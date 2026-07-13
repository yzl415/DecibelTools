import { shouldRunHomeLive } from '../../../main/ets/model/HomePreviewState';

function assertEqual<T>(actual: T, expected: T, message: string): void {
  (actual === expected) || fail(`${message}: expected ${expected}, got ${actual}`);
}

function fail(message: string): boolean {
  throw new Error(message);
}

export function test_home_live_stops_outside_tools_tab(): void {
  // Arrange
  const settingsTab: number = 1;

  // Act
  const active: boolean = shouldRunHomeLive(true, settingsTab, false, true);

  // Assert
  assertEqual(active, false, 'home live should stop on settings tab');
}
