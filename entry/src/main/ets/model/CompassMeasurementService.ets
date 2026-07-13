import { CompassSensor, ACC_MEDIUM } from './CompassSensor';
import { HardwareReadingState } from './HardwareReadingState';

export class CompassMeasurementSnapshot {
  active: boolean = false;
  heading: number = -1;
  accuracy: number = ACC_MEDIUM;
  available: boolean = false;
  waiting: boolean = false;
  timedOut: boolean = false;
}

export class CompassMeasurementService {
  private static instance: CompassMeasurementService | null = null;
  private sensor: CompassSensor = new CompassSensor();
  private active: boolean = false;
  private heading: number = 0;
  private accuracy: number = ACC_MEDIUM;
  private readingState: HardwareReadingState = new HardwareReadingState();

  private constructor() {
    this.sensor.onHeading = (heading: number, accuracy: number) => {
      this.heading = heading;
      this.accuracy = accuracy;
      this.readingState.markReading(Date.now());
    };
  }

  static getInstance(): CompassMeasurementService {
    if (CompassMeasurementService.instance === null) {
      CompassMeasurementService.instance = new CompassMeasurementService();
    }
    return CompassMeasurementService.instance;
  }

  isActive(): boolean {
    return this.active;
  }

  start(): boolean {
    if (this.active) {
      return true;
    }
    this.sensor.onHeading = (heading: number, accuracy: number) => {
      this.heading = heading;
      this.accuracy = accuracy;
      this.readingState.markReading(Date.now());
    };
    this.readingState.markStarted(Date.now());
    this.active = this.sensor.start();
    if (!this.active) {
      this.readingState.reset();
    }
    return this.active;
  }

  stop(): void {
    this.sensor.stop();
    this.active = false;
    this.readingState.reset();
  }

  snapshot(nowMs: number = Date.now()): CompassMeasurementSnapshot {
    const out: CompassMeasurementSnapshot = new CompassMeasurementSnapshot();
    out.active = this.active;
    const health = this.readingState.snapshot(nowMs);
    out.available = this.active && health.available;
    out.waiting = this.active && health.waiting;
    out.timedOut = this.active && health.timedOut;
    out.heading = out.available ? Math.round(this.heading) : -1;
    out.accuracy = this.accuracy;
    return out;
  }
}
