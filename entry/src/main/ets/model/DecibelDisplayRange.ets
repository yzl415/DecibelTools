export const DECIBEL_DISPLAY_MIN_DB: number = 30;
export const DECIBEL_DISPLAY_MAX_DB: number = 120;
export const DECIBEL_SPECTRUM_MIN_HEIGHT: number = 0.06;

export function clampDecibelDisplayDb(db: number): number {
  return Math.max(DECIBEL_DISPLAY_MIN_DB, Math.min(DECIBEL_DISPLAY_MAX_DB, db));
}

export function normalizeDecibelDisplayDb(db: number): number {
  const clamped: number = clampDecibelDisplayDb(db);
  return (clamped - DECIBEL_DISPLAY_MIN_DB) / (DECIBEL_DISPLAY_MAX_DB - DECIBEL_DISPLAY_MIN_DB);
}

export function normalizeDecibelSpectrumHeight(db: number): number {
  return Math.max(DECIBEL_SPECTRUM_MIN_HEIGHT, normalizeDecibelDisplayDb(db));
}

export function decibelFromSpectrumHeight(height: number): number {
  const clamped: number = Math.max(0, Math.min(1, height));
  return DECIBEL_DISPLAY_MIN_DB + clamped * (DECIBEL_DISPLAY_MAX_DB - DECIBEL_DISPLAY_MIN_DB);
}
