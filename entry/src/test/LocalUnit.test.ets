import { MeasureRecord } from '../main/ets/model/RecordStore';
import { averageDb, dayBuckets, filterRecordsByRange, peakDb, peakRecord, peakTimeLabel,
  trendSeries } from '../main/ets/model/HistoryAnalysis';
import { MeasurementSession } from '../main/ets/model/MeasurementSession';
import { DecibelLevelProcessor } from '../main/ets/model/DecibelLevelProcessor';
import { DECIBEL_SPECTRUM_MIN_HEIGHT, decibelFromSpectrumHeight, normalizeDecibelDisplayDb,
  formatDecibelStatValue, normalizeDecibelSpectrumHeight } from '../main/ets/model/DecibelDisplayRange';
import { resolvedRulerPxPerCm, rulerSelectionBounds, systemPxPerCm } from '../main/ets/model/RulerCalibration';
import { TimerState } from '../main/ets/model/TimerState';
import { FlashlightState, FLASH_MODE_SOS, FLASH_MODE_STROBE } from '../main/ets/model/FlashlightState';
import { angleSummary, compassSummary, homeDbSummary, homeNoiseTitle, shouldRunHomeLive } from '../main/ets/model/HomePreviewState';
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
  const active: boolean = shouldRunHomeLive(pageShown, 0, true, false, false, true);

  // Assert
  assertTrue(active, 'home live should run');
}

export function test_home_live_waits_until_measurement_has_started(): void {
  // Arrange
  const measurementStarted: boolean = false;

  // Act
  const active: boolean = shouldRunHomeLive(true, 0, true, false, false, measurementStarted);

  // Assert
  assertEqual(active, false, 'home live should wait for measurement start');
}

export function test_home_live_restarts_after_detail_return_to_tools_tab(): void {
  // Arrange
  const pageShownAfterReturn: boolean = true;

  // Act
  const active: boolean = shouldRunHomeLive(pageShownAfterReturn, 0, true, false, false, true);

  // Assert
  assertTrue(active, 'home live should restart after returning to tools tab');
}

export function test_home_microphone_denied_does_not_use_recent_db(): void {
  // Arrange
  const liveActive: boolean = false;

  // Act
  const value: string = homeDbSummary(liveActive, 64);

  // Assert
  assertEqual(value, '--', 'db summary should use placeholder');
}

export function test_home_live_title_reports_realtime_when_active(): void {
  // Arrange
  const liveActive: boolean = true;

  // Act
  const title: string = homeNoiseTitle(liveActive);

  // Assert
  assertEqual(title, '环境噪音 · 实时', 'home live title should report realtime state');
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

export function test_decibel_weighting_change_rebases_current_level(): void {
  // Arrange
  const processor: DecibelLevelProcessor = new DecibelLevelProcessor();
  processor.configure(0, 'A', 'FAST');
  const aWeighted: number = processor.processBaseSpl(60);

  // Act
  processor.configure(0, 'C', 'FAST');
  const cWeighted: number = processor.current();

  // Assert
  assertEqual(`${Math.round(aWeighted)}|${Math.round(cWeighted)}`, '56|60',
    'weighting change should immediately rebase current level');
}

export function test_decibel_response_fast_tracks_level_jump_more_than_slow(): void {
  // Arrange
  const fast: DecibelLevelProcessor = new DecibelLevelProcessor();
  const slow: DecibelLevelProcessor = new DecibelLevelProcessor();
  fast.configure(0, 'C', 'FAST');
  slow.configure(0, 'C', 'SLOW');
  fast.processBaseSpl(50);
  slow.processBaseSpl(50);

  // Act
  const fastAfterJump: number = fast.processBaseSpl(80);
  const slowAfterJump: number = slow.processBaseSpl(80);

  // Assert
  assertTrue(fastAfterJump > slowAfterJump + 10, 'fast response should track a level jump sooner');
}

export function test_decibel_display_range_clamps_values_above_gauge_maximum(): void {
  // Arrange
  const db: number = 135;

  // Act
  const normalized: number = normalizeDecibelDisplayDb(db);
  const mappedDb: number = decibelFromSpectrumHeight(normalized);

  // Assert
  assertEqual(`${normalized}|${mappedDb}`, '1|120', 'display range should clamp above the gauge maximum');
}

export function test_decibel_spectrum_height_keeps_low_values_visible(): void {
  // Arrange
  const db: number = 20;

  // Act
  const height: number = normalizeDecibelSpectrumHeight(db);

  // Assert
  assertEqual(height, DECIBEL_SPECTRUM_MIN_HEIGHT, 'spectrum should keep a visible minimum height');
}

export function test_decibel_stat_value_rounds_live_sample(): void {
  // Arrange
  const liveSample: number = 58.6;

  // Act
  const value: string = formatDecibelStatValue(liveSample);

  // Assert
  assertEqual(value, '59', 'stat value should round live sample');
}

export function test_ruler_default_scale_uses_system_density(): void {
  // Arrange
  const systemScale: number = systemPxPerCm(480, 3);

  // Act
  const scale: number = resolvedRulerPxPerCm(systemScale);

  // Assert
  assertEqual(scale, 63, 'default ruler scale should use system density');
}

export function test_ruler_default_scale_uses_fallback_without_system_density(): void {
  // Arrange
  const missingSystemScale: number = 0;

  // Act
  const scale: number = resolvedRulerPxPerCm(missingSystemScale);

  // Assert
  assertEqual(scale, 38, 'default ruler scale should use fallback without system density');
}

export function test_ruler_selection_bounds_follow_marker_positions(): void {
  // Arrange
  const topMarkerY: number = 72;
  const bottomMarkerY: number = 348;

  // Act
  const bounds = rulerSelectionBounds(topMarkerY, bottomMarkerY);

  // Assert
  assertEqual(`${bounds.top}|${bounds.bottom}|${bounds.height}|${bounds.center}`, '72|348|276|210',
    'selection bounds should follow marker positions');
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
