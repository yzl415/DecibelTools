/**
 * 角度仪服务：订阅加速度计，根据重力分量算出设备相对水平/垂直的倾角。
 * pitch：设备前后倾角；roll：左右倾角（单位：度）。
 */
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { MOCK_HARDWARE } from './MockConfig';

export class AngleSensor {
  private subscribed: boolean = false;
  private mockTimer: number = -1;
  private mockT: number = 0;
  // 回调：pitch / roll 角度（度）
  onAngle: (pitch: number, roll: number) => void = () => {};

  /** 开始订阅。返回是否成功 */
  start(): boolean {
    if (this.subscribed) {
      return true;
    }
    if (MOCK_HARDWARE) {
      this.mockT = 0;
      this.mockTimer = setInterval(() => {
        this.mockT += 0.05;
        const pitch: number = Math.sin(this.mockT) * 30;
        const roll: number = Math.cos(this.mockT * 0.7) * 20;
        this.onAngle(pitch, roll);
      }, 100);
      this.subscribed = true;
      return true;
    }
    try {
      sensor.on(sensor.SensorId.ACCELEROMETER, (data: sensor.AccelerometerResponse) => {
        const x: number = data.x;
        const y: number = data.y;
        const z: number = data.z;
        // 倾角：用反正切由重力分量得到，转成度
        const roll: number = Math.atan2(x, Math.sqrt(y * y + z * z)) * 180 / Math.PI;
        const pitch: number = Math.atan2(y, Math.sqrt(x * x + z * z)) * 180 / Math.PI;
        this.onAngle(pitch, roll);
      }, { interval: 100000000 }); // 100ms（纳秒）
      this.subscribed = true;
      return true;
    } catch (e) {
      const err = e as BusinessError;
      console.error(`AngleSensor start failed: ${err.code} ${err.message}`);
      return false;
    }
  }

  stop(): void {
    if (!this.subscribed) {
      return;
    }
    if (this.mockTimer !== -1) {
      clearInterval(this.mockTimer);
      this.mockTimer = -1;
      this.subscribed = false;
      return;
    }
    try {
      sensor.off(sensor.SensorId.ACCELEROMETER);
    } catch (e) {
      const err = e as BusinessError;
      console.error(`AngleSensor stop failed: ${err.code} ${err.message}`);
    }
    this.subscribed = false;
  }
}
