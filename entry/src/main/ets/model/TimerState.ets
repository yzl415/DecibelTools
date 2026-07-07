export class TimerSnapshot {
  elapsedMs: number = 0;
  running: boolean = false;
  laps: number[] = [];
}

export class TimerState {
  private startMs: number = 0;
  private accumulatedMs: number = 0;
  private running: boolean = false;
  private laps: number[] = [];

  start(nowMs: number): TimerSnapshot {
    if (!this.running) {
      this.startMs = nowMs;
      this.running = true;
    }
    return this.snapshot(nowMs);
  }

  stop(nowMs: number): TimerSnapshot {
    if (this.running) {
      this.accumulatedMs += nowMs - this.startMs;
      this.running = false;
    }
    return this.snapshot(nowMs);
  }

  lap(nowMs: number): TimerSnapshot {
    if (this.running) {
      this.laps = [this.elapsed(nowMs)].concat(this.laps);
    }
    return this.snapshot(nowMs);
  }

  reset(): TimerSnapshot {
    this.startMs = 0;
    this.accumulatedMs = 0;
    this.running = false;
    this.laps = [];
    return this.snapshot(0);
  }

  snapshot(nowMs: number): TimerSnapshot {
    const out: TimerSnapshot = new TimerSnapshot();
    out.elapsedMs = this.elapsed(nowMs);
    out.running = this.running;
    out.laps = this.laps.slice(0);
    return out;
  }

  private elapsed(nowMs: number): number {
    if (!this.running) {
      return this.accumulatedMs;
    }
    return this.accumulatedMs + nowMs - this.startMs;
  }
}
