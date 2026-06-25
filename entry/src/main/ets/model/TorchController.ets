/**
 * 手电筒控制：用 CameraManager 的 torch 模式开关闪光灯，并支持频闪（按间隔切换）。
 * torch 模式无需相机权限。
 */
import { camera } from '@kit.CameraKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

export class TorchController {
  private mgr: camera.CameraManager | null = null;
  private on: boolean = false;
  private timer: number = -1;

  /** 初始化 CameraManager。返回设备是否支持手电筒 */
  init(ctx: common.UIAbilityContext): boolean {
    try {
      this.mgr = camera.getCameraManager(ctx);
      return this.mgr.isTorchSupported();
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
  setOn(on: boolean): void {
    if (this.mgr === null) {
      return;
    }
    try {
      this.mgr.setTorchMode(on ? camera.TorchMode.ON : camera.TorchMode.OFF);
      this.on = on;
    } catch (e) {
      const err = e as BusinessError;
      console.error(`setTorchMode failed: ${err.code} ${err.message}`);
    }
  }

  /** 开始频闪：每 intervalMs 翻转一次 */
  startStrobe(intervalMs: number): void {
    this.stopStrobe();
    let lit: boolean = false;
    this.timer = setInterval(() => {
      lit = !lit;
      this.setOn(lit);
    }, intervalMs);
  }

  /**
   * 开始 SOS：按摩斯电码 ···———··· 循环。unit 为基本时间单位（ms）。
   * 点=1u 亮、划=3u 亮，元素间隔 1u 灭、字母间隔 3u 灭、循环间隔 7u 灭。
   */
  startSos(unit: number): void {
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
      this.setOn(lit);
      const dur: number = Math.abs(seg) * unit;
      this.timer = setTimeout(step, dur);
    };
    step();
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
  }
}
