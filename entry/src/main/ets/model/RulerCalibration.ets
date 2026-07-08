export class RulerCalibrationPreset {
  label: string;
  cm: number;

  constructor(label: string, cm: number) {
    this.label = label;
    this.cm = cm;
  }
}

export const RULER_CALIBRATION_PRESETS: RulerCalibrationPreset[] = [
  new RulerCalibrationPreset('银行卡短边 5.40cm', 5.4),
  new RulerCalibrationPreset('5cm 直尺', 5),
  new RulerCalibrationPreset('一元硬币 2.5cm', 2.5)
];

const DEFAULT_PX_PER_CM: number = 38;
const INCH_PER_CM: number = 2.54;
const CALIBRATION_TOLERANCE: number = 0.35;

export function systemPxPerCm(densityDPI: number, densityPixels: number): number {
  if (densityDPI <= 0 || densityPixels <= 0) {
    return 0;
  }
  return Math.round(densityDPI / densityPixels / INCH_PER_CM * 10) / 10;
}

export function resolvedRulerPxPerCm(storedPxPerCm: number, systemPxPerCmValue: number): number {
  if (systemPxPerCmValue <= 0) {
    return storedPxPerCm > 0 ? storedPxPerCm : DEFAULT_PX_PER_CM;
  }
  if (storedPxPerCm <= 0 || Math.abs(storedPxPerCm - DEFAULT_PX_PER_CM) < 0.01) {
    return systemPxPerCmValue;
  }
  if (!isCalibrationNearSystem(storedPxPerCm, systemPxPerCmValue)) {
    return systemPxPerCmValue;
  }
  return storedPxPerCm;
}

export function rulerDistance(markerGapVp: number, pxPerCm: number, unit: string): number {
  if (pxPerCm <= 0) {
    return 0;
  }
  const cm: number = Math.abs(markerGapVp) / pxPerCm;
  if (unit === 'in') {
    return Math.round(cm / INCH_PER_CM * 100) / 100;
  }
  return Math.round(cm * 10) / 10;
}

export function calibratedPxPerCm(markerGapVp: number, realCm: number, fallbackPxPerCm: number): number {
  if (realCm <= 0 || Math.abs(markerGapVp) <= 10) {
    return fallbackPxPerCm;
  }
  const ppc: number = Math.abs(markerGapVp) / realCm;
  return Math.round(ppc * 10) / 10;
}

export function shouldAcceptCalibration(markerGapVp: number, realCm: number, systemPxPerCmValue: number): boolean {
  if (systemPxPerCmValue <= 0) {
    return true;
  }
  const nextPxPerCm: number = calibratedPxPerCm(markerGapVp, realCm, systemPxPerCmValue);
  return isCalibrationNearSystem(nextPxPerCm, systemPxPerCmValue);
}

function isCalibrationNearSystem(pxPerCm: number, systemPxPerCmValue: number): boolean {
  return pxPerCm >= systemPxPerCmValue * (1 - CALIBRATION_TOLERANCE) &&
    pxPerCm <= systemPxPerCmValue * (1 + CALIBRATION_TOLERANCE);
}
