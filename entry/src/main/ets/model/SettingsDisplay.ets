export function formatCalibrationLabel(calibration: number): string {
  return `${calibration >= 0 ? '+' : ''}${calibration.toFixed(1)} dB`;
}

export function normalizeCalibration(calibration: number): number {
  const clamped: number = Math.max(-15, Math.min(15, calibration));
  return Math.round(clamped * 10) / 10;
}

export function formatRecordCountLabel(recordCount: number): string {
  return `${recordCount} 条`;
}
