import { AngleSensor } from './AngleSensor';

export class AngleMeasurementSnapshot {
  active: boolean = false;
  pitch: number = 0;
  roll: number = 0;
  tilt: number = -1;
}

export class AngleMeasurementService {
  private static instance: AngleMeasurementService | null = null;
  private sensor: AngleSensor = new AngleSensor();
  private active: boolean = false;
  private rawPitch: number = 0;
  private rawRoll: number = 0;
  private calPitch: number = 0;
  private calRoll: number = 0;

  private constructor() {
    this.sensor.onAngle = (pitch: number, roll: number) => {
      this.rawPitch = pitch;
      this.rawRoll = roll;
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
    this.sensor.onAngle = (pitch: number, roll: number) => {
      this.rawPitch = pitch;
      this.rawRoll = roll;
    };
    this.active = this.sensor.start();
    return this.active;
  }

  stop(): void {
    this.sensor.stop();
    this.active = false;
  }

  calibrate(): void {
    this.calPitch = this.rawPitch;
    this.calRoll = this.rawRoll;
  }

  snapshot(): AngleMeasurementSnapshot {
    const pitch: number = this.round1(this.rawPitch - this.calPitch);
    const roll: number = this.round1(this.rawRoll - this.calRoll);
    const out: AngleMeasurementSnapshot = new AngleMeasurementSnapshot();
    out.active = this.active;
    out.pitch = pitch;
    out.roll = roll;
    out.tilt = this.active ? this.round1(Math.sqrt(pitch * pitch + roll * roll)) : -1;
    return out;
  }

  private round1(value: number): number {
    return Math.round(value * 10) / 10;
  }
}
