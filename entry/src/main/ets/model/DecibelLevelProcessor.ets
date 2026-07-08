const SPL_OFFSET: number = 90;
const WEIGHT_A_BIAS: number = -4;
const WEIGHT_C_BIAS: number = 0;
const FAST_ALPHA: number = 0.65;
const SLOW_ALPHA: number = 0.12;

export class DecibelLevelProcessor {
  private calibration: number = 0;
  private weighting: string = 'A';
  private response: string = 'FAST';
  private smoothed: number = -1;
  private lastBaseSpl: number = -1;
  private lastWeightedRaw: number = -1;

  configure(calibration: number, weighting: string, response: string): void {
    const previousRaw: number = this.lastWeightedRaw;
    const hadReading: boolean = this.smoothed >= 0 && this.lastBaseSpl >= 0;
    this.calibration = calibration;
    this.weighting = weighting;
    this.response = response;
    if (!hadReading) {
      return;
    }
    const nextRaw: number = this.weightedRaw();
    this.smoothed += nextRaw - previousRaw;
    this.lastWeightedRaw = nextRaw;
  }

  reset(): void {
    this.smoothed = -1;
    this.lastBaseSpl = -1;
    this.lastWeightedRaw = -1;
  }

  processDbfs(dbfs: number): number {
    return this.processBaseSpl(dbfs + SPL_OFFSET);
  }

  processBaseSpl(baseSpl: number): number {
    this.lastBaseSpl = baseSpl;
    const raw: number = this.weightedRaw();
    this.lastWeightedRaw = raw;
    const alpha: number = this.response === 'SLOW' ? SLOW_ALPHA : FAST_ALPHA;
    if (this.smoothed < 0) {
      this.smoothed = raw;
    } else {
      this.smoothed = this.smoothed + alpha * (raw - this.smoothed);
    }
    return this.smoothed;
  }

  current(): number {
    return this.smoothed;
  }

  private weightedRaw(): number {
    const bias: number = this.weighting === 'C' ? WEIGHT_C_BIAS : WEIGHT_A_BIAS;
    const raw: number = this.lastBaseSpl + this.calibration + bias;
    return raw < 0 ? 0 : raw;
  }
}
