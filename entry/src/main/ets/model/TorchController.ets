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

  stopStrobe(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  /** 释放：停频闪并关灯 */
  dispose(): void {
    this.stopStrobe();
    this.setOn(false);
  }
}
