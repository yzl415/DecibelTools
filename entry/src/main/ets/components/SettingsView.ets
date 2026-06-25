import { router } from '@kit.ArkUI';
import { getTheme, AppTheme, TOOL_GREEN, TOOL_INDIGO, TOOL_ORANGE, TOOL_PURPLE } from '../model/Theme';
import { SettingsStore } from '../model/SettingsStore';
import { AppIcon } from './AppIcon';

/** 设置 */
@Component
export struct SettingsView {
  @StorageProp('themeDark') themeDark: boolean = false;
  private store: SettingsStore = SettingsStore.getInstance();
  // 本地镜像，用于驱动刷新
  @State weighting: string = 'A';
  @State response: string = 'FAST';
  @State unit: string = 'cm';
  @State vibration: boolean = true;
  @State overAlert: boolean = true;

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
    AppStorage.setOrCreate('themeDark', dark);
    this.store.setThemeDark(dark);
  }

  build() {
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
            (this.store.calibration >= 0 ? '+' : '') + this.store.calibration.toFixed(1) + ' dB',
            () => router.pushUrl({ url: 'pages/CalibratePage' }))
          this.Divider()
          this.SegRow(this.th().tintIndigo, TOOL_INDIGO, 'A', '默认计权', ['A', 'C'],
            this.weighting, (v: string) => {
              this.weighting = v;
              this.store.setWeighting(v);
            })
          this.Divider()
          this.SegRow(this.th().tintIndigo, TOOL_INDIGO, 'T', '时间计权', ['FAST', 'SLOW'],
            this.response, (v: string) => {
              this.response = v;
              this.store.setResponse(v);
            })
          this.Divider()
          this.ToggleRow(this.th().tintOrange, TOOL_ORANGE, 'angle', '超标提醒', this.overAlert,
            (v: boolean) => {
              this.overAlert = v;
              this.store.setOverLimitAlert(v);
            })
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
            ['cm', 'in'], this.unit, (v: string) => {
              this.unit = v;
              this.store.setUnit(v);
            })
          this.Divider()
          this.NavRow(this.th().surfaceAlt, this.th().textSecondary, 'ruler', '屏幕校准',
            this.store.pxPerCm.toFixed(0) + ' px/cm',
            () => router.pushUrl({ url: 'pages/RulerPage' }))
          this.Divider()
          this.ToggleRow(this.th().surfaceAlt, this.th().textSecondary, 'timer', '震动反馈',
            this.vibration, (v: boolean) => {
              this.vibration = v;
              this.store.setVibration(v);
            })
        }
        .width('100%')
        .backgroundColor(this.th().surface)
        .borderRadius(16)
        .border({ width: 1, color: this.th().cardBorder })
        .clip(true)
        .margin({ bottom: 18 })

        this.SectionLabel('关于')
        Column() {
          this.NavRow(this.th().tintPurple, TOOL_PURPLE, 'shield', '隐私政策', '',
            () => router.pushUrl({ url: 'pages/Privacy' }))
        }
        .width('100%')
        .backgroundColor(this.th().surface)
        .borderRadius(16)
        .border({ width: 1, color: this.th().cardBorder })
        .clip(true)
        .margin({ bottom: 18 })

        Text('声活 · 分贝实用工具箱')
          .fontSize(12)
          .fontColor(this.th().textTertiary)
          .width('100%')
          .textAlign(TextAlign.Center)
        Text('VERSION 2.0.0')
          .fontSize(11)
          .fontFamily('HarmonyOS Sans')
          .fontColor(this.th().textTertiary)
          .opacity(0.7)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 3 })
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 12, bottom: 24 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }
  // PH_SETTINGS

  @Builder
  SectionLabel(text: string) {
    Text(text)
      .fontSize(10)
      .fontFamily('HarmonyOS Sans')
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
          .fontFamily('HarmonyOS Sans')
          .fontWeight(FontWeight.Bold)
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
        .fontFamily('HarmonyOS Sans')
        .fontColor(this.th().textSecondary)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(cb)
  }

  @Builder
  ToggleRow(tint: string, accent: string, icon: string, title: string, on: boolean, cb: (v: boolean) => void) {
    Row() {
      this.IconBox(tint, accent, icon)
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.th().textPrimary)
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: on })
        .selectedColor(this.th().accent)
        .onChange((v: boolean) => cb(v))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
  }

  @Builder
  SegRow(tint: string, accent: string, icon: string, title: string, opts: string[], cur: string, cb: (v: string) => void) {
    Row() {
      this.IconBox(tint, accent, icon)
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.th().textPrimary)
        .layoutWeight(1)
      Row() {
        ForEach(opts, (o: string) => {
          Text(o)
            .fontSize(11)
            .fontFamily('HarmonyOS Sans')
            .fontWeight(FontWeight.Bold)
            .fontColor(cur === o ? this.th().accentText : this.th().textTertiary)
            .padding({ left: 9, right: 9, top: 4, bottom: 4 })
            .backgroundColor(cur === o ? this.th().accent : '#00000000')
            .borderRadius(6)
            .onClick(() => cb(o))
        })
      }
      .padding(2)
      .backgroundColor(this.th().surfaceAlt)
      .borderRadius(8)
      .border({ width: 1, color: this.th().cardBorder })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 11, bottom: 11 })
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
    .padding({ left: 16, right: 16, top: 11, bottom: 11 })
  }
}
