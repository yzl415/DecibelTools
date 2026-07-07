import { compassStatusText } from '../../../main/ets/model/CompassStatus';
import { ACC_LOW } from '../../../main/ets/model/CompassSensor';

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
