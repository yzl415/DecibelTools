import { router } from '@kit.ArkUI';
import { getTheme, AppTheme, TOOL_GREEN, TOOL_INDIGO, withAlpha } from '../model/Theme';
import { AngleSensor } from '../model/AngleSensor';
import { AppIcon } from '../components/AppIcon';

@Entry
@Component
struct AnglePage {
  @StorageProp('themeDark') themeDark: boolean = false;
  @State pitch: number = 0;
  @State roll: number = 0;
  @State active: boolean = false;
  private sensor: AngleSensor = new AngleSensor();
  private lastPitch: number = 0;
  private lastRoll: number = 0;
  private calPitch: number = 0;
  private calRoll: number = 0;
  private uiTimer: number = -1;

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  aboutToAppear(): void {
    this.sensor.onAngle = (pitch: number, roll: number) => {
      this.lastPitch = pitch;
      this.lastRoll = roll;
    };
    this.active = this.sensor.start();
    this.uiTimer = setInterval(() => {
      this.pitch = Math.round((this.lastPitch - this.calPitch) * 10) / 10;
      this.roll = Math.round((this.lastRoll - this.calRoll) * 10) / 10;
    }, 100);
  }

  aboutToDisappear(): void {
    if (this.uiTimer !== -1) {
      clearInterval(this.uiTimer);
      this.uiTimer = -1;
    }
    this.sensor.stop();
  }

  isLevel(): boolean {
    return Math.abs(this.pitch) < 1 && Math.abs(this.roll) < 1;
  }

  calibrate(): void {
    this.calPitch = this.lastPitch;
    this.calRoll = this.lastRoll;
  }

  // 合成倾角（两轴矢量和）
  tilt(): number {
    return Math.round(Math.sqrt(this.pitch * this.pitch + this.roll * this.roll) * 10) / 10;
  }

  build() {
    Column() {
      this.NavBar()
      Column() {
        // 气泡水平仪盘
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(248).height(248)
            .fill(this.th().gaugeOuter)
            .shadow({ radius: this.th().isDark ? 0 : 12, color: '#1A000000', offsetY: 6 })
            .border({ width: 1, color: this.th().cardBorder })
          Circle().width(168).height(168).fill('#00000000')
            .border({ width: 1.5, color: this.th().divider })
          Circle().width(80).height(80).fill('#00000000')
            .border({ width: 1.5, color: this.th().divider })
          Column().width(212).height(1.5).backgroundColor(this.th().divider)
          Column().width(1.5).height(212).backgroundColor(this.th().divider)
          // 目标环
          Circle().width(62).height(62).fill('#00000000')
            .border({ width: 2, color: withAlpha(TOOL_GREEN, '73') })
          // 气泡
          Circle().width(50).height(50)
            .fill(this.isLevel() ? this.th().accent : TOOL_INDIGO)
            .shadow({ radius: 16, color: withAlpha(this.isLevel() ? TOOL_GREEN : TOOL_INDIGO, '99') })
            .offset({
              x: Math.max(-95, Math.min(95, this.roll * 3)),
              y: Math.max(-95, Math.min(95, -this.pitch * 3))
            })
          Text(this.tilt().toFixed(1) + '°')
            .fontSize(15)
            .fontFamily('HarmonyOS Sans')
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isLevel() ? '#FFFFFF' : '#FFFFFF')
            .offset({
              x: Math.max(-95, Math.min(95, this.roll * 3)),
              y: Math.max(-95, Math.min(95, -this.pitch * 3))
            })
        }
        .margin({ top: 6 })

        Row() {
          Circle().width(6).height(6).fill(this.isLevel() ? this.th().success : this.th().textTertiary)
          Text(this.isLevel() ? '已水平' : '调整中')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isLevel() ? this.th().success : this.th().textSecondary)
            .margin({ left: 6 })
        }
        .margin({ top: 18 })

        Row({ space: 9 }) {
          this.AngleBox('横向 ROLL', this.roll)
          this.AngleBox('纵向 PITCH', this.pitch)
        }
        .width('100%')
        .margin({ top: 20 })

        Row() {
          Column().width(13).height(13).borderRadius(3).backgroundColor(TOOL_INDIGO)
          Text('校准归零')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.th().textPrimary)
            .margin({ left: 9 })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .padding({ top: 15, bottom: 15 })
        .backgroundColor(this.th().surface)
        .borderRadius(16)
        .border({ width: 1, color: this.th().cardBorder })
        .margin({ top: 14 })
        .onClick(() => this.calibrate())

        if (!this.active) {
          Text('未能读取到传感器数据，当前设备可能不支持。')
            .fontSize(13)
            .fontColor(this.th().danger)
            .margin({ top: 16 })
        }
        Text('提示：将手机平放后点击校准归零。读数仅供参考。')
          .fontSize(11)
          .fontColor(this.th().textTertiary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 18 })
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 22, right: 22 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.th().bg)
  }
  // PH_ANGLE

  @Builder
  AngleBox(label: string, value: number) {
    Column() {
      Text(value.toFixed(1) + '°')
        .fontSize(24)
        .fontFamily('HarmonyOS Sans')
        .fontWeight(FontWeight.Bold)
        .fontColor(this.th().textPrimary)
      Text(label)
        .fontSize(9)
        .fontFamily('HarmonyOS Sans')
        .fontColor(this.th().textTertiary)
        .letterSpacing(1.2)
        .margin({ top: 5 })
    }
    .layoutWeight(1)
    .padding({ top: 14, bottom: 14 })
    .backgroundColor(this.th().surface)
    .borderRadius(16)
    .border({ width: 1, color: this.th().cardBorder })
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
      Text('角度仪')
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
