import { FlashlightState, FLASH_MODE_STROBE } from '../main/ets/model/FlashlightState';
import { TimerState } from '../main/ets/model/TimerState';
import {
  test_compass_accuracy_mapping_never_claims_calibrated_when_inactive,
  test_compass_accuracy_mapping_reports_high_medium_low_and_unreliable,
  test_decibel_response_fast_tracks_level_jump_more_than_slow,
  test_decibel_weighting_change_rebases_current_level,
  test_flashlight_mode_switch_keeps_frequency_state_isolated,
  test_flashlight_status_reflects_current_mode_without_waiting,
  test_history_empty_records_returns_zero_metrics,
  test_history_peak_time_uses_record_with_highest_peak,
  test_history_range_filters_out_older_records,
  test_history_seven_day_buckets_keep_oldest_to_today_order,
  test_history_today_trend_keeps_single_record_point,
  test_home_angle_and_compass_empty_values_show_placeholders,
  test_home_live_requires_visible_tools_tab_and_privacy,
  test_home_live_restarts_after_detail_return_to_tools_tab,
  test_home_live_title_reports_realtime_when_active,
  test_home_live_waits_until_measurement_has_started,
  test_home_microphone_denied_does_not_use_recent_db,
  test_measurement_preview_does_not_accumulate_statistics,
  test_measurement_records_min_avg_and_peak_after_start,
  test_measurement_stop_persists_only_when_saved_with_duration,
  test_ruler_calibration_rejects_mismatched_marker_gap,
  test_ruler_calibration_presets_avoid_oversized_references,
  test_ruler_calibration_sets_selected_reference_length,
  test_ruler_default_scale_uses_system_density,
  test_timer_start_stop_lap_and_running_reset_clears_state
} from './LocalUnit.test';

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

export default function testsuite(): void {
  test_timer_lap_ignored_when_stopped();
  test_flashlight_frequency_is_clamped_without_real_time_wait();
  test_home_live_requires_visible_tools_tab_and_privacy();
  test_home_live_waits_until_measurement_has_started();
  test_home_live_restarts_after_detail_return_to_tools_tab();
  test_home_microphone_denied_does_not_use_recent_db();
  test_home_live_title_reports_realtime_when_active();
  test_home_angle_and_compass_empty_values_show_placeholders();
  test_measurement_preview_does_not_accumulate_statistics();
  test_measurement_records_min_avg_and_peak_after_start();
  test_measurement_stop_persists_only_when_saved_with_duration();
  test_decibel_weighting_change_rebases_current_level();
  test_decibel_response_fast_tracks_level_jump_more_than_slow();
  test_ruler_calibration_sets_selected_reference_length();
  test_ruler_calibration_presets_avoid_oversized_references();
  test_ruler_default_scale_uses_system_density();
  test_ruler_calibration_rejects_mismatched_marker_gap();
  test_history_empty_records_returns_zero_metrics();
  test_history_seven_day_buckets_keep_oldest_to_today_order();
  test_history_peak_time_uses_record_with_highest_peak();
  test_history_today_trend_keeps_single_record_point();
  test_history_range_filters_out_older_records();
  test_timer_start_stop_lap_and_running_reset_clears_state();
  test_flashlight_mode_switch_keeps_frequency_state_isolated();
  test_flashlight_status_reflects_current_mode_without_waiting();
  test_compass_accuracy_mapping_never_claims_calibrated_when_inactive();
  test_compass_accuracy_mapping_reports_high_medium_low_and_unreliable();
}
