import { router } from '@kit.ArkUI';
import { getTheme, AppTheme, TOOL_GREEN , MONO, MONO_B } from '../model/Theme';
import { SettingsStore } from '../model/SettingsStore';

/** 麦克风校准：用滑块叠加偏移，使读数对齐已知参考声级计。 */
@Entry
@Component
struct CalibratePage {
  @StorageProp('themeDark') themeDark: boolean = false;
  @State calibration: number = 0;
  private store: SettingsStore = SettingsStore.getInstance();

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  aboutToAppear(): void {
    this.calibration = this.store.calibration;
  }

  save(v: number): void {
    this.calibration = Math.round(v * 10) / 10;
    this.store.setCalibration(this.calibration);
  }

  build() {
    Column() {
      this.NavBar()
      Column() {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(160).height(160).fill(this.th().surface)
            .border({ width: 1, color: this.th().cardBorder })
            .shadow({ radius: this.th().isDark ? 0 : 12, color: '#14000000', offsetY: 6 })
          Column() {
            Text((this.calibration >= 0 ? '+' : '') + this.calibration.toFixed(1))
              .fontSize(44)
              .fontFamily(MONO_B)
              .fontColor(this.th().accentStrong)
            Text('dB 偏移')
              .fontSize(12)
              .fontColor(this.th().textSecondary)
              .margin({ top: 4 })
          }
        }
        .margin({ top: 24, bottom: 28 })

        Column() {
          Row() {
            Text('-15')
              .fontSize(11).fontFamily(MONO).fontColor(this.th().textTertiary)
            Blank().layoutWeight(1)
            Text('+15')
              .fontSize(11).fontFamily(MONO).fontColor(this.th().textTertiary)
          }
          .width('100%')
          Slider({ value: this.calibration, min: -15, max: 15, step: 0.5 })
            .width('100%')
            .blockColor('#FFFFFF')
            .selectedColor(TOOL_GREEN)
            .trackColor(this.th().track)
            .onChange((v: number) => this.save(v))
        }
        .width('100%')
        .padding(18)
        .backgroundColor(this.th().surface)
        .borderRadius(16)
        .border({ width: 1, color: this.th().cardBorder })

        Row({ space: 9 }) {
          this.QuickBtn('归零', () => this.save(0))
          this.QuickBtn('-1.0', () => this.save(Math.max(-15, this.calibration - 1)))
          this.QuickBtn('+1.0', () => this.save(Math.min(15, this.calibration + 1)))
        }
        .width('100%')
        .margin({ top: 12 })

        Text('校准方法：找一台已知准确的声级计或参考源，对比本应用读数，拖动滑块使两者一致。该偏移会叠加到所有测量。')
          .fontSize(12)
          .lineHeight(20)
          .fontColor(this.th().textTertiary)
          .width('100%')
          .margin({ top: 20 })
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 22, right: 22 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.th().bg)
  }
  // PH_CAL

  @Builder
  QuickBtn(label: string, cb: () => void) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.th().textPrimary)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .padding({ top: 13, bottom: 13 })
      .backgroundColor(this.th().surface)
      .borderRadius(14)
      .border({ width: 1, color: this.th().cardBorder })
      .onClick(cb)
  }

  @Builder
  NavBar() {
    Row() {
      Stack() {
        Column().width(36).height(36).borderRadius(11).backgroundColor(this.th().surfaceAlt)
          .border({ width: this.th().isDark ? 1 : 0, color: this.th().cardBorder })
        Text('‹').fontSize(22).fontColor(this.th().textSecondary).margin({ bottom: 2 })
      }
      .onClick(() => router.back())
      Text('麦克风校准')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.th().textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Column().width(36).height(36)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 8 })
  }
}
