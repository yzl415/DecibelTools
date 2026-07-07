import { common } from '@kit.AbilityKit';
import { SettingsStore } from '../model/SettingsStore';
import { RecordStore, MeasureRecord } from '../model/RecordStore';
import { getTheme, AppTheme } from '../model/Theme';
import { AppIcon } from '../components/AppIcon';
import { HomeView } from '../components/HomeView';
import { HistoryView } from '../components/HistoryView';
import { SettingsView } from '../components/SettingsView';
import { pushPage } from '../model/NavigationHelper';

@Entry
@Component
struct Index {
  @State loaded: boolean = false;
  @State showPrivacy: boolean = false;
  @State showWelcome: boolean = false;
  @State curTab: number = 0;
  @State records: MeasureRecord[] = [];
  @StorageProp('themeDark') themeDark: boolean = false;
  // 首页实时预览状态（下传给 HomeView）
  @State liveActive: boolean = false;   // 麦克风预览是否在跑
  @State homeDb: number = 0;
  @State homeSpectrum: number[] = [];
  @State homeTilt: number = -1;         // <0 表示无角度数据
  @State homeHeading: number = -1;      // <0 表示无方位数据
  private store: SettingsStore = SettingsStore.getInstance();
  private recordStore: RecordStore = RecordStore.getInstance();
  private pageShown: boolean = false;

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  async aboutToAppear(): Promise<void> {
    const ctx = this.getHostContext();
    if (ctx === null) {
      return;
    }
    await this.store.init(ctx);
    await this.recordStore.init(ctx);
    this.records = this.recordStore.records.slice(0);
    AppStorage.setOrCreate('themeDark', this.store.themeDark);
    this.showPrivacy = !this.store.privacyAgreed;
    this.showWelcome = this.store.privacyAgreed && !this.store.onboarded;
    this.loaded = true;
  }

  aboutToDisappear(): void {
    this.resetHomePreview();
  }

  onPageShow(): void {
    this.pageShown = true;
    // 从分贝仪返回后刷新历史
    this.records = this.recordStore.records.slice(0);
    // 分贝仪"查看历史"按钮通过 AppStorage 请求切到历史 Tab
    const req: number | undefined = AppStorage.get('requestTab');
    if (req !== undefined) {
      this.curTab = req;
      AppStorage.delete('requestTab');
    }
    this.resetHomePreview();
  }

  onPageHide(): void {
    this.pageShown = false;
    this.resetHomePreview();
  }

  resetHomePreview(): void {
    this.liveActive = false;
    this.homeDb = 0;
    this.homeSpectrum = [];
    this.homeTilt = -1;
    this.homeHeading = -1;
  }

  onHistoryCleared(): void {
    this.records = this.recordStore.records.slice(0);
  }

  async agreePrivacy(): Promise<void> {
    await this.store.setPrivacyAgreed();
    this.showPrivacy = false;
    this.showWelcome = !this.store.onboarded;
    this.resetHomePreview();
  }

  async finishWelcome(): Promise<void> {
    await this.store.setOnboarded();
    this.showWelcome = false;
    this.resetHomePreview();
  }

  exitApp(): void {
    const ctx = this.getHostContext();
    if (ctx === null) {
      return;
    }
    try {
      ctx.terminateSelf();
    } catch (e) {
    }
  }

  getHostContext(): common.UIAbilityContext | null {
    const host = this.getUIContext().getHostContext();
    if (host === undefined) {
      return null;
    }
    return host as common.UIAbilityContext;
  }

  build() {
    Stack() {
      Column() {
        Tabs({ barPosition: BarPosition.End, index: this.curTab }) {
          TabContent() {
            HomeView({
              liveActive: this.liveActive,
              homeDb: this.homeDb,
              homeSpectrum: this.homeSpectrum,
              homeTilt: this.homeTilt,
              homeHeading: this.homeHeading
            })
          }
          .tabBar(this.BottomTab('工具', 'grid', 0))

          TabContent() {
            HistoryView({ records: this.records })
          }
          .tabBar(this.BottomTab('历史', 'list', 1))

          TabContent() {
            SettingsView({
              recordCount: this.records.length,
              onClearHistory: () => this.onHistoryCleared()
            })
          }
          .tabBar(this.BottomTab('设置', 'gear', 2))
        }
        .barBackgroundColor(this.th().navBar)
        .scrollable(false)
        .onChange((i: number) => {
          this.curTab = i;
          this.resetHomePreview();
        })
        .layoutWeight(1)
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
  // PH_INDEX

  @Builder
  BottomTab(label: string, icon: string, idx: number) {
    Column() {
      AppIcon({
        name: icon,
        color: this.curTab === idx ? this.th().accent : this.th().textTertiary,
        iconSize: 22,
        cutout: this.th().navBar
      })
      Text(label)
        .fontSize(11)
        .fontWeight(this.curTab === idx ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.curTab === idx ? this.th().accent : this.th().textTertiary)
        .margin({ top: 4 })
    }
    .width('100%')
    .padding({ top: 8, bottom: 6 })
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  WelcomeScreen() {
    Column() {
      Blank().layoutWeight(1)
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(96)
          .height(96)
          .borderRadius(26)
          .linearGradient({ angle: 135, colors: [['#00D68F', 0], ['#00B377', 1]] })
        AppIcon({ name: 'wave', color: '#FFFFFF', iconSize: 52 })
      }
      Text('声活 · 分贝工具箱')
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
        this.Feature('角度仪 / 指南针：测倾角与方位')
        this.Feature('测距尺 / 计时器：日常小工具')
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
        .fontColor(this.th().accentText)
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
        Text('欢迎使用声活 · 分贝工具箱')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.th().textPrimary)
          .margin({ top: 4, bottom: 14 })
        Text() {
          Span('在使用前，请阅读并同意')
          Span('《隐私政策》')
            .fontColor(this.th().accentStrong)
            .onClick(() => pushPage(this.getUIContext(), 'pages/Privacy'))
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
          .fontColor(this.th().accentText)
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
