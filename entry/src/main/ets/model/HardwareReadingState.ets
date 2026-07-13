export const HARDWARE_FIRST_READING_TIMEOUT_MS: number = 2000;
export const HARDWARE_READING_STALE_MS: number = 1500;

export class HardwareReadingSnapshot {
  available: boolean = false;
  waiting: boolean = false;
  timedOut: boolean = false;
}

export class HardwareReadingState {
  private startedAtMs: number = -1;
  private lastReadingAtMs: number = -1;

  markStarted(nowMs: number): void {
    this.startedAtMs = nowMs;
    this.lastReadingAtMs = -1;
  }

  markReading(nowMs: number): void {
    this.lastReadingAtMs = nowMs;
  }

  reset(): void {
    this.startedAtMs = -1;
    this.lastReadingAtMs = -1;
  }

  snapshot(nowMs: number): HardwareReadingSnapshot {
    const out: HardwareReadingSnapshot = new HardwareReadingSnapshot();
    if (this.startedAtMs < 0) {
      return out;
    }
    if (this.lastReadingAtMs < 0) {
      out.waiting = nowMs - this.startedAtMs < HARDWARE_FIRST_READING_TIMEOUT_MS;
      out.timedOut = !out.waiting;
      return out;
    }
    out.available = nowMs - this.lastReadingAtMs <= HARDWARE_READING_STALE_MS;
    out.timedOut = !out.available;
    return out;
  }
}
