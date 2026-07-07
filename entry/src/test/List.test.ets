import { FlashlightState, FLASH_MODE_STROBE } from '../main/ets/model/FlashlightState';
import { TimerState } from '../main/ets/model/TimerState';

function assertEqual<T>(actual: T, expected: T, message: string): void {
  (actual === expected) || fail(`${message}: expected ${expected}, got ${actual}`);
}

function fail(message: string): boolean {
  throw new Error(message);
}

export function test_timer_lap_ignored_when_stopped(): void {
  // Arrange
  const timer: TimerState = new TimerState();

  // Act
  const snapshot = timer.lap(1000);

  // Assert
  assertEqual(snapshot.laps.length, 0, 'stopped timer should ignore lap');
}

export function test_flashlight_frequency_is_clamped_without_real_time_wait(): void {
  // Arrange
  const state: FlashlightState = new FlashlightState();
  state.pickMode(FLASH_MODE_STROBE);

  // Act
  state.setFrequency(99);

  // Assert
  assertEqual(state.freqHz, 20, 'frequency should clamp to maximum');
}
