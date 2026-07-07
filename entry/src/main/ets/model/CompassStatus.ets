import { ACC_HIGH, ACC_LOW, ACC_MEDIUM } from './CompassSensor';

export function compassStatusText(active: boolean, accuracy: number): string {
  if (!active) {
    return '未读取到磁力计数据';
  }
  if (accuracy >= ACC_MEDIUM) {
    return '磁偏角已校正';
  }
  if (accuracy === ACC_LOW) {
    return '建议校准 · 远离磁性物体';
  }
  return '请校准 · 做 8 字晃动';
}

export function compassAccuracyText(active: boolean, accuracy: number): string {
  if (!active) {
    return '--';
  }
  if (accuracy >= ACC_HIGH) {
    return '精度 ±2°';
  }
  if (accuracy === ACC_MEDIUM) {
    return '精度 ±5°';
  }
  if (accuracy === ACC_LOW) {
    return '精度较低';
  }
  return '精度不可靠';
}
