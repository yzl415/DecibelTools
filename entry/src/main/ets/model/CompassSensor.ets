/**
 * 指南针服务：订阅 ORIENTATION 传感器，alpha 即设备绕 Z 轴旋转角（方位角，0~360°，
 * 0 为正北）。回调返回 heading（度）。需设备具备磁力计。
 */
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { MOCK_HARDWARE } from './MockConfig';

/** 传感器精度等级（对齐 sensor.SensorAccuracy 枚举值）：0 不可靠 / 1 低 / 2 中 / 3 高 */
export const ACC_UNRELIABLE: number = 0;
export const ACC_LOW: number = 1;
export const ACC_MEDIUM: number = 2;
export const ACC_HIGH: number = 3;

export class CompassSensor {
  private subscribed: boolean = false;
  private mockTimer: number = -1;
  private mockHeading: number = 0;
  // 回调：heading 方位角（度，0=正北，顺时针增大）；accuracy 为 SensorAccuracy 枚举值(0~3)
  onHeading: (heading: number, accuracy: number) => void = () => {};

  /** 开始订阅。返回是否成功 */
  start(): boolean {
    if (this.subscribed) {
      return true;
    }
    if (MOCK_HARDWARE) {
      this.mockHeading = 0;
      this.mockTimer = setInterval(() => {
        // 缓慢顺时针旋转（约 18s 一圈），便于观察方位变化；模拟器恒定高精度
        this.mockHeading = (this.mockHeading + 2) % 360;
        this.onHeading(this.mockHeading, ACC_HIGH);
      }, 100);
      this.subscribed = true;
      return true;
    }
    try {
      sensor.getSingleSensorSync(sensor.SensorId.ORIENTATION);
      sensor.on(sensor.SensorId.ORIENTATION, (data: sensor.OrientationResponse) => {
        let h: number = data.alpha;
        // 归一化到 0~360
        h = ((h % 360) + 360) % 360;
        // accuracy 为 Response 继承字段（SensorAccuracy 枚举），部分机型可能缺省
        const acc: number = data.accuracy === undefined ? ACC_MEDIUM : data.accuracy as number;
        this.onHeading(h, acc);
      }, { interval: 100000000 }); // 100ms（纳秒）
      this.subscribed = true;
      return true;
    } catch (e) {
      const err = e as BusinessError;
      console.error(`CompassSensor start failed: ${err.code} ${err.message}`);
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
      sensor.off(sensor.SensorId.ORIENTATION);
    } catch (e) {
      const err = e as BusinessError;
      console.error(`CompassSensor stop failed: ${err.code} ${err.message}`);
    }
    this.subscribed = false;
  }

  /** 方位角 -> 八方位英文缩写 */
  static dirAbbr(heading: number): string {
    const dirs: string[] = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    const idx: number = Math.round(heading / 45) % 8;
    return dirs[idx];
  }

  /** 方位角 -> 八方位中文 */
  static dirCn(heading: number): string {
    const dirs: string[] = ['北', '东北', '东', '东南', '南', '西南', '西', '西北'];
    const idx: number = Math.round(heading / 45) % 8;
    return dirs[idx];
  }
}
