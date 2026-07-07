export class MeasurementSummary {
  count: number = 0;
  min: number = 0;
  avg: number = 0;
  peak: number = 0;
  elapsedSec: number = 0;
  shouldPersist: boolean = false;
}

export class MeasurementSession {
  private sum: number = 0;
  private count: number = 0;
  private minDb: number = 0;
  private peakDb: number = 0;
  private startMs: number = 0;
  private measuring: boolean = false;

  start(nowMs: number): void {
    this.sum = 0;
    this.count = 0;
    this.minDb = 0;
    this.peakDb = 0;
    this.startMs = nowMs;
    this.measuring = true;
  }

  isMeasuring(): boolean {
    return this.measuring;
  }

  preview(_db: number): void {
  }

  record(db: number): void {
    if (!this.measuring) {
      return;
    }
    this.sum += db;
    this.count++;
    if (db > this.peakDb) {
      this.peakDb = db;
    }
    if (this.minDb === 0 || db < this.minDb) {
      this.minDb = db;
    }
  }

  snapshot(nowMs: number): MeasurementSummary {
    const out: MeasurementSummary = new MeasurementSummary();
    out.count = this.count;
    out.min = Math.round(this.minDb);
    out.avg = this.count > 0 ? Math.round(this.sum / this.count) : 0;
    out.peak = Math.round(this.peakDb);
    out.elapsedSec = this.measuring ? Math.floor((nowMs - this.startMs) / 1000) : 0;
    return out;
  }

  stop(save: boolean, elapsedSec: number): MeasurementSummary {
    this.measuring = false;
    const out: MeasurementSummary = new MeasurementSummary();
    out.count = this.count;
    out.min = Math.round(this.minDb);
    out.avg = this.count > 0 ? Math.round(this.sum / this.count) : 0;
    out.peak = Math.round(this.peakDb);
    out.elapsedSec = elapsedSec;
    out.shouldPersist = save && this.count > 0 && elapsedSec >= 1;
    return out;
  }
}
