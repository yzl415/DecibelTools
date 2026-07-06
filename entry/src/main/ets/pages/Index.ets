import { common, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { SettingsStore } from '../model/SettingsStore';
import { RecordStore, MeasureRecord } from '../model/RecordStore';
import { getTheme, AppTheme } from '../model/Theme';
import { DecibelMeter } from '../model/DecibelMeter';
import { AngleSensor } from '../model/AngleSensor';
import { CompassSensor } from '../model/CompassSensor';
import { MOCK_HARDWARE } from '../model/MockConfig';
import { AppIcon } from '../components/AppIcon';
import { HomeView } from '../components/HomeView';
import { HistoryView } from '../components/HistoryView';
import { SettingsView } from '../components/SettingsView';

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
  // 首页实时源（独立实例，仅在工具 Tab 前台运行）
  private liveMeter: DecibelMeter = new DecibelMeter();
  private liveAngle: AngleSensor = new AngleSensor();
  private liveCompass: CompassSensor = new CompassSensor();
  private liveTimer: number = -1;
  private livePreviewing: boolean = false;
  private micRequested: boolean = false;   // 本会话是否已请求过麦克风
  private micDenied: boolean = false;
  private latestDb: number = 0;
  private latestTilt: number = -1;
  private latestHeading: number = -1;
  private pageShown: boolean = false;

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  async aboutToAppear(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    await this.store.init(ctx);
    await this.recordStore.init(ctx);
    this.records = this.recordStore.records.slice(0);
    AppStorage.setOrCreate('themeDark', this.store.themeDark);
    this.showPrivacy = !this.store.privacyAgreed;
    this.showWelcome = this.store.privacyAgreed && !this.store.onboarded;
    this.loaded = true;
    // 传感器回调只更新缓存值，UI 由 liveTimer 统一节流刷新（遵循刷新坑）
    this.liveMeter.setWeighting(this.store.weighting);
    this.liveMeter.setResponse(this.store.response);
    this.liveMeter.setCalibration(this.store.calibration);
    this.liveMeter.onDb = (db: number) => {
      this.latestDb = db;
    };
    this.liveAngle.onAngle = (pitch: number, roll: number) => {
      this.latestTilt = Math.sqrt(pitch * pitch + roll * roll);
    };
    this.liveCompass.onHeading = (h: number) => {
      this.latestHeading = h;
    };
  }

  aboutToDisappear(): void {
    this.stopLive();
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
    this.syncLive();
  }

  onPageHide(): void {
    // 进入详情页 / 切到后台时释放麦克风与传感器，避免与正式测量抢占
    this.pageShown = false;
    this.stopLive();
  }

  // 是否应当运行首页实时预览
  shouldLive(): boolean {
    return this.pageShown && this.curTab === 0 && this.store.privacyAgreed
      && !this.showWelcome && !this.showPrivacy;
  }

  // 根据当前状态启停实时预览
  async syncLive(): Promise<void> {
    if (this.shouldLive()) {
      await this.startLive();
    } else {
      this.stopLive();
    }
  }

  async startLive(): Promise<void> {
    if (this.livePreviewing) {
      return;
    }
    // 角度 / 指南针无需运行时权限，直接启动
    this.liveAngle.start();
    this.liveCompass.start();
    // 麦克风：真机需权限，本会话请求一次；拒绝后不再重试，卡片显 --
    if (!MOCK_HARDWARE && !this.micRequested) {
      this.micRequested = true;
      const ctx = getContext(this) as common.UIAbilityContext;
      const atManager = abilityAccessCtrl.createAtManager();
      try {
        const perms: Permissions[] = ['ohos.permission.MICROPHONE'];
        const res = await atManager.requestPermissionsFromUser(ctx, perms);
        this.micDenied = !(res.authResults.length > 0 && res.authResults[0] === 0);
      } catch (e) {
        this.micDenied = true;
      }
    }
    let micOk: boolean = false;
    if (!this.micDenied) {
      micOk = await this.liveMeter.start();
    }
    this.liveActive = micOk;
    this.livePreviewing = true;
    if (this.liveTimer === -1) {
      this.liveTimer = setInterval(() => {
        this.homeDb = Math.round(this.latestDb);
        this.homeSpectrum = this.liveMeter.getSpectrum();
        this.homeTilt = this.latestTilt;
        this.homeHeading = this.latestHeading;
      }, 200);
    }
  }

  stopLive(): void {
    if (this.liveTimer !== -1) {
      clearInterval(this.liveTimer);
      this.liveTimer = -1;
    }
    if (this.livePreviewing) {
      this.liveMeter.stop();
      this.liveAngle.stop();
      this.liveCompass.stop();
      this.livePreviewing = false;
    }
    // 清空缓存，避免下次进入时短暂显示上次的陈旧读数
    this.latestTilt = -1;
    this.latestHeading = -1;
    this.latestDb = 0;
    this.liveActive = false;
  }

  onHistoryCleared(): void {
    this.records = this.recordStore.records.slice(0);
  }

  async agreePrivacy(): Promise<void> {
    await this.store.setPrivacyAgreed();
    this.showPrivacy = false;
    this.showWelcome = !this.store.onboarded;
    this.syncLive();
  }

  async finishWelcome(): Promise<void> {
    await this.store.setOnboarded();
    this.showWelcome = false;
    this.syncLive();
  }

  exitApp(): void {
    const ctx = getContext(this) as common.UIAbilityContext;
    ctx.terminateSelf();
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
          this.syncLive();
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
