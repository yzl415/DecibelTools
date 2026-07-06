import { router } from '@kit.ArkUI';
import { getTheme, AppTheme , MONO, MONO_B } from '../model/Theme';
import { CompassSensor, ACC_HIGH, ACC_MEDIUM, ACC_LOW } from '../model/CompassSensor';
import { AppIcon } from '../components/AppIcon';

@Entry
@Component
struct CompassPage {
  @StorageProp('themeDark') themeDark: boolean = false;
  @State heading: number = 0;
  @State active: boolean = false;
  @State accuracy: number = ACC_MEDIUM;
  private sensor: CompassSensor = new CompassSensor();
  private lastHeading: number = 0;
  private lastAccuracy: number = ACC_MEDIUM;
  private uiTimer: number = -1;

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  aboutToAppear(): void {
    this.sensor.onHeading = (h: number, acc: number) => {
      this.lastHeading = h;
      this.lastAccuracy = acc;
    };
    this.active = this.sensor.start();
    this.uiTimer = setInterval(() => {
      this.heading = Math.round(this.lastHeading);
      this.accuracy = this.lastAccuracy;
    }, 100);
  }

  aboutToDisappear(): void {
    if (this.uiTimer !== -1) {
      clearInterval(this.uiTimer);
      this.uiTimer = -1;
    }
    this.sensor.stop();
  }

  // 精度等级 -> 左侧校准状态文案
  statusText(): string {
    if (!this.active) {
      return '未读取到磁力计数据';
    }
    if (this.accuracy >= ACC_MEDIUM) {
      return '磁偏角已校正';
    }
    if (this.accuracy === ACC_LOW) {
      return '建议校准 · 远离磁性物体';
    }
    return '请校准 · 做 8 字晃动';
  }

  // 精度等级 -> 右侧精度文案
  accuracyText(): string {
    if (!this.active) {
      return '--';
    }
    if (this.accuracy >= ACC_HIGH) {
      return '精度 ±2°';
    }
    if (this.accuracy === ACC_MEDIUM) {
      return '精度 ±5°';
    }
    if (this.accuracy === ACC_LOW) {
      return '精度较低';
    }
    return '精度不可靠';
  }

  showInfo(): void {
    AlertDialog.show({
      title: '关于指南针',
      message: '基于设备磁力计计算方位角，0° 为正北。附近的金属、磁铁、电子设备会干扰读数；'
        + '若提示精度较低，请远离磁性物体并将手机沿"8"字方向晃动几次以重新校准。读数仅供参考。',
      confirm: { value: '知道了', action: () => {} }
    });
  }

  build() {
    Column() {
      this.NavBar()
      Column() {
        // 大读数
        Row() {
          Text(this.heading.toString() + '°')
            .fontSize(46)
            .fontFamily(MONO_B)
            .fontColor(this.th().textPrimary)
          Text(' ' + CompassSensor.dirAbbr(this.heading))
            .fontSize(20)
            .fontFamily(MONO_B)
            .fontColor(this.th().accentStrong)
            .margin({ bottom: 6 })
        }
        .alignItems(VerticalAlign.Bottom)
        .margin({ top: 4, bottom: 8 })

        // 罗盘盘面
        Stack({ alignContent: Alignment.Center }) {
          Column().width(252).height(252).borderRadius(126)
            .radialGradient({
              center: ['50%', '35%'],
              radius: 174,
              colors: [[this.th().gaugeOuter, 0.0], [this.th().gaugeEdge, 1.0]]
            })
            .border({ width: 1, color: this.th().cardBorder })
            .shadow({
              radius: this.th().isDark ? 16 : 12,
              color: this.th().isDark ? '#80000000' : '#1A000000',
              offsetY: 6
            })
          // 顶部固定指示三角
          Polygon().points([[6, 0], [12, 11], [0, 11]]).width(12).height(11)
            .fill(this.th().danger).offset({ y: -120 })

          // 旋转盘（反向于 heading）
          Stack({ alignContent: Alignment.Center }) {
            // 方位字母
            this.DirLabel('N', this.th().danger, 0)
            this.DirLabel('E', this.th().textSecondary, 90)
            this.DirLabel('S', this.th().textSecondary, 180)
            this.DirLabel('W', this.th().textSecondary, 270)
            // 指针（红北灰南）
            Column() {
              Column().width(7).height(44)
                .backgroundColor(this.th().danger)
                .borderRadius({ topLeft: 3, topRight: 3 })
              Column().width(7).height(44)
                .backgroundColor(this.th().isDark ? '#3A4452' : '#C3C8D0')
                .borderRadius({ bottomLeft: 3, bottomRight: 3 })
            }
          }
          .width(212).height(212)
          .rotate({ angle: -this.heading })

          // 中心轴
          Circle().width(14).height(14).fill(this.th().textPrimary)
            .border({ width: 3, color: this.th().bg })
        }
        .width(252).height(252)
        .margin({ top: 8 })

        Row() {
          Text(this.statusText())
            .fontSize(13)
            .fontColor(this.active ? this.th().textSecondary : this.th().danger)
            .layoutWeight(1)
          Text(this.accuracyText())
            .fontSize(12)
            .fontFamily(MONO)
            .fontColor(this.th().accentStrong)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 14 })
        .backgroundColor(this.th().surface)
        .borderRadius(16)
        .border({ width: 1, color: this.th().cardBorder })
        .margin({ top: 20 })

        Text('提示：远离磁性物体、做 8 字晃动可提升精度。读数仅供参考。')
          .fontSize(11)
          .fontColor(this.th().textTertiary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 16 })
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 22, right: 22 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.th().bg)
  }
  // PH_COMPASS

  // 方位字母固定在盘内边缘（angle 度，0=上）
  @Builder
  DirLabel(label: string, color: string, angle: number) {
    Stack({ alignContent: Alignment.Top }) {
      Text(label)
        .fontSize(label === 'N' ? 17 : 15)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .margin({ top: 6 })
    }
    .width(212).height(212)
    .rotate({ angle: angle })
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
      Text('指南针')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.th().textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Stack() {
        Column().width(36).height(36).borderRadius(11).backgroundColor(this.th().surfaceAlt)
          .border({ width: this.th().isDark ? 1 : 0, color: this.th().cardBorder })
        AppIcon({ name: 'info', color: this.th().textSecondary, iconSize: 16 })
      }
      .onClick(() => this.showInfo())
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 8 })
  }
}
