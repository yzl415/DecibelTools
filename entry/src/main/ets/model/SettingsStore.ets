/**
 * 应用设置仓库：主题 / 隐私同意 / 引导 / 分贝校准值。
 * preferences 持久化，单例。从 HabitTracker 的 HabitStore 精简而来。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME: string = 'decibel_settings';
const KEY_THEME_DARK: string = 'theme_dark';
const KEY_PRIVACY_AGREED: string = 'privacy_agreed';
const KEY_ONBOARDED: string = 'onboarded';
const KEY_CALIBRATION: string = 'db_calibration';
const KEY_MAX_DB: string = 'history_max_db';

export class SettingsStore {
  private static instance: SettingsStore | null = null;
  private store: preferences.Preferences | null = null;
  themeDark: boolean = false;
  privacyAgreed: boolean = false;
  onboarded: boolean = false;
  calibration: number = 0;     // 分贝校准偏移（dB）
  historyMaxDb: number = 0;    // 历史最高分贝

  static getInstance(): SettingsStore {
    if (SettingsStore.instance === null) {
      SettingsStore.instance = new SettingsStore();
    }
    return SettingsStore.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.store !== null) {
      return;
    }
    try {
      this.store = await preferences.getPreferences(context, STORE_NAME);
      this.themeDark = await this.store.get(KEY_THEME_DARK, false) as boolean;
      this.privacyAgreed = await this.store.get(KEY_PRIVACY_AGREED, false) as boolean;
      this.onboarded = await this.store.get(KEY_ONBOARDED, false) as boolean;
      this.calibration = await this.store.get(KEY_CALIBRATION, 0) as number;
      this.historyMaxDb = await this.store.get(KEY_MAX_DB, 0) as number;
    } catch (e) {
      this.store = null;
    }
  }

  async setThemeDark(dark: boolean): Promise<void> {
    this.themeDark = dark;
    await this.putFlush(KEY_THEME_DARK, dark);
  }

  async setPrivacyAgreed(): Promise<void> {
    this.privacyAgreed = true;
    await this.putFlush(KEY_PRIVACY_AGREED, true);
  }

  async setOnboarded(): Promise<void> {
    this.onboarded = true;
    await this.putFlush(KEY_ONBOARDED, true);
  }

  async setCalibration(v: number): Promise<void> {
    this.calibration = v;
    await this.putFlush(KEY_CALIBRATION, v);
  }

  async setHistoryMaxDb(v: number): Promise<void> {
    this.historyMaxDb = v;
    await this.putFlush(KEY_MAX_DB, v);
  }

  private async putFlush(key: string, value: boolean | number): Promise<void> {
    if (this.store === null) {
      return;
    }
    await this.store.put(key, value);
    await this.store.flush();
  }
}
