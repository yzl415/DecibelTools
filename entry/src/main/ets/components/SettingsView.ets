import { getTheme, AppTheme, TOOL_GREEN, TOOL_INDIGO, TOOL_ORANGE, MONO, MONO_B,
  SCROLL_EDGE_ALWAYS_ENABLED } from '../model/Theme';
import { SettingsStore } from '../model/SettingsStore';
import { RecordStore } from '../model/RecordStore';
import { tapFeedback } from '../model/Haptics';
import { AppIcon } from './AppIcon';
import { DecibelMeasurementService } from '../model/DecibelMeasurementService';
import { APP_DISPLAY_NAME, formatVersionLabel, getAppVersionName } from '../model/AppMetadata';
import { formatCalibrationLabel, formatRecordCountLabel } from '../model/SettingsDisplay';

/** 设置 */
@Component
// code-linter-disable-next-line
export struct SettingsView {
  @StorageProp('themeDark') themeDark: boolean = false;
  @Prop calibration: number;
  @State recordCount: number = 0;
  onClearHistory: () => void = () => {};
  onOpenCalibration: () => void = () => {};
  private store: SettingsStore = SettingsStore.getInstance();
  private recordStore: RecordStore = RecordStore.getInstance();
  private measurement: DecibelMeasurementService = DecibelMeasurementService.getInstance();
  private versionName: string = getAppVersionName();
  // 本地镜像，用于驱动刷新
  @State weighting: string = 'A';
  @State response: string = 'FAST';
  @State unit: string = 'cm';
  @State vibration: boolean = true;
  @State overAlert: boolean = true;
  @State showClearConfirm: boolean = false;

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  aboutToAppear(): void {
    this.weighting = this.store.weighting;
    this.response = this.store.response;
    this.unit = this.store.unit;
    this.vibration = this.store.vibration;
    this.overAlert = this.store.overLimitAlert;
  }

  toggleTheme(dark: boolean): void {
    tapFeedback();
    AppStorage.setOrCreate('themeDark', dark);
    this.store.setThemeDark(dark);
  }

  syncMeasurementSettings(): void {
    this.measurement.configure(this.store.calibration, this.store.weighting,
      this.store.response, this.store.overLimitAlert);
  }

  clearHistory(): void {
    if (this.recordCount === 0) {
      return;
    }
    this.recordStore.clear();
    this.recordCount = 0;
    this.showClearConfirm = false;
    this.onClearHistory();
  }

  confirmClearHistory(): void {
    if (this.recordCount === 0) {
      return;
    }
    this.showClearConfirm = true;
  }

  selectSegment(key: string, value: string): void {
    if (key === 'weighting') {
      this.weighting = value;
      this.store.setWeighting(value);
      this.syncMeasurementSettings();
      return;
    }
    if (key === 'response') {
      this.response = value;
      this.store.setResponse(value);
      this.syncMeasurementSettings();
      return;
    }
    this.unit = value;
    this.store.setUnit(value);
  }

  toggleSetting(key: string, value: boolean): void {
    if (key === 'overAlert') {
      this.overAlert = value;
      this.store.setOverLimitAlert(value);
      this.syncMeasurementSettings();
      return;
    }
    this.vibration = value;
    this.store.setVibration(value);
    if (value) {
      tapFeedback();
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Scroll() {
        Column() {
        Text('设置')
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.th().textPrimary)
          .width('100%')
          .margin({ bottom: 18 })

        this.SectionLabel('分贝仪')
        Column() {
          this.NavRow(this.th().tintGreen, TOOL_GREEN, 'wave', '麦克风校准',
            formatCalibrationLabel(this.calibration),
            () => this.onOpenCalibration())
          this.Divider()
          this.SegRow(this.th().tintIndigo, TOOL_INDIGO, 'A', '计权修正', ['A', 'C'], 'weighting')
          this.Divider()
          this.SegRow(this.th().tintIndigo, TOOL_INDIGO, 'T', '时间计权', ['FAST', 'SLOW'], 'response')
          this.Divider()
          this.ToggleRow(this.th().tintOrange, TOOL_ORANGE, 'angle', '超标震动', 'overAlert')
        }
        .width('100%')
        .backgroundColor(this.th().surface)
        .borderRadius(16)
        .border({ width: 1, color: this.th().cardBorder })
        .clip(true)
        .margin({ bottom: 18 })

        this.SectionLabel('通用')
        Column() {
          this.ThemeRow()
          this.Divider()
          this.SegRow(this.th().surfaceAlt, this.th().textSecondary, 'ruler', '标尺单位',
            ['cm', 'in'], 'unit')
          this.Divider()
          this.ToggleRow(this.th().surfaceAlt, this.th().textSecondary, 'timer', '震动反馈', 'vibration')
        }
        .width('100%')
        .backgroundColor(this.th().surface)
        .borderRadius(16)
        .border({ width: 1, color: this.th().cardBorder })
        .clip(true)
        .margin({ bottom: 18 })

        this.SectionLabel('数据')
        Column() {
          this.NavRow(this.th().surfaceAlt, this.th().textSecondary, 'list', '清空测量历史',
            formatRecordCountLabel(this.recordCount), () => this.confirmClearHistory())
        }
        .width('100%')
        .backgroundColor(this.th().surface)
        .borderRadius(16)
        .border({ width: 1, color: this.th().cardBorder })
        .clip(true)
        .margin({ bottom: 18 })

        Text(APP_DISPLAY_NAME)
          .fontSize(12)
          .fontColor(this.th().textTertiary)
          .width('100%')
          .textAlign(TextAlign.Center)
        Text(formatVersionLabel(this.versionName))
          .fontSize(11)
          .fontFamily(MONO)
          .fontColor(this.th().textTertiary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 3 })
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 12, bottom: 24 })
      }
      .width('100%')
      .height('100%')
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: SCROLL_EDGE_ALWAYS_ENABLED })
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

      if (this.showClearConfirm) {
        this.ClearHistoryConfirm()
      }
    }
    .layoutWeight(1)
    .width('100%')
    .height('100%')
  }
  // PH_SETTINGS

  @Builder
  SectionLabel(text: string) {
    Text(text)
      .fontSize(10)
      .fontFamily(MONO)
      .fontColor(this.th().textTertiary)
      .letterSpacing(1.6)
      .width('100%')
      .margin({ left: 2, bottom: 10 })
  }

  @Builder
  Divider() {
    Row().height(1).backgroundColor(this.th().divider).margin({ left: 59 })
  }

  @Builder
  IconBox(tint: string, accent: string, icon: string) {
    Stack() {
      Column().width(30).height(30).borderRadius(9).backgroundColor(tint)
      if (icon === 'A' || icon === 'T') {
        Text(icon)
          .fontSize(12)
          .fontFamily(MONO_B)
          .fontColor(accent)
      } else {
        AppIcon({ name: icon, color: accent, iconSize: 15, cutout: tint })
      }
    }
    .margin({ right: 13 })
  }

  @Builder
  NavRow(tint: string, accent: string, icon: string, title: string, value: string, cb: () => void) {
    Row() {
      this.IconBox(tint, accent, icon)
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.th().textPrimary)
        .layoutWeight(1)
      Text(value + (value.length > 0 ? ' ›' : '›'))
        .fontSize(13)
        .fontFamily(MONO)
        .fontColor(this.th().textSecondary)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(cb)
  }

  @Builder
  ToggleRow(tint: string, accent: string, icon: string, title: string, key: string) {
    Row() {
      this.IconBox(tint, accent, icon)
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.th().textPrimary)
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch,
        isOn: key === 'overAlert' ? this.overAlert : this.vibration })
        .selectedColor(this.th().accent)
        .onChange((v: boolean) => this.toggleSetting(key, v))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  @Builder
  SegRow(tint: string, accent: string, icon: string, title: string, opts: string[], key: string) {
    Row() {
      this.IconBox(tint, accent, icon)
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.th().textPrimary)
        .layoutWeight(1)
      Row() {
        ForEach(opts, (o: string) => {
          Button(o)
            .height(26)
            .fontSize(11)
            .fontFamily(MONO_B)
            .fontColor((key === 'weighting' ? this.weighting === o
              : (key === 'response' ? this.response === o : this.unit === o))
              ? this.th().accentText : this.th().textTertiary)
            .padding({ left: 9, right: 9, top: 4, bottom: 4 })
            .backgroundColor((key === 'weighting' ? this.weighting === o
              : (key === 'response' ? this.response === o : this.unit === o))
              ? this.th().accent : '#00000000')
            .borderRadius(6)
            .stateEffect(true)
            .onClick(() => this.selectSegment(key, o))
        }, (o: string) => o)
      }
      .padding(2)
      .backgroundColor(this.th().surfaceAlt)
      .borderRadius(8)
      .border({ width: 1, color: this.th().cardBorder })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  @Builder
  ThemeRow() {
    Row() {
      this.IconBox(this.th().surfaceAlt, this.th().textSecondary, this.themeDark ? 'moon' : 'sun')
      Text('深色外观')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.th().textPrimary)
        .layoutWeight(1)
      Row() {
        Text('浅')
          .fontSize(11)
          .fontColor(!this.themeDark ? this.th().accentText : this.th().textTertiary)
          .padding({ left: 9, right: 9, top: 3, bottom: 3 })
          .backgroundColor(!this.themeDark ? this.th().textPrimary : '#00000000')
          .borderRadius(6)
          .onClick(() => this.toggleTheme(false))
        Text('深')
          .fontSize(11)
          .fontColor(this.themeDark ? this.th().bg : this.th().textTertiary)
          .padding({ left: 9, right: 9, top: 3, bottom: 3 })
          .backgroundColor(this.themeDark ? '#E6E8EC' : '#00000000')
          .borderRadius(6)
          .onClick(() => this.toggleTheme(true))
      }
      .padding(2)
      .backgroundColor(this.th().surfaceAlt)
      .borderRadius(8)
      .border({ width: 1, color: this.th().cardBorder })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  @Builder
  ClearHistoryConfirm() {
    Column() {
      Column() {
        Text('清空测量历史')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.th().textPrimary)
          .width('100%')
        Text(`将删除全部 ${this.recordCount} 条本地测量记录，此操作不可撤销。`)
          .fontSize(14)
          .lineHeight(21)
          .fontColor(this.th().textSecondary)
          .width('100%')
          .margin({ top: 10, bottom: 20 })
        Row({ space: 10 }) {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .fontColor(this.th().textPrimary)
            .backgroundColor(this.th().surfaceAlt)
            .onClick(() => this.showClearConfirm = false)
          Button('清空')
            .layoutWeight(1)
            .height(44)
            .fontColor('#FFFFFF')
            .backgroundColor(this.th().danger)
            .onClick(() => this.clearHistory())
        }
        .width('100%')
      }
      .width('84%')
      .padding(22)
      .backgroundColor(this.th().surface)
      .borderRadius(16)
      .border({ width: 1, color: this.th().cardBorder })
    }
    .id('clear-history-confirm')
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#99000000')
  }
}
