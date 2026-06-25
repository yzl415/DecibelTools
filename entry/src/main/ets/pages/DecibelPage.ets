import { common, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { getTheme, AppTheme, levelColor, levelDesc, withAlpha, MONO, MONO_B, TOOL_GREEN, TOOL_INDIGO } from '../model/Theme';
import { DecibelMeter } from '../model/DecibelMeter';
import { SettingsStore } from '../model/SettingsStore';
import { RecordStore } from '../model/RecordStore';
import { AppIcon } from '../components/AppIcon';

@Entry
@Component
struct DecibelPage {
  @StorageProp('themeDark') themeDark: boolean = false;
  @State current: number = 0;
  @State needle: number = -80;     // 指针角度，随 current 同步更新（直接绑 state 才会重绘）
  @State peak: number = 0;
  @State avg: number = 0;
  @State minDb: number = 0;
  @State measuring: boolean = false;
  @State denied: boolean = false;
  @State elapsed: number = 0;          // 秒
  @State spectrum: number[] = [];
  @State weighting: string = 'A';
  @State response: string = 'FAST';
  private meter: DecibelMeter = new DecibelMeter();
  private store: SettingsStore = SettingsStore.getInstance();
  private recordStore: RecordStore = RecordStore.getInstance();
  private sum: number = 0;
  private count: number = 0;
  private uiTimer: number = -1;
  private latest: number = 0;
  private startTs: number = 0;

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  aboutToAppear(): void {
    this.weighting = this.store.weighting;
    this.response = this.store.response;
    this.meter.setCalibration(this.store.calibration);
    this.meter.setWeighting(this.weighting);
    this.meter.setResponse(this.response);
    this.meter.onDb = (db: number) => {
      this.latest = db;
      this.sum += db;
      this.count++;
      if (db > this.peak) {
        this.peak = db;
      }
      if (this.minDb === 0 || db < this.minDb) {
        this.minDb = db;
      }
    };
  }

  aboutToDisappear(): void {
    this.stop(false);
  }

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
    this.minDb = 0;
    this.elapsed = 0;
    this.startTs = Date.now();
    const ok: boolean = await this.meter.start();
    if (!ok) {
      this.denied = true;
      return;
    }
    this.measuring = true;
    this.uiTimer = setInterval(() => {
      this.current = Math.round(this.latest);
      this.needle = this.needleAngle();
      this.avg = this.count > 0 ? Math.round(this.sum / this.count) : 0;
      this.elapsed = Math.floor((Date.now() - this.startTs) / 1000);
      this.spectrum = this.meter.getSpectrum();
    }, 150);
  }

  async stop(save: boolean): Promise<void> {
    if (this.uiTimer !== -1) {
      clearInterval(this.uiTimer);
      this.uiTimer = -1;
    }
    if (this.measuring) {
      await this.meter.stop();
      if (this.peak > this.store.historyMaxDb) {
        await this.store.setHistoryMaxDb(Math.round(this.peak));
      }
      if (save && this.count > 0 && this.elapsed >= 1) {
        await this.recordStore.add('测量记录', this.elapsed,
          Math.round(this.minDb), this.avg, Math.round(this.peak));
      }
    }
    this.measuring = false;
    this.needle = -80;   // 指针归位到起点（30dB）
  }

  toggle(): void {
    if (this.measuring) {
      this.stop(true);
    } else {
      this.requestAndStart();
    }
  }

  setWeighting(w: string): void {
    this.weighting = w;
    this.meter.setWeighting(w);
    this.store.setWeighting(w);
  }

  setResponse(r: string): void {
    this.response = r;
    this.meter.setResponse(r);
    this.store.setResponse(r);
  }

  // dB -> 指针角度（30dB≈-80°，120dB≈+70°）
  needleAngle(): number {
    const db: number = this.measuring ? this.current : 30;
    const c: number = Math.max(30, Math.min(120, db));
    return -80 + (c - 30) / 90 * 150;
  }

  dispDb(): string {
    return this.measuring ? this.current.toString() : '--';
  }

  fmtElapsed(): string {
    const m: number = Math.floor(this.elapsed / 60);
    const s: number = this.elapsed % 60;
    return m.toString().padStart(2, '0') + ':' + s.toString().padStart(2, '0');
  }
  // PH_DB

  build() {
    Column() {
      this.NavBar()
      Scroll() {
        Column() {
          this.Toggles()
          this.Gauge()
          if (this.measuring) {
            this.Spectrum()
            this.Stats()
            this.StopBtn()
          } else {
            Text('点击开始，记录这段时间的噪音变化')
              .fontSize(12)
              .fontColor(this.th().textSecondary)
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ top: 16, bottom: 12 })
            this.StartBtn()
          }
          if (this.denied) {
            Text('未获得麦克风权限，请在系统设置中开启后重试。仅用于本地测量噪音，不录音、不上传。')
              .fontSize(13)
              .fontColor(this.th().danger)
              .textAlign(TextAlign.Center)
              .margin({ top: 16 })
          }
          Text('提示：分贝读数为估算值，受麦克风灵敏度影响，仅供参考。可在设置中校准。')
            .fontSize(11)
            .lineHeight(18)
            .fontColor(this.th().textTertiary)
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 18 })
        }
        .width('100%')
        .padding({ left: 22, right: 22, bottom: 30 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.th().bg)
  }

  @Builder
  Toggles() {
    Row({ space: 8 }) {
      // 计权
      Row() {
        this.Seg('dB(A)', this.weighting === 'A', TOOL_GREEN, () => this.setWeighting('A'))
        this.Seg('dB(C)', this.weighting === 'C', TOOL_GREEN, () => this.setWeighting('C'))
      }
      .padding(2)
      .backgroundColor(this.th().surface)
      .borderRadius(9)
      .border({ width: 1, color: this.th().cardBorder })
      // 时间计权
      Row() {
        this.Seg('FAST', this.response === 'FAST', TOOL_INDIGO, () => this.setResponse('FAST'))
        this.Seg('SLOW', this.response === 'SLOW', TOOL_INDIGO, () => this.setResponse('SLOW'))
      }
      .padding(2)
      .backgroundColor(this.th().surface)
      .borderRadius(9)
      .border({ width: 1, color: this.th().cardBorder })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .margin({ top: 4, bottom: 10 })
  }

  @Builder
  Seg(label: string, active: boolean, activeColor: string, cb: () => void) {
    Text(label)
      .fontSize(11)
      .fontFamily(MONO_B)
      .fontColor(active ? this.th().accentText : this.th().textTertiary)
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .backgroundColor(active ? activeColor : '#00000000')
      .borderRadius(6)
      .onClick(cb)
  }

  // 单根主刻度短线（满尺寸容器旋转，短线在顶部）
  @Builder
  Tick(angle: number) {
    Stack({ alignContent: Alignment.Top }) {
      Column()
        .width(3).height(11).borderRadius(1)
        .backgroundColor(this.th().tick)
        .margin({ top: 8 })
    }
    .width(260).height(260)
    .rotate({ angle: angle })
  }

  @Builder
  Gauge() {
    Stack({ alignContent: Alignment.Center }) {
      // 表盘外圈：径向渐变制造凸起金属圈 + 外投影
      Column()
        .width(260).height(260).borderRadius(130)
        .radialGradient({
          center: ['50%', '35%'],
          radius: 180,
          colors: [[this.th().gaugeOuter, 0.0], [this.th().gaugeEdge, 1.0]]
        })
        .shadow({
          radius: this.th().isDark ? 18 : 14,
          color: this.th().isDark ? '#80000000' : '#22000000',
          offsetY: 6
        })
      // 顶部内高光（弱白渐变，模拟弧面反光）
      Column()
        .width(260).height(260).borderRadius(130)
        .linearGradient({
          angle: 180,
          colors: [
            [withAlpha(this.th().gaugeHighlight, this.th().isDark ? '14' : '2E'), 0.0],
            ['#00000000', 0.45]
          ]
        })
      // 彩色弧（sweepGradient），inset 18
      Circle().width(224).height(224)
        .fill(this.th().gaugeInner)
      Stack() {}
        .width(224).height(224)
        .borderRadius(112)
        .sweepGradient({
          center: ['50%', '50%'],
          start: 135,
          end: 495,
          colors: [
            ['#22C55E', 0.0], ['#84CC16', 0.17], ['#EAB308', 0.29],
            ['#F59E0B', 0.37], ['#EF4444', 0.46], [this.th().gaugeInner, 0.75],
            [this.th().gaugeInner, 1.0]
          ]
        })
        .opacity(this.measuring ? 0.95 : 0.5)
      // 中心遮罩（凹陷核心 + 下沿暗影）
      Circle().width(188).height(188)
        .fill(this.th().gaugeCore)
        .shadow({ radius: 6, color: this.th().isDark ? '#B3000000' : '#1A000000', offsetY: 1 })

      // 4 根主刻度
      this.Tick(-135)
      this.Tick(-45)
      this.Tick(45)
      this.Tick(135)

      // 刻度数字（等宽 mono）
      Text('30').fontSize(11).fontFamily(MONO).fontColor(this.th().textSecondary)
        .position({ x: 52, y: 178 })
      Text('60').fontSize(11).fontFamily(MONO).fontColor(this.th().textSecondary)
        .position({ x: 52, y: 64 })
      Text('90').fontSize(11).fontFamily(MONO).fontColor(this.th().textSecondary)
        .position({ x: 190, y: 64 })
      Text('120').fontSize(11).fontFamily(MONO).fontColor(this.th().textSecondary)
        .position({ x: 186, y: 178 })

      // 指针（满尺寸容器旋转，三角在顶部，带等级辉光）
      Stack({ alignContent: Alignment.Top }) {
        Polygon()
          .points([[7, 0], [14, 16], [0, 16]])
          .width(14).height(16)
          .fill(levelColor(this.measuring ? this.current : 35))
          .shadow({ radius: 8, color: withAlpha(levelColor(this.measuring ? this.current : 35), 'B3') })
          .margin({ top: 24 })
      }
      .width(260).height(260)
      .rotate({ angle: this.needle })

      // 中央读数
      Column() {
        Text('SOUND LEVEL')
          .fontSize(10)
          .fontFamily(MONO)
          .fontColor(this.th().textTertiary)
          .letterSpacing(2.2)
        Text(this.measuring ? this.current.toString() : '--')
          .fontSize(68)
          .fontFamily(MONO_B)
          .fontColor(this.th().textPrimary)
          .letterSpacing(-2.7)
          .lineHeight(56)
          .margin({ top: 6 })
        Text('dB(' + this.weighting + ') · ' + this.response)
          .fontSize(12)
          .fontFamily(MONO)
          .fontColor(this.th().textSecondary)
          .letterSpacing(0.5)
          .margin({ top: 4 })
        if (this.measuring) {
          Row() {
            Circle().width(6).height(6).fill(levelColor(this.current))
              .shadow({ radius: 6, color: withAlpha(levelColor(this.current), 'CC') })
            Text(levelDesc(this.current))
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(levelColor(this.current))
              .margin({ left: 6 })
          }
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .backgroundColor(withAlpha(levelColor(this.current), '22'))
          .borderRadius(20)
          .margin({ top: 11 })
        }
      }
      .width(188)
    }
    .width(260)
    .height(260)
    .margin({ top: 4 })
  }

  @Builder
  Spectrum() {
    // 细窄定宽柱、居中成簇，贴合设计稿声级计样式（非铺满拉伸）
    Row({ space: 4 }) {
      ForEach(this.spectrum, (h: number) => {
        Column()
          .width(5)
          .height(Math.max(3, 42 * h))
          .borderRadius(2.5)
          .backgroundColor(levelColor(30 + h * 80))
      })
    }
    .width('100%')
    .height(42)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Bottom)
    .margin({ top: 16, bottom: 18 })
  }

  @Builder
  Stats() {
    Row() {
      this.StatCell('MIN', Math.round(this.minDb).toString(), this.th().success)
      Column().width(1).height(36).backgroundColor(this.th().divider)
      this.StatCell('AVG · Leq', this.avg.toString(), this.th().textPrimary)
      Column().width(1).height(36).backgroundColor(this.th().divider)
      this.StatCell('MAX · 峰值', Math.round(this.peak).toString(), this.th().danger)
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
    .backgroundColor(this.th().surface)
    .borderRadius(16)
    .border({ width: 1, color: this.th().cardBorder })
    .margin({ bottom: 14 })
  }

  @Builder
  StatCell(label: string, value: string, color: string) {
    Column() {
      Text(value)
        .fontSize(21)
        .fontFamily(MONO_B)
        .fontColor(color)
      Text(label)
        .fontSize(9)
        .fontFamily(MONO)
        .fontColor(this.th().textTertiary)
        .letterSpacing(1.2)
        .margin({ top: 5 })
    }
    .layoutWeight(1)
    .padding({ top: 13, bottom: 13 })
  }

  @Builder
  StartBtn() {
    Row() {
      Circle().width(13).height(13).fill(this.th().accent)
        .shadow({ radius: 10, color: withAlpha(this.th().accent, 'E6') })
      Text('开始测量')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.th().accentStrong)
        .margin({ left: 10 })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .padding({ top: 17, bottom: 17 })
    .backgroundColor(this.th().accentSoft)
    .borderRadius(18)
    .border({ width: 1, color: withAlpha(this.th().accent, '40') })
    .shadow({ radius: 22, color: withAlpha(this.th().accent, '29'), offsetY: 8 })
    .onClick(() => this.toggle())
  }

  @Builder
  StopBtn() {
    Row() {
      Column().width(13).height(13).borderRadius(3).backgroundColor(this.th().danger)
      Text('停止测量')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.th().danger)
        .margin({ left: 9 })
      Text(this.fmtElapsed())
        .fontSize(13)
        .fontFamily(MONO)
        .fontColor(this.th().isDark ? '#8A5559' : '#C08185')
        .margin({ left: 10 })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .backgroundColor(withAlpha(this.th().danger, '1A'))
    .borderRadius(16)
    .border({ width: 1, color: withAlpha(this.th().danger, '40') })
    .onClick(() => this.toggle())
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
      Text('分贝仪')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.th().textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Stack() {
        Column().width(36).height(36).borderRadius(11).backgroundColor(this.th().surfaceAlt)
          .border({ width: this.th().isDark ? 1 : 0, color: this.th().cardBorder })
        AppIcon({ name: 'list', color: this.th().textSecondary, iconSize: 16 })
      }
      .onClick(() => router.back())
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 8 })
  }
}
