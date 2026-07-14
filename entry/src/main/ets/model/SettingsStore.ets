/**
 * 应用设置仓库：主题 / 引导 / 分贝校准 / 计权 / 时间计权 /
 * 标尺单位 / 震动 / 超标提醒。preferences 持久化，单例。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME: string = 'decibel_settings';
const KEY_THEME_DARK: string = 'theme_dark';
const KEY_ONBOARDED: string = 'onboarded';
const KEY_CALIBRATION: string = 'db_calibration';
const KEY_MAX_DB: string = 'history_max_db';
const KEY_WEIGHTING: string = 'db_weighting';     // 'A' | 'C'
const KEY_RESPONSE: string = 'db_response';        // 'FAST' | 'SLOW'
const KEY_UNIT: string = 'ruler_unit';             // 'cm' | 'in'
const KEY_VIBRATION: string = 'vibration';
const KEY_OVER_ALERT: string = 'over_limit_alert';

export class SettingsStore {
  private static instance: SettingsStore | null = null;
  private store: preferences.Preferences | null = null;
  themeDark: boolean = false;
  onboarded: boolean = false;
  calibration: number = 0;       // 分贝校准偏移（dB）
  historyMaxDb: number = 0;      // 历史最高分贝
  weighting: string = 'A';       // 计权 A/C
  response: string = 'FAST';     // 时间计权 FAST/SLOW
  unit: string = 'cm';           // 标尺单位
  vibration: boolean = true;     // 震动反馈
  overLimitAlert: boolean = true; // 超标提醒

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
      this.onboarded = await this.store.get(KEY_ONBOARDED, false) as boolean;
      this.calibration = await this.store.get(KEY_CALIBRATION, 0) as number;
      this.historyMaxDb = await this.store.get(KEY_MAX_DB, 0) as number;
      this.weighting = await this.store.get(KEY_WEIGHTING, 'A') as string;
      this.response = await this.store.get(KEY_RESPONSE, 'FAST') as string;
      this.unit = await this.store.get(KEY_UNIT, 'cm') as string;
      this.vibration = await this.store.get(KEY_VIBRATION, true) as boolean;
      this.overLimitAlert = await this.store.get(KEY_OVER_ALERT, true) as boolean;
    } catch (e) {
      this.store = null;
    }
  }

  async setThemeDark(dark: boolean): Promise<void> {
    this.themeDark = dark;
    await this.putFlush(KEY_THEME_DARK, dark);
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

  async setWeighting(v: string): Promise<void> {
    this.weighting = v;
    await this.putFlush(KEY_WEIGHTING, v);
  }

  async setResponse(v: string): Promise<void> {
    this.response = v;
    await this.putFlush(KEY_RESPONSE, v);
  }

  async setUnit(v: string): Promise<void> {
    this.unit = v;
    await this.putFlush(KEY_UNIT, v);
  }

  async setVibration(v: boolean): Promise<void> {
    this.vibration = v;
    await this.putFlush(KEY_VIBRATION, v);
  }

  async setOverLimitAlert(v: boolean): Promise<void> {
    this.overLimitAlert = v;
    await this.putFlush(KEY_OVER_ALERT, v);
  }

  private async putFlush(key: string, value: boolean | number | string): Promise<void> {
    if (this.store === null) {
      return;
    }
    try {
      await this.store.put(key, value);
      await this.store.flush();
    } catch (e) {
      this.store = null;
    }
  }
}
