import { AngleSensor } from './AngleSensor';
import { HardwareReadingState } from './HardwareReadingState';
import { AngleCalibration } from './AngleCalibration';

export class AngleMeasurementSnapshot {
  active: boolean = false;
  pitch: number = 0;
  roll: number = 0;
  tilt: number = -1;
  available: boolean = false;
  waiting: boolean = false;
  timedOut: boolean = false;
  calibrated: boolean = false;
}

export class AngleMeasurementService {
  private static instance: AngleMeasurementService | null = null;
  private sensor: AngleSensor = new AngleSensor();
  private active: boolean = false;
  private rawPitch: number = 0;
  private rawRoll: number = 0;
  private calibration: AngleCalibration = new AngleCalibration();
  private readingState: HardwareReadingState = new HardwareReadingState();

  private constructor() {
    this.sensor.onAngle = (pitch: number, roll: number) => {
      this.rawPitch = pitch;
      this.rawRoll = roll;
      this.readingState.markReading(Date.now());
    };
  }

  static getInstance(): AngleMeasurementService {
    if (AngleMeasurementService.instance === null) {
      AngleMeasurementService.instance = new AngleMeasurementService();
    }
    return AngleMeasurementService.instance;
  }

  isActive(): boolean {
    return this.active;
  }

  start(): boolean {
    if (this.active) {
      return true;
    }
    this.calibration.clear();
    this.sensor.onAngle = (pitch: number, roll: number) => {
      this.rawPitch = pitch;
      this.rawRoll = roll;
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
    this.calibration.clear();
  }

  calibrate(): void {
    this.calibration.setReference(this.rawPitch, this.rawRoll);
  }

  clearCalibration(): void {
    this.calibration.clear();
  }

  snapshot(nowMs: number = Date.now()): AngleMeasurementSnapshot {
    const pitch: number = this.round1(this.calibration.applyPitch(this.rawPitch));
    const roll: number = this.round1(this.calibration.applyRoll(this.rawRoll));
    const out: AngleMeasurementSnapshot = new AngleMeasurementSnapshot();
    out.active = this.active;
    out.pitch = pitch;
    out.roll = roll;
    const health = this.readingState.snapshot(nowMs);
    out.available = this.active && health.available;
    out.waiting = this.active && health.waiting;
    out.timedOut = this.active && health.timedOut;
    out.calibrated = this.calibration.isActive();
    out.tilt = out.available ? this.round1(Math.sqrt(pitch * pitch + roll * roll)) : -1;
    return out;
  }

  private round1(value: number): number {
    return Math.round(value * 10) / 10;
  }
}
