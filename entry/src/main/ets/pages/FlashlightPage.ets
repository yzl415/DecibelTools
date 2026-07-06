import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { getTheme, AppTheme, TOOL_ORANGE, withAlpha , MONO } from '../model/Theme';
import { TorchController } from '../model/TorchController';
import { tapFeedback } from '../model/Haptics';
import { AppIcon } from '../components/AppIcon';

@Entry
@Component
struct FlashlightPage {
  @StorageProp('themeDark') themeDark: boolean = false;
  @State on: boolean = false;
  @State mode: string = 'steady';   // steady | strobe | sos
  @State freqHz: number = 5;
  @State supported: boolean = true;
  private torch: TorchController = new TorchController();

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  aboutToAppear(): void {
    const ctx = getContext(this) as common.UIAbilityContext;
    this.supported = this.torch.init(ctx);
  }

  aboutToDisappear(): void {
    this.torch.dispose();
  }

  // 中央圆盘点击：切换开关（当前模式生效）
  toggleDisc(): void {
    tapFeedback();
    if (this.on) {
      this.allOff();
    } else {
      this.applyMode(this.mode);
    }
  }

  allOff(): void {
    this.torch.stopStrobe();
    this.torch.setOn(false);
    this.on = false;
  }

  applyMode(m: string): void {
    this.torch.stopStrobe();
    if (m === 'steady') {
      this.torch.setOn(true);
    } else if (m === 'strobe') {
      this.torch.startStrobe(Math.round(1000 / (this.freqHz * 2)));
    } else {
      this.torch.startSos(220);
    }
    this.on = true;
  }

  pickMode(m: string): void {
    this.mode = m;
    if (this.on) {
      this.applyMode(m);
    }
  }

  setFreq(hz: number): void {
    this.freqHz = hz;
    if (this.on && this.mode === 'strobe') {
      this.torch.startStrobe(Math.round(1000 / (hz * 2)));
    }
  }

  statusText(): string {
    if (!this.on) {
      return '已关闭';
    }
    if (this.mode === 'strobe') {
      return '频闪运行中';
    }
    if (this.mode === 'sos') {
      return 'SOS 求救信号';
    }
    return '已开启';
  }

  showInfo(): void {
    AlertDialog.show({
      title: '关于手电筒',
      message: '点击中央圆盘开关手电筒。常亮 / 频闪 / SOS 三种模式可切换：'
        + '频闪模式下滑块调节闪烁频率，SOS 循环发送国际摩斯求救信号。'
        + '受系统限制，本设备的手电筒亮度不可调节。频闪可能引起不适，光敏性癫痫人群慎用。',
      confirm: { value: '知道了', action: () => {} }
    });
  }

  build() {
    Column() {
      this.NavBar()
      Column() {
        // 发光圆盘
        Stack({ alignContent: Alignment.Center }) {
          if (this.on) {
            Column().width(200).height(200).borderRadius(100)
              .radialGradient({
                center: ['50%', '50%'], radius: 100,
                colors: [[withAlpha(TOOL_ORANGE, '38'), 0], ['#00000000', 0.68]]
              })
          }
          Column().width(140).height(140).borderRadius(70)
            .radialGradient(this.on
              ? {
                  center: ['50%', '38%'], radius: 90,
                  colors: [['#FBBF24', 0], ['#F59E0B', 1]]
                }
              : {
                  center: ['50%', '38%'], radius: 90,
                  colors: [[this.th().surface, 0], [this.th().surfaceAlt, 1]]
                })
            .shadow(this.on
              ? { radius: 50, color: withAlpha(TOOL_ORANGE, '99') }
              : { radius: 0, color: '#00000000' })
            .border({ width: this.on ? 0 : 1, color: this.th().cardBorder })
          // 灯泡剪影
          Column()
            .width(38).height(54)
            .borderRadius({ topLeft: 7, topRight: 7, bottomLeft: 9, bottomRight: 9 })
            .backgroundColor(this.on ? withAlpha(this.th().bg, 'E6') : this.th().textTertiary)
            .opacity(0.85)
        }
        .width(200).height(200)
        .margin({ top: 20, bottom: 6 })
        .onClick(() => this.toggleDisc())

        Text(this.statusText())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.on ? TOOL_ORANGE : this.th().textSecondary)
          .margin({ top: 6 })
        Text('点击圆盘开关')
          .fontSize(12)
          .fontColor(this.th().textTertiary)
          .margin({ top: 3, bottom: 22 })

        // 频闪：频率控制；常亮 / SOS：亮度不可调（系统限制，诚实降级）
        Column() {
          Row() {
            Text(this.mode === 'strobe' ? '频闪频率' : '亮度')
              .fontSize(12)
              .fontColor(this.th().textSecondary)
              .layoutWeight(1)
            Text(this.mode === 'strobe' ? this.freqHz + ' 次/秒' : '不可调')
              .fontSize(12)
              .fontFamily(MONO)
              .fontColor(this.mode === 'strobe' ? TOOL_ORANGE : this.th().textTertiary)
          }
          .width('100%')
          .margin({ bottom: 6 })
          Slider({ value: this.mode === 'strobe' ? this.freqHz : 20, min: 1, max: 20, step: 1 })
            .width('100%')
            .blockColor('#FFFFFF')
            .selectedColor(this.mode === 'strobe' ? TOOL_ORANGE : this.th().textTertiary)
            .trackColor(this.th().track)
            .enabled(this.mode === 'strobe')
            .opacity(this.mode === 'strobe' ? 1 : 0.5)
            .onChange((v: number) => this.setFreq(Math.round(v)))
          if (this.mode !== 'strobe') {
            Text('当前设备不支持调节手电筒亮度')
              .fontSize(11)
              .fontColor(this.th().textTertiary)
              .width('100%')
              .margin({ top: 8 })
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.th().surface)
        .borderRadius(16)
        .border({ width: 1, color: this.th().cardBorder })
        .margin({ bottom: 12 })

        // 模式
        Row({ space: 9 }) {
          this.ModeTile('steady', '常亮')
          this.ModeTile('strobe', '频闪')
          this.ModeTile('sos', 'SOS')
        }
        .width('100%')

        if (!this.supported) {
          Text('当前设备不支持手电筒控制。')
            .fontSize(13)
            .fontColor(this.th().danger)
            .margin({ top: 16 })
        }
        Text('提示：频闪可能引起不适，请勿直视，光敏性癫痫人群慎用。')
          .fontSize(11)
          .lineHeight(18)
          .fontColor(this.th().textTertiary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 18 })
        Blank().layoutWeight(1)
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 22, right: 22 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.th().bg)
  }
  // PH_FLASH

  @Builder
  ModeTile(m: string, label: string) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.mode === m ? TOOL_ORANGE : this.th().textSecondary)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .padding({ top: 13, bottom: 13 })
      .backgroundColor(this.mode === m ? this.th().tintOrange : this.th().surface)
      .borderRadius(14)
      .border({ width: 1, color: this.mode === m ? withAlpha(TOOL_ORANGE, '66') : this.th().cardBorder })
      .onClick(() => this.pickMode(m))
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
      Text('手电筒')
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
