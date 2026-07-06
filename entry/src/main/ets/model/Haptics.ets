/**
 * 震动反馈封装：统一读取设置中的"震动反馈"开关，开关关闭时静默跳过。
 * 用预设短振动（非精确计量，兼容模拟器无振动马达的情况，失败静默忽略）。
 */
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { SettingsStore } from './SettingsStore';

/** 轻触反馈：普通按钮点击 */
export function tapFeedback(): void {
  vibrate(15);
}

/** 强反馈：警示 / 超标提醒 */
export function alertFeedback(): void {
  vibrate(45);
}

function vibrate(durationMs: number): void {
  if (!SettingsStore.getInstance().vibration) {
    return;
  }
  try {
    vibrator.startVibration(
      { type: 'time', duration: durationMs },
      { id: 0, usage: 'touch' },
      (err: BusinessError) => {
        if (err) {
          console.error(`vibrate failed: ${err.code} ${err.message}`);
        }
      }
    );
  } catch (e) {
    const err = e as BusinessError;
    console.error(`vibrate failed: ${err.code} ${err.message}`);
  }
}
