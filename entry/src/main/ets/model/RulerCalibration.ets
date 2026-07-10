const DEFAULT_PX_PER_CM: number = 38;
const INCH_PER_CM: number = 2.54;

export class RulerSelectionBounds {
  top: number;
  bottom: number;
  height: number;
  center: number;

  constructor(firstMarkerY: number, secondMarkerY: number) {
    this.top = Math.min(firstMarkerY, secondMarkerY);
    this.bottom = Math.max(firstMarkerY, secondMarkerY);
    this.height = this.bottom - this.top;
    this.center = (this.top + this.bottom) / 2;
  }
}

export function rulerSelectionBounds(firstMarkerY: number, secondMarkerY: number): RulerSelectionBounds {
  return new RulerSelectionBounds(firstMarkerY, secondMarkerY);
}

export function systemPxPerCm(densityDPI: number, densityPixels: number): number {
  if (densityDPI <= 0 || densityPixels <= 0) {
    return 0;
  }
  return Math.round(densityDPI / densityPixels / INCH_PER_CM * 10) / 10;
}

export function resolvedRulerPxPerCm(systemPxPerCmValue: number): number {
  return systemPxPerCmValue > 0 ? systemPxPerCmValue : DEFAULT_PX_PER_CM;
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
