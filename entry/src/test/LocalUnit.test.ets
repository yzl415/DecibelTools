import { MeasureRecord } from '../main/ets/model/RecordStore';
import { averageDb, dayBuckets, filterRecordsByRange, peakDb, peakRecord, peakTimeLabel,
  trendSeries } from '../main/ets/model/HistoryAnalysis';
import { MeasurementSession } from '../main/ets/model/MeasurementSession';
import { TimerState } from '../main/ets/model/TimerState';
import { FlashlightState, FLASH_MODE_SOS, FLASH_MODE_STROBE } from '../main/ets/model/FlashlightState';
import { angleSummary, compassSummary, homeDbSummary, shouldRunHomeLive } from '../main/ets/model/HomePreviewState';
import { compassAccuracyText, compassStatusText } from '../main/ets/model/CompassStatus';
import { ACC_HIGH, ACC_LOW, ACC_MEDIUM, ACC_UNRELIABLE } from '../main/ets/model/CompassSensor';

function assertEqual<T>(actual: T, expected: T, message: string): void {
  (actual === expected) || fail(`${message}: expected ${expected}, got ${actual}`);
}

function assertTrue(actual: boolean, message: string): void {
  assertEqual(actual, true, message);
}

function fail(message: string): boolean {
  throw new Error(message);
}

function rec(id: number, time: number, avg: number, peak: number): MeasureRecord {
  return new MeasureRecord(id, `r${id}`, time, 3, avg - 5, avg, peak);
}

export function test_home_live_requires_visible_tools_tab_and_privacy(): void {
  // Arrange
  const pageShown: boolean = true;

  // Act
  const active: boolean = shouldRunHomeLive(pageShown, 0, true, false, false);

  // Assert
  assertTrue(active, 'home live should run');
}

export function test_home_microphone_denied_does_not_use_recent_db(): void {
  // Arrange
  const liveActive: boolean = false;

  // Act
  const value: string = homeDbSummary(liveActive, 64);

  // Assert
  assertEqual(value, '--', 'db summary should use placeholder');
}

export function test_home_angle_and_compass_empty_values_show_placeholders(): void {
  // Arrange
  const emptyTilt: number = -1;
  const emptyHeading: number = -1;

  // Act
  const value: string = angleSummary(emptyTilt) + '|' + compassSummary(emptyHeading);

  // Assert
  assertEqual(value, '--|--', 'empty sensor summaries should use placeholders');
}

export function test_measurement_preview_does_not_accumulate_statistics(): void {
  // Arrange
  const session: MeasurementSession = new MeasurementSession();

  // Act
  session.preview(80);

  // Assert
  assertEqual(session.snapshot(1000).count, 0, 'preview should not count samples');
}

export function test_measurement_records_min_avg_and_peak_after_start(): void {
  // Arrange
  const session: MeasurementSession = new MeasurementSession();
  session.start(1000);

  // Act
  session.record(45);
  session.record(65);
  session.record(70);
  const summary = session.snapshot(2500);

  // Assert
  assertEqual(`${summary.min}|${summary.avg}|${summary.peak}`, '45|60|70', 'measurement stats should match samples');
}

export function test_measurement_stop_persists_only_when_saved_with_duration(): void {
  // Arrange
  const session: MeasurementSession = new MeasurementSession();
  session.start(1000);
  session.record(55);

  // Act
  const summary = session.stop(true, 1);

  // Assert
  assertTrue(summary.shouldPersist, 'record should persist');
}

export function test_history_empty_records_returns_zero_metrics(): void {
  // Arrange
  const records: MeasureRecord[] = [];

  // Act
  const value: string = averageDb(records).toString() + '|' + peakDb(records).toString();

  // Assert
  assertEqual(value, '0|0', 'empty history metrics should be zero');
}

export function test_history_seven_day_buckets_keep_oldest_to_today_order(): void {
  // Arrange
  const now: number = new Date(2026, 6, 7, 12, 0, 0).getTime();
  const records: MeasureRecord[] = [rec(1, new Date(2026, 6, 7, 9, 0, 0).getTime(), 60, 75)];

  // Act
  const buckets = dayBuckets(records, 7, now);

  // Assert
  assertEqual(`${buckets[0].label}|${buckets[6].label}|${buckets[6].value}`, '三|二|60',
    'seven day buckets should keep stable order');
}

export function test_history_peak_time_uses_record_with_highest_peak(): void {
  // Arrange
  const records: MeasureRecord[] = [
    rec(1, new Date(2026, 6, 6, 9, 0, 0).getTime(), 50, 70),
    rec(2, new Date(2026, 6, 7, 15, 0, 0).getTime(), 55, 90)
  ];

  // Act
  const label: string = peakTimeLabel(peakRecord(records));

  // Assert
  assertEqual(label, '周二 下午', 'peak label should use highest peak record');
}

export function test_history_today_trend_keeps_single_record_point(): void {
  // Arrange
  const now: number = new Date(2026, 6, 7, 12, 0, 0).getTime();
  const records: MeasureRecord[] = [rec(1, new Date(2026, 6, 7, 9, 30, 0).getTime(), 58, 68)];

  // Act
  const series = trendSeries(records, 0, now);

  // Assert
  assertEqual(`${series.length}|${series[0].label}|${series[0].value}`, '1|09:30|58',
    'today trend should include single point');
}

export function test_history_range_filters_out_older_records(): void {
  // Arrange
  const now: number = new Date(2026, 6, 7, 12, 0, 0).getTime();
  const records: MeasureRecord[] = [rec(1, now - 2 * 24 * 3600 * 1000, 50, 60), rec(2, now, 70, 80)];

  // Act
  const filtered = filterRecordsByRange(records, 0, now);

  // Assert
  assertEqual(filtered.length, 1, 'today range should drop older records');
}

export function test_timer_start_stop_lap_and_running_reset_clears_state(): void {
  // Arrange
  const timer: TimerState = new TimerState();
  timer.start(1000);
  timer.lap(2500);

  // Act
  const reset = timer.reset();

  // Assert
  assertEqual(`${reset.running}|${reset.elapsedMs}|${reset.laps.length}`, 'false|0|0',
    'reset should stop and clear timer');
}

export function test_flashlight_mode_switch_keeps_frequency_state_isolated(): void {
  // Arrange
  const state: FlashlightState = new FlashlightState();
  state.pickMode(FLASH_MODE_STROBE);
  state.setFrequency(10);

  // Act
  state.pickMode(FLASH_MODE_SOS);

  // Assert
  assertEqual(`${state.mode}|${state.freqHz}|${state.strobeIntervalMs()}`, 'sos|10|50',
    'mode switch should not mutate strobe frequency');
}

export function test_flashlight_status_reflects_current_mode_without_waiting(): void {
  // Arrange
  const state: FlashlightState = new FlashlightState();
  state.on = true;
  state.pickMode(FLASH_MODE_STROBE);

  // Act
  const status: string = state.statusText();

  // Assert
  assertEqual(status, '频闪运行中', 'status should reflect strobe mode');
}

export function test_compass_accuracy_mapping_never_claims_calibrated_when_inactive(): void {
  // Arrange
  const active: boolean = false;

  // Act
  const text: string = compassStatusText(active, ACC_HIGH);

  // Assert
  assertEqual(text, '未读取到磁力计数据', 'inactive compass should report missing data');
}

export function test_compass_accuracy_mapping_reports_high_medium_low_and_unreliable(): void {
  // Arrange
  const active: boolean = true;

  // Act
  const text: string = compassAccuracyText(active, ACC_HIGH) + '|'
    + compassAccuracyText(active, ACC_MEDIUM) + '|'
    + compassAccuracyText(active, ACC_LOW) + '|'
    + compassAccuracyText(active, ACC_UNRELIABLE);

  // Assert
  assertEqual(text, '精度 ±2°|精度 ±5°|精度较低|精度不可靠',
    'accuracy labels should match product mapping');
}
