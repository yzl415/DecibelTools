import { DecibelMeter } from './DecibelMeter';
import { MeasurementSession, MeasurementSummary } from './MeasurementSession';
import { RecordStore } from './RecordStore';
import { SettingsStore } from './SettingsStore';
import { LEVEL_NOISY_THRESHOLD } from './Theme';
import { alertFeedback } from './Haptics';
import { HardwareReadingState } from './HardwareReadingState';

const OVER_ALERT_COOLDOWN_MS: number = 6000;

export class DecibelMeasurementSnapshot {
  measuring: boolean = false;
  current: number = 0;
  min: number = 0;
  avg: number = 0;
  peak: number = 0;
  elapsedSec: number = 0;
  count: number = 0;
  spectrum: number[] = [];
  available: boolean = false;
  waiting: boolean = false;
  timedOut: boolean = false;
}

export class DecibelMeasurementService {
  private static instance: DecibelMeasurementService | null = null;
  private meter: DecibelMeter = new DecibelMeter();
  private session: MeasurementSession = new MeasurementSession();
  private running: boolean = false;
  private measuring: boolean = false;
  private latest: number = 0;
  private current: number = 0;
  private minDb: number = 0;
  private avgDb: number = 0;
  private peakDb: number = 0;
  private elapsedSec: number = 0;
  private count: number = 0;
  private sumDb: number = 0;
  private startMs: number = 0;
  private calibration: number = 0;
  private weighting: string = 'A';
  private response: string = 'FAST';
  private overLimitAlert: boolean = true;
  private lastAlertTs: number = 0;
  private latestSeq: number = 0;
  private recordedSeq: number = 0;
  private readingState: HardwareReadingState = new HardwareReadingState();

  private constructor() {
    this.meter.onDb = (db: number) => this.handleDb(db);
  }

  static getInstance(): DecibelMeasurementService {
    if (DecibelMeasurementService.instance === null) {
      DecibelMeasurementService.instance = new DecibelMeasurementService();
    }
    return DecibelMeasurementService.instance;
  }

  configure(calibration: number, weighting: string, response: string, overLimitAlert: boolean): void {
    this.calibration = calibration;
    this.weighting = weighting;
    this.response = response;
    this.overLimitAlert = overLimitAlert;
    this.meter.configure(calibration, weighting, response);
  }

  isMeasuring(): boolean {
    return this.measuring;
  }

  async start(nowMs: number): Promise<boolean> {
    if (this.measuring) {
      return true;
    }
    this.resetStats();
    this.session.start(nowMs);
    this.measuring = true;
    this.startMs = nowMs;
    this.lastAlertTs = 0;
    const ok: boolean = await this.ensureRunning();
    if (!ok) {
      this.session.stop(false, 0);
      this.measuring = false;
      this.resetStats();
      return false;
    }
    return true;
  }

  snapshot(nowMs: number): DecibelMeasurementSnapshot {
    if (this.measuring) {
      this.recordLatestIfNeeded(nowMs);
      this.elapsedSec = Math.floor((nowMs - this.startMs) / 1000);
    }
    const out: DecibelMeasurementSnapshot = new DecibelMeasurementSnapshot();
    out.measuring = this.measuring;
    out.current = this.current;
    out.min = this.minDb;
    out.avg = this.avgDb;
    out.peak = this.peakDb;
    out.elapsedSec = this.elapsedSec;
    out.count = this.count;
    out.spectrum = this.running ? this.meter.getSpectrum() : [];
    const health = this.readingState.snapshot(nowMs);
    out.available = this.running && health.available;
    out.waiting = this.running && health.waiting;
    out.timedOut = this.running && health.timedOut;
    return out;
  }

  async stop(save: boolean, recordStore: RecordStore, store: SettingsStore): Promise<MeasurementSummary> {
    if (!this.measuring) {
      return new MeasurementSummary();
    }
    this.recordLatestIfNeeded(Date.now());
    this.session.stop(false, this.elapsedSec);
    const summary: MeasurementSummary = this.currentSummary(save);
    this.measuring = false;
    this.count = summary.count;
    this.minDb = summary.min;
    this.avgDb = summary.avg;
    this.peakDb = summary.peak;
    this.elapsedSec = summary.elapsedSec;
    if (this.peakDb > store.historyMaxDb) {
      await store.setHistoryMaxDb(Math.round(this.peakDb));
    }
    if (summary.shouldPersist) {
      await recordStore.add('测量记录', this.elapsedSec,
        Math.round(this.minDb), this.avgDb, Math.round(this.peakDb));
    }
    await this.meter.stop();
    this.running = false;
    this.readingState.reset();
    this.latest = 0;
    this.current = 0;
    return summary;
  }

  private async ensureRunning(): Promise<boolean> {
    if (this.running) {
      return true;
    }
    this.meter.configure(this.calibration, this.weighting, this.response);
    this.meter.onDb = (db: number) => this.handleDb(db);
    this.readingState.markStarted(Date.now());
    const ok: boolean = await this.meter.start();
    this.running = ok;
    if (!ok) {
      this.readingState.reset();
    }
    return ok;
  }

  private handleDb(db: number): void {
    this.readingState.markReading(Date.now());
    this.latest = db;
    this.latestSeq++;
    this.current = Math.round(db);
    this.recordLatestIfNeeded(Date.now());
  }

  private recordLatestIfNeeded(nowMs: number): void {
    if (!this.measuring || this.latestSeq === this.recordedSeq || this.latest <= 0) {
      return;
    }
    this.sumDb += this.latest;
    this.count++;
    if (this.minDb === 0 || this.latest < this.minDb) {
      this.minDb = Math.round(this.latest);
    }
    if (this.latest > this.peakDb) {
      this.peakDb = Math.round(this.latest);
    }
    this.avgDb = Math.round(this.sumDb / this.count);
    this.elapsedSec = Math.floor((nowMs - this.startMs) / 1000);
    this.recordedSeq = this.latestSeq;
    if (this.overLimitAlert && this.latest >= LEVEL_NOISY_THRESHOLD) {
      if (nowMs - this.lastAlertTs >= OVER_ALERT_COOLDOWN_MS) {
        this.lastAlertTs = nowMs;
        alertFeedback();
      }
    }
  }

  private currentSummary(save: boolean): MeasurementSummary {
    const out: MeasurementSummary = new MeasurementSummary();
    out.count = this.count;
    out.min = this.minDb;
    out.avg = this.avgDb;
    out.peak = this.peakDb;
    out.elapsedSec = this.elapsedSec;
    out.shouldPersist = save && this.count > 0 && this.elapsedSec >= 1;
    return out;
  }

  private resetStats(): void {
    this.latest = 0;
    this.current = 0;
    this.minDb = 0;
    this.avgDb = 0;
    this.peakDb = 0;
    this.elapsedSec = 0;
    this.count = 0;
    this.sumDb = 0;
    this.startMs = 0;
    this.latestSeq = 0;
    this.recordedSeq = 0;
  }
}
