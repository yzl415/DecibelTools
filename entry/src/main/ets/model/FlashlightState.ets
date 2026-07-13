export const FLASH_MODE_STEADY: string = 'steady';
export const FLASH_MODE_STROBE: string = 'strobe';
export const FLASH_MODE_SOS: string = 'sos';

export function shouldSyncFlashlightHardwareState(mode: string): boolean {
  return mode === FLASH_MODE_STEADY;
}

export class FlashlightState {
  on: boolean = false;
  mode: string = FLASH_MODE_STEADY;
  freqHz: number = 5;

  turnOff(): void {
    this.on = false;
  }

  toggleOn(): void {
    this.on = !this.on;
  }

  pickMode(mode: string): void {
    this.mode = mode;
  }

  setFrequency(hz: number): void {
    this.freqHz = Math.max(1, Math.min(20, Math.round(hz)));
  }

  strobeIntervalMs(): number {
    return Math.round(1000 / (this.freqHz * 2));
  }

  statusText(): string {
    if (!this.on) {
      return '已关闭';
    }
    if (this.mode === FLASH_MODE_STROBE) {
      return '频闪运行中';
    }
    if (this.mode === FLASH_MODE_SOS) {
      return 'SOS 求救信号';
    }
    return '已开启';
  }
}
