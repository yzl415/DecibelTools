import { router } from '@kit.ArkUI';
import { getTheme, AppTheme } from '../model/Theme';
import { AngleSensor } from '../model/AngleSensor';

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
    // 节流刷新
    this.uiTimer = setInterval(() => {
      this.pitch = Math.round(this.lastPitch * 10) / 10;
      this.roll = Math.round(this.lastRoll * 10) / 10;
    }, 100);
  }

  aboutToDisappear(): void {
    if (this.uiTimer !== -1) {
      clearInterval(this.uiTimer);
      this.uiTimer = -1;
    }
    this.sensor.stop();
  }

  // 是否接近水平（两轴都接近 0）
  isLevel(): boolean {
    return Math.abs(this.pitch) < 1 && Math.abs(this.roll) < 1;
  }

  build() {
    Column() {
      this.NavBar('角度仪')
      Column() {
        // 气泡水平仪：一个圆盘，气泡随倾角偏移
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(260).height(260).fill(this.th().surface)
            .border({ width: 1, color: this.th().cardBorder })
          Circle().width(170).height(170).fill('#00000000')
            .border({ width: 1, color: this.th().divider })
          Circle().width(80).height(80).fill('#00000000')
            .border({ width: 1, color: this.th().divider })
          // 十字线
          Column().width(260).height(1).backgroundColor(this.th().divider)
          Column().width(1).height(260).backgroundColor(this.th().divider)
          // 气泡：偏移量按倾角比例，限制在圆盘内
          Circle().width(54).height(54)
            .fill(this.isLevel() ? this.th().success : this.th().accent)
            .opacity(0.85)
            .offset({
              x: Math.max(-95, Math.min(95, this.roll * 3)),
              y: Math.max(-95, Math.min(95, -this.pitch * 3))
            })
        }
        .margin({ top: 20 })

        Text(this.isLevel() ? '已水平' : '调整中')
          .fontSize(15)
          .fontColor(this.isLevel() ? this.th().success : this.th().textSecondary)
          .margin({ top: 20 })

        Row() {
          this.AngleBox('前后倾角', this.pitch)
          this.AngleBox('左右倾角', this.roll)
        }
        .width('100%')
        .margin({ top: 28 })

        if (!this.active) {
          Text('未能读取到传感器数据，当前设备可能不支持。')
            .fontSize(13)
            .fontColor(this.th().danger)
            .margin({ top: 16 })
        }

        Text('提示：将手机平放可校准为水平。读数仅供参考。')
          .fontSize(12)
          .fontColor(this.th().textTertiary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 22 })
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 22, right: 22 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.th().bg)
  }

  @Builder
  AngleBox(label: string, value: number) {
    Column() {
      Text(value.toFixed(1) + '°')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.th().textPrimary)
      Text(label)
        .fontSize(13)
        .fontColor(this.th().textSecondary)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .padding({ top: 18, bottom: 18 })
    .backgroundColor(this.th().surface)
    .borderRadius(14)
    .margin({ left: 5, right: 5 })
    .border({ width: this.th().shadowRadius > 0 ? 0 : 1, color: this.th().cardBorder })
  }

  @Builder
  NavBar(title: string) {
    Row() {
      Text('‹ 返回')
        .fontSize(16)
        .fontColor(this.th().accent)
        .onClick(() => router.back())
        .layoutWeight(1)
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.th().textPrimary)
      Blank().layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 14, bottom: 10 })
  }
}
