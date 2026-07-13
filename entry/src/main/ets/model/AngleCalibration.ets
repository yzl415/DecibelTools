export class AngleCalibration {
  private pitchOffset: number = 0;
  private rollOffset: number = 0;
  private active: boolean = false;

  setReference(pitch: number, roll: number): void {
    this.pitchOffset = pitch;
    this.rollOffset = roll;
    this.active = true;
  }

  clear(): void {
    this.pitchOffset = 0;
    this.rollOffset = 0;
    this.active = false;
  }

  isActive(): boolean {
    return this.active;
  }

  applyPitch(pitch: number): number {
    return pitch - this.pitchOffset;
  }

  applyRoll(roll: number): number {
    return roll - this.rollOffset;
  }
}
