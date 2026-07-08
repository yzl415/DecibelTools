import { CompassSensor, ACC_MEDIUM } from './CompassSensor';

export class CompassMeasurementSnapshot {
  active: boolean = false;
  heading: number = -1;
  accuracy: number = ACC_MEDIUM;
}

export class CompassMeasurementService {
  private static instance: CompassMeasurementService | null = null;
  private sensor: CompassSensor = new CompassSensor();
  private active: boolean = false;
  private heading: number = 0;
  private accuracy: number = ACC_MEDIUM;

  private constructor() {
    this.sensor.onHeading = (heading: number, accuracy: number) => {
      this.heading = heading;
      this.accuracy = accuracy;
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
    };
    this.active = this.sensor.start();
    return this.active;
  }

  stop(): void {
    this.sensor.stop();
    this.active = false;
  }

  snapshot(): CompassMeasurementSnapshot {
    const out: CompassMeasurementSnapshot = new CompassMeasurementSnapshot();
    out.active = this.active;
    out.heading = this.active ? Math.round(this.heading) : -1;
    out.accuracy = this.accuracy;
    return out;
  }
}
