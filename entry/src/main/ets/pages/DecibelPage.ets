import { common, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { getTheme, AppTheme } from '../model/Theme';
import { DecibelMeter } from '../model/DecibelMeter';
import { SettingsStore } from '../model/SettingsStore';

/** 噪音参考级别 */
class NoiseRef {
  max: number;
  label: string;
  constructor(max: number, label: string) {
    this.max = max;
    this.label = label;
  }
}

const REFS: NoiseRef[] = [
  new NoiseRef(30, '极安静 · 如深夜卧室'),
  new NoiseRef(45, '安静 · 如图书馆'),
  new NoiseRef(60, '适中 · 如普通交谈'),
  new NoiseRef(75, '较吵 · 如繁忙街道'),
  new NoiseRef(90, '吵闹 · 如地铁车厢'),
  new NoiseRef(200, '嘈杂 · 需注意听力保护'),
];

@Entry
@Component
struct DecibelPage {
  @StorageProp('themeDark') themeDark: boolean = false;
  @State current: number = 0;
  @State peak: number = 0;
  @State avg: number = 0;
  @State measuring: boolean = false;
  @State denied: boolean = false;
  private meter: DecibelMeter = new DecibelMeter();
  private store: SettingsStore = SettingsStore.getInstance();
  private sum: number = 0;
  private count: number = 0;
  private uiTimer: number = -1;
  private latest: number = 0;

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  async aboutToAppear(): Promise<void> {
    this.meter.setCalibration(this.store.calibration);
    this.meter.onDb = (db: number) => {
      this.latest = db;
      this.sum += db;
      this.count++;
      if (db > this.peak) {
        this.peak = db;
      }
    };
  }

  aboutToDisappear(): void {
    this.stop();
  }

  /** 申请麦克风权限并开始 */
  async requestAndStart(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const perms: Permissions[] = ['ohos.permission.MICROPHONE'];
      const res = await atManager.requestPermissionsFromUser(ctx, perms);
      const granted: boolean = res.authResults.length > 0 && res.authResults[0] === 0;
      if (!granted) {
        this.denied = true;
        return;
      }
      this.denied = false;
      await this.start();
    } catch (e) {
      this.denied = true;
    }
  }

  async start(): Promise<void> {
    this.sum = 0;
    this.count = 0;
    this.peak = 0;
    const ok: boolean = await this.meter.start();
    if (!ok) {
      this.denied = true;
      return;
    }
    this.measuring = true;
    // UI 刷新节流：每 200ms 更新一次显示，避免回调过密导致频繁重绘
    this.uiTimer = setInterval(() => {
      this.current = Math.round(this.latest);
      this.avg = this.count > 0 ? Math.round(this.sum / this.count) : 0;
    }, 200);
  }

  async stop(): Promise<void> {
    if (this.uiTimer !== -1) {
      clearInterval(this.uiTimer);
      this.uiTimer = -1;
    }
    if (this.measuring) {
      await this.meter.stop();
      // 记录历史最高
      if (this.peak > this.store.historyMaxDb) {
        await this.store.setHistoryMaxDb(Math.round(this.peak));
      }
    }
    this.measuring = false;
  }

  toggle(): void {
    if (this.measuring) {
      this.stop();
    } else {
      this.requestAndStart();
    }
  }

  refLabel(): string {
    for (const r of REFS) {
      if (this.current <= r.max) {
        return r.label;
      }
    }
    return REFS[REFS.length - 1].label;
  }

  // 根据分贝映射弧形进度颜色：低绿、中黄、高红
  dbColor(): string {
    if (this.current < 50) {
      return this.th().success;
    } else if (this.current < 75) {
      return this.th().warn;
    }
    return this.th().danger;
  }
  // PLACEHOLDER_BUILD

  build() {
    Column() {
      this.NavBar('分贝仪')
      Scroll() {
        Column() {
          // 大数字 + 单位
          Stack({ alignContent: Alignment.Center }) {
            // 进度环底
            Progress({ value: this.current, total: 120, type: ProgressType.Ring })
              .width(240)
              .height(240)
              .color(this.dbColor())
              .backgroundColor(this.th().track)
              .style({ strokeWidth: 14 })
            Column() {
              Text(this.measuring ? this.current.toString() : '--')
                .fontSize(72)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.th().textPrimary)
              Text('dB')
                .fontSize(20)
                .fontColor(this.th().textSecondary)
                .margin({ top: 2 })
              Text(this.measuring ? this.refLabel() : '点击下方开始测量')
                .fontSize(13)
                .fontColor(this.th().textTertiary)
                .margin({ top: 8 })
            }
          }
          .margin({ top: 24 })

          // 峰值 / 平均
          Row() {
            this.StatBox('平均', this.measuring ? this.avg.toString() : '--')
            this.StatBox('峰值', this.measuring ? this.peak.toString() : '--')
            this.StatBox('历史最高', this.store.historyMaxDb > 0 ? this.store.historyMaxDb.toString() : '--')
          }
          .width('100%')
          .margin({ top: 30 })

          // 开始/停止按钮
          Button(this.measuring ? '停止' : '开始测量')
            .width('100%')
            .height(52)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .backgroundColor(this.measuring ? this.th().danger : this.th().accent)
            .borderRadius(16)
            .margin({ top: 32 })
            .onClick(() => this.toggle())

          if (this.denied) {
            Text('未获得麦克风权限，请在系统设置中开启后重试。仅用于本地测量噪音，不录音、不上传。')
              .fontSize(13)
              .fontColor(this.th().danger)
              .margin({ top: 16 })
              .textAlign(TextAlign.Center)
          }

          Text('提示：分贝读数为估算值，受麦克风灵敏度影响，仅供参考。可在设置中校准。')
            .fontSize(12)
            .lineHeight(20)
            .fontColor(this.th().textTertiary)
            .width('100%')
            .margin({ top: 24 })
        }
        .width('100%')
        .padding({ left: 22, right: 22, bottom: 40 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.th().bg)
  }

  @Builder
  StatBox(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.th().textPrimary)
      Text(label)
        .fontSize(12)
        .fontColor(this.th().textSecondary)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .padding({ top: 16, bottom: 16 })
    .backgroundColor(this.th().surface)
    .borderRadius(14)
    .margin({ left: 4, right: 4 })
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
