import { describe, it } from '@ohos/hypium';
import { compassStatusText } from '../../../main/ets/model/CompassStatus';
import { ACC_LOW } from '../../../main/ets/model/CompassSensor';
import { test_home_live_stops_outside_tools_tab } from './Ability.test';
import { HardwareReadingState } from '../../../main/ets/model/HardwareReadingState';

function assertEqual<T>(actual: T, expected: T, message: string): void {
  (actual === expected) || fail(`${message}: expected ${expected}, got ${actual}`);
}

function fail(message: string): boolean {
  throw new Error(message);
}

export function test_compass_low_accuracy_requests_calibration(): void {
  // Arrange
  const active: boolean = true;

  // Act
  const text: string = compassStatusText(active, ACC_LOW);

  // Assert
  assertEqual(text, '建议校准 · 远离磁性物体', 'low accuracy should request calibration');
}

export function test_hardware_reading_recovers_after_new_sample(): void {
  // Arrange
  const state: HardwareReadingState = new HardwareReadingState();
  state.markStarted(1000);
  state.snapshot(3000);

  // Act
  state.markReading(3100);
  const snapshot = state.snapshot(3100);

  // Assert
  assertEqual(snapshot.available, true, 'hardware state should recover after a new sample');
}

export default function testsuite(): void {
  describe('DecibelTools device behavior', () => {
    it('test_compass_low_accuracy_requests_calibration', 0, test_compass_low_accuracy_requests_calibration);
    it('test_hardware_reading_recovers_after_new_sample', 0, test_hardware_reading_recovers_after_new_sample);
    it('test_home_live_stops_outside_tools_tab', 0, test_home_live_stops_outside_tools_tab);
  });
}
