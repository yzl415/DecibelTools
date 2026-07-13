/**
 * 手电筒控制：用 CameraManager 的 torch 模式开关闪光灯，并支持频闪（按间隔切换）。
 * torch 模式无需相机权限。
 */
import { camera } from '@kit.CameraKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { MOCK_HARDWARE } from './MockConfig';

export class TorchController {
  private mgr: camera.CameraManager | null = null;
  private on: boolean = false;
  private timer: number = -1;
  onStateChanged: (on: boolean) => void = () => {};
  onSequenceFailed: () => void = () => {};

  /** 初始化 CameraManager。返回设备是否支持手电筒 */
  init(ctx: common.UIAbilityContext): boolean {
    if (MOCK_HARDWARE) {
      // 模拟器无闪光灯，伪装为支持，仅维护开关状态供 UI 验证（屏幕上看不到真实灯光）
      return true;
    }
    try {
      this.mgr = camera.getCameraManager(ctx);
      const supported: boolean = this.mgr.isTorchSupported();
      if (supported) {
        this.mgr.on('torchStatusChange', (err: BusinessError, info: camera.TorchStatusInfo) => {
          if (err) {
            console.error(`torchStatusChange failed: ${err.code} ${err.message}`);
            return;
          }
          this.on = info.isTorchAvailable && info.isTorchActive;
          this.onStateChanged(this.on);
          if (!info.isTorchAvailable && this.timer !== -1) {
            this.stopStrobe();
            this.onSequenceFailed();
          }
        });
      }
      return supported;
    } catch (e) {
      const err = e as BusinessError;
      console.error(`Torch init failed: ${err.code} ${err.message}`);
      return false;
    }
  }

  isOn(): boolean {
    return this.on;
  }

  /** 常亮开关 */
  setOn(on: boolean): boolean {
    if (MOCK_HARDWARE) {
      this.on = on;
      this.onStateChanged(this.on);
      return true;
    }
    if (this.mgr === null) {
      return false;
    }
    try {
      this.mgr.setTorchMode(on ? camera.TorchMode.ON : camera.TorchMode.OFF);
      this.on = this.mgr.getTorchMode() === (on ? camera.TorchMode.ON : camera.TorchMode.OFF);
      this.onStateChanged(this.on);
      return this.on === on;
    } catch (e) {
      const err = e as BusinessError;
      console.error(`setTorchMode failed: ${err.code} ${err.message}`);
      this.onStateChanged(this.on);
      return false;
    }
  }

  /** 开始频闪：每 intervalMs 翻转一次 */
  startStrobe(intervalMs: number): boolean {
    this.stopStrobe();
    let lit: boolean = true;
    if (!this.setOn(true)) {
      return false;
    }
    this.timer = setInterval(() => {
      lit = !lit;
      if (!this.setOn(lit)) {
        this.stopStrobe();
        this.onSequenceFailed();
      }
    }, intervalMs);
    return true;
  }

  /**
   * 开始 SOS：按摩斯电码 ···———··· 循环。unit 为基本时间单位（ms）。
   * 点=1u 亮、划=3u 亮，元素间隔 1u 灭、字母间隔 3u 灭、循环间隔 7u 灭。
   */
  startSos(unit: number): boolean {
    this.stopStrobe();
    // 构造亮/灭序列（true=亮，持续 n 个 unit）
    const pattern: number[] = [];   // 正数=亮的时长(unit)，负数=灭的时长(unit)
    const dot: number = 1;
    const dash: number = 3;
    const letter: number[][] = [
      [dot, dot, dot],          // S
      [dash, dash, dash],       // O
      [dot, dot, dot]           // S
    ];
    for (let li = 0; li < letter.length; li++) {
      const marks: number[] = letter[li];
      for (let mi = 0; mi < marks.length; mi++) {
        pattern.push(marks[mi]);          // 亮
        pattern.push(mi < marks.length - 1 ? -1 : 0); // 元素间隔
      }
      pattern.push(li < letter.length - 1 ? -3 : -7); // 字母 / 循环间隔
    }
    let idx: number = 0;
    const step = (): void => {
      if (idx >= pattern.length) {
        idx = 0;
      }
      const seg: number = pattern[idx];
      idx++;
      if (seg === 0) {
        // 0 间隔，立即推进
        step();
        return;
      }
      const lit: boolean = seg > 0;
      if (!this.setOn(lit)) {
        this.stopStrobe();
        this.onSequenceFailed();
        return;
      }
      const dur: number = Math.abs(seg) * unit;
      this.timer = setTimeout(step, dur);
    };
    step();
    return this.on;
  }

  stopStrobe(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      clearTimeout(this.timer);
      this.timer = -1;
    }
  }

  /** 释放：停频闪并关灯 */
  dispose(): void {
    this.stopStrobe();
    this.setOn(false);
    if (this.mgr !== null && !MOCK_HARDWARE) {
      this.mgr.off('torchStatusChange');
    }
    this.mgr = null;
  }
}
