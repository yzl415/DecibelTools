import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { SettingsStore } from '../model/SettingsStore';
import { getTheme, AppTheme } from '../model/Theme';
import { AppIcon } from '../components/AppIcon';

/** 一个工具的元数据 */
class ToolItem {
  key: string;
  icon: string;
  title: string;
  desc: string;
  route: string;
  constructor(key: string, icon: string, title: string, desc: string, route: string) {
    this.key = key;
    this.icon = icon;
    this.title = title;
    this.desc = desc;
    this.route = route;
  }
}

const TOOLS: ToolItem[] = [
  new ToolItem('decibel', 'wave', '分贝仪', '实时测量环境噪音响度', 'pages/DecibelPage'),
  new ToolItem('angle', 'angle', '角度仪', '测量倾角 / 坡度', 'pages/AnglePage'),
  new ToolItem('flash', 'flash', '手电筒', '照明 / 频闪爆闪', 'pages/FlashlightPage'),
];

@Entry
@Component
struct Index {
  @State loaded: boolean = false;
  @State showPrivacy: boolean = false;
  @State showWelcome: boolean = false;
  @StorageProp('themeDark') themeDark: boolean = false;
  private store: SettingsStore = SettingsStore.getInstance();

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  async aboutToAppear(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    await this.store.init(ctx);
    AppStorage.setOrCreate('themeDark', this.store.themeDark);
    this.showPrivacy = !this.store.privacyAgreed;
    this.showWelcome = this.store.privacyAgreed && !this.store.onboarded;
    this.loaded = true;
  }

  async agreePrivacy(): Promise<void> {
    await this.store.setPrivacyAgreed();
    this.showPrivacy = false;
    this.showWelcome = !this.store.onboarded;
  }

  async finishWelcome(): Promise<void> {
    await this.store.setOnboarded();
    this.showWelcome = false;
  }

  exitApp(): void {
    const ctx = getContext(this) as common.UIAbilityContext;
    ctx.terminateSelf();
  }

  toggleTheme(): void {
    const next: boolean = !this.themeDark;
    AppStorage.setOrCreate('themeDark', next);
    this.store.setThemeDark(next);
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        Scroll() {
          Column() {
            ForEach(TOOLS, (t: ToolItem) => {
              this.ToolCard(t)
            })
            this.PrivacyEntry()
          }
          .width('100%')
          .padding({ left: 18, right: 18, bottom: 30 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.th().bg)

      if (this.showPrivacy) {
        this.PrivacyGate()
      }
      if (this.showWelcome && !this.showPrivacy) {
        this.WelcomeScreen()
      }
    }
    .width('100%')
    .height('100%')
  }
  // PLACEHOLDER_BUILDERS

  @Builder
  Header() {
    Row() {
      Column() {
        Text('声活')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.th().textPrimary)
        Text('分贝 · 实用工具箱')
          .fontSize(13)
          .fontColor(this.th().textSecondary)
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Stack() {
        Circle().width(40).height(40).fill(this.th().surfaceAlt)
        AppIcon({ name: this.themeDark ? 'sun' : 'moon', color: this.th().textSecondary, iconSize: 20, cutout: this.th().surfaceAlt })
      }
      .onClick(() => this.toggleTheme())
    }
    .width('100%')
    .padding({ left: 22, right: 22, top: 18, bottom: 14 })
  }

  @Builder
  ToolCard(t: ToolItem) {
    Row() {
      Stack() {
        Column().width(48).height(48).borderRadius(14).backgroundColor(this.th().accentSoft)
        AppIcon({ name: t.icon, color: this.th().accent, iconSize: 26 })
      }
      .margin({ right: 16 })

      Column() {
        Text(t.title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.th().textPrimary)
        Text(t.desc)
          .fontSize(13)
          .fontColor(this.th().textSecondary)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(22)
        .fontColor(this.th().textTertiary)
    }
    .width('100%')
    .padding(16)
    .margin({ top: 12 })
    .backgroundColor(this.th().surface)
    .borderRadius(18)
    .border({ width: this.th().shadowRadius > 0 ? 0 : 1, color: this.th().cardBorder })
    .onClick(() => router.pushUrl({ url: t.route }))
  }

  @Builder
  PrivacyEntry() {
    Row() {
      Text('隐私政策')
        .fontSize(13)
        .fontColor(this.th().textTertiary)
        .decoration({ type: TextDecorationType.Underline, color: this.th().textTertiary })
    }
    .margin({ top: 26 })
    .onClick(() => router.pushUrl({ url: 'pages/Privacy' }))
  }

  @Builder
  WelcomeScreen() {
    Column() {
      Blank().layoutWeight(1)
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(96)
          .height(96)
          .borderRadius(24)
          .linearGradient({ angle: 135, colors: [['#5B53E8', 0], ['#7C76F0', 1]] })
        AppIcon({ name: 'wave', color: '#FFFFFF', iconSize: 52 })
      }
      Text('声活·分贝工具箱')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.th().textPrimary)
        .margin({ top: 24 })
      Text('一个工具箱，搞定测量小事')
        .fontSize(15)
        .fontColor(this.th().textSecondary)
        .margin({ top: 10 })

      Column({ space: 16 }) {
        this.Feature('分贝仪：实时测量环境噪音')
        this.Feature('角度仪：测倾角、坡度、水平')
        this.Feature('手电筒：照明与频闪爆闪')
        this.Feature('全部本地运行，不联网不上传')
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 44 })

      Blank().layoutWeight(1)
      Button('开始使用')
        .width('100%')
        .height(52)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .backgroundColor(this.th().accent)
        .borderRadius(16)
        .onClick(() => this.finishWelcome())
    }
    .width('100%')
    .height('100%')
    .padding({ left: 36, right: 36, top: 60, bottom: 48 })
    .backgroundColor(this.th().bg)
  }

  @Builder
  Feature(text: string) {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(24).height(24).fill(this.th().accentSoft)
        AppIcon({ name: 'check', color: this.th().accent, iconSize: 13 })
      }
      .margin({ right: 14 })
      Text(text)
        .fontSize(15)
        .fontColor(this.th().textPrimary)
        .layoutWeight(1)
    }
    .width('100%')
  }

  @Builder
  PrivacyGate() {
    Column() {
      Column() {
        Text('欢迎使用声活·分贝工具箱')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.th().textPrimary)
          .margin({ top: 4, bottom: 14 })
        Text() {
          Span('在使用前，请阅读并同意')
          Span('《隐私政策》')
            .fontColor(this.th().accent)
            .onClick(() => router.pushUrl({ url: 'pages/Privacy' }))
          Span('。我们高度重视你的隐私：分贝仪麦克风数据仅在本机实时计算、不录音不上传，全部功能均在本地完成，无广告、无第三方共享。')
        }
        .fontSize(14)
        .lineHeight(23)
        .textAlign(TextAlign.Start)
        .width('100%')

        Button('同意并开始使用')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor(this.th().accent)
          .borderRadius(14)
          .margin({ top: 22 })
          .onClick(() => this.agreePrivacy())
        Text('不同意并退出')
          .fontSize(14)
          .fontColor(this.th().textTertiary)
          .margin({ top: 14, bottom: 4 })
          .onClick(() => this.exitApp())
      }
      .width('86%')
      .padding(24)
      .backgroundColor(this.th().surface)
      .borderRadius(22)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#99000000')
    .justifyContent(FlexAlign.Center)
  }
}
