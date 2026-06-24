import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { getTheme, AppTheme } from '../model/Theme';
import { TorchController } from '../model/TorchController';

@Entry
@Component
struct FlashlightPage {
  @StorageProp('themeDark') themeDark: boolean = false;
  @State on: boolean = false;
  @State strobe: boolean = false;
  @State freqHz: number = 5;        // 频闪频率
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

  toggleLight(): void {
    if (this.strobe) {
      return;
    }
    const next: boolean = !this.on;
    this.torch.setOn(next);
    this.on = next;
  }

  toggleStrobe(): void {
    if (this.strobe) {
      this.torch.stopStrobe();
      this.torch.setOn(false);
      this.strobe = false;
      this.on = false;
    } else {
      const interval: number = Math.round(1000 / (this.freqHz * 2)); // 半周期
      this.torch.startStrobe(interval);
      this.strobe = true;
      this.on = true;
    }
  }

  setFreq(hz: number): void {
    this.freqHz = hz;
    if (this.strobe) {
      const interval: number = Math.round(1000 / (hz * 2));
      this.torch.startStrobe(interval);
    }
  }

  build() {
    Column() {
      this.NavBar('手电筒')
      Column() {
        // 大圆形开关
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(180).height(180)
            .fill(this.on ? this.th().accent : this.th().surface)
            .border({ width: this.th().shadowRadius > 0 ? 0 : 1, color: this.th().cardBorder })
          Text(this.on ? '已开启' : '已关闭')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.on ? '#FFFFFF' : this.th().textSecondary)
        }
        .margin({ top: 40 })
        .onClick(() => this.toggleLight())

        Text(this.strobe ? '频闪模式运行中，点击下方停止' : '点击圆形按钮开关手电筒')
          .fontSize(14)
          .fontColor(this.th().textTertiary)
          .margin({ top: 24 })

        // 频闪区
        Column() {
          Text('频闪 / 爆闪')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.th().textPrimary)
            .width('100%')
          Text('频率：' + this.freqHz + ' 次/秒')
            .fontSize(13)
            .fontColor(this.th().textSecondary)
            .width('100%')
            .margin({ top: 8 })
          Slider({ value: this.freqHz, min: 1, max: 20, step: 1 })
            .width('100%')
            .blockColor(this.th().accent)
            .selectedColor(this.th().accent)
            .trackColor(this.th().track)
            .margin({ top: 4 })
            .onChange((value: number) => this.setFreq(Math.round(value)))
          Button(this.strobe ? '停止频闪' : '开始频闪')
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(this.strobe ? this.th().danger : this.th().accent)
            .borderRadius(14)
            .margin({ top: 16 })
            .onClick(() => this.toggleStrobe())
        }
        .width('100%')
        .padding(18)
        .margin({ top: 40 })
        .backgroundColor(this.th().surface)
        .borderRadius(18)
        .border({ width: this.th().shadowRadius > 0 ? 0 : 1, color: this.th().cardBorder })

        if (!this.supported) {
          Text('当前设备不支持手电筒控制。')
            .fontSize(13)
            .fontColor(this.th().danger)
            .margin({ top: 16 })
        }

        Text('提示：频闪可能引起不适，请勿直视，光敏性癫痫人群慎用。')
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
