import { common, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { getTheme, AppTheme, levelColor, levelDesc, withAlpha, MONO, MONO_B, TOOL_GREEN, TOOL_INDIGO } from '../model/Theme';
import { MOCK_HARDWARE } from '../model/MockConfig';
import { SettingsStore } from '../model/SettingsStore';
import { RecordStore } from '../model/RecordStore';
import { tapFeedback } from '../model/Haptics';
import { AppIcon } from '../components/AppIcon';
import { backPage } from '../model/NavigationHelper';
import { DecibelMeasurementService, DecibelMeasurementSnapshot } from '../model/DecibelMeasurementService';
import { MeasurementSummary } from '../model/MeasurementSession';

@Entry
@Component
struct DecibelPage {
  @StorageProp('themeDark') themeDark: boolean = false;
  @State current: number = 0;
  @State needle: number = -80;     // 指针角度，随 current 同步更新（直接绑 state 才会重绘）
  @State peak: number = 0;
  @State avg: number = 0;
  @State minDb: number = 0;
  @State measuring: boolean = false;   // 记录测量中（累计 MIN/AVG/MAX 并保存）
  @State previewing: boolean = false;  // 实时预览中（麦克风已开，仅显示当前值）
  @State starting: boolean = false;
  @State denied: boolean = false;
  @State elapsed: number = 0;          // 秒
  @State spectrum: number[] = [];
  @State weighting: string = 'A';
  @State response: string = 'FAST';
  private store: SettingsStore = SettingsStore.getInstance();
  private recordStore: RecordStore = RecordStore.getInstance();
  private measurement: DecibelMeasurementService = DecibelMeasurementService.getInstance();
  private count: number = 0;
  private uiTimer: number = -1;
  // 表盘彩色弧用 Canvas 绘制（标准 HTML5 角度：0°=3点钟，顺时针为正），
  // 避免 sweepGradient 角度约定不确定 + end 越界(>360) 被忽略的问题。
  private arcSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private arcCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.arcSettings);

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  // 画表盘彩色弧：标准 HTML5 角度(0°=3点钟,顺时针)。圆心(130,130)，半径110，线宽12，
  // 对应设计稿 inset14(外232)→inset26(内208) 之间的 12px 环。绿起左下135°→红收右下405°，底部90°缺口透明。
  drawGaugeArc(): void {
    this.arcCtx.clearRect(0, 0, 260, 260);
    this.arcSeg('#22C55E', 135, 195);   // 安静 绿
    this.arcSeg('#84CC16', 195, 240);   // 适中 黄绿
    this.arcSeg('#EAB308', 240, 270);   // 一般 黄
    this.arcSeg('#F59E0B', 270, 300);   // 较吵 橙
    this.arcSeg('#EF4444', 300, 405);   // 吵闹 红（收于右下45°）
  }

  // 单个色段；起点回退 0.6° 与上一段重叠，由后画的段盖住接缝，消除抗锯齿缝隙。
  arcSeg(color: string, startDeg: number, endDeg: number): void {
    const d2r: number = Math.PI / 180;
    this.arcCtx.beginPath();
    this.arcCtx.lineWidth = 12;
    this.arcCtx.strokeStyle = color;
    this.arcCtx.arc(130, 130, 110, (startDeg - 0.6) * d2r, endDeg * d2r, false);
    this.arcCtx.stroke();
  }

  aboutToAppear(): void {
    this.weighting = this.store.weighting;
    this.response = this.store.response;
    this.configureMeasurement();
    this.refreshFromMeasurement();
    if (this.measurement.isMeasuring()) {
      this.ensureUiTimer();
    }
  }

  aboutToDisappear(): void {
    this.detachPage();
  }

  // 点击开始后才开启采集，避免未开始测量时显示实时读数。
  async startPreview(): Promise<boolean> {
    if (this.measurement.isMeasuring()) {
      this.refreshFromMeasurement();
      this.ensureUiTimer();
      return true;
    }
    if (this.starting) {
      return false;
    }
    this.starting = true;
    if (!MOCK_HARDWARE) {
      const ctx = this.getHostContext();
      if (ctx === null) {
        this.denied = true;
        this.starting = false;
        return false;
      }
      const atManager = abilityAccessCtrl.createAtManager();
      try {
        const perms: Permissions[] = ['ohos.permission.MICROPHONE'];
        const res = await atManager.requestPermissionsFromUser(ctx, perms);
        const granted: boolean = res.authResults.length > 0 && res.authResults[0] === 0;
        if (!granted) {
          this.denied = true;
          this.starting = false;
          return false;
        }
      } catch (e) {
        this.denied = true;
        this.starting = false;
        return false;
      }
    }
    this.denied = false;
    this.configureMeasurement();
    const ok: boolean = await this.measurement.start(Date.now());
    if (!ok) {
      this.denied = true;
      this.starting = false;
      return false;
    }
    this.previewing = true;
    this.ensureUiTimer();
    this.starting = false;
    return true;
  }

  // 常驻 UI 定时器：预览或测量时都刷新当前值 / 指针 / 频谱
  ensureUiTimer(): void {
    if (this.uiTimer !== -1) {
      return;
    }
    this.uiTimer = setInterval(() => {
      this.refreshFromMeasurement();
    }, 150);
  }

  // 开始记录测量：重置统计并翻到测量态。
  startMeasure(): void {
    this.refreshFromMeasurement();
  }

  // 停止记录测量（可选保存），并关闭采集回到待测状态。
  async stopMeasure(save: boolean): Promise<void> {
    if (!this.measuring) {
      return;
    }
    const summary: MeasurementSummary = await this.measurement.stop(save, this.recordStore, this.store);
    this.avg = summary.avg;
    this.minDb = summary.min;
    this.peak = summary.peak;
    this.elapsed = summary.elapsedSec;
    if (this.uiTimer !== -1) {
      clearInterval(this.uiTimer);
      this.uiTimer = -1;
    }
    this.measuring = false;
    this.previewing = false;
    this.current = 0;
    this.needle = -80;
    this.spectrum = [];
  }

  // 页面离开只解绑 UI 刷新；共享测量需用户手动点“停止测量”才结束。
  detachPage(): void {
    this.starting = false;
    if (this.uiTimer !== -1) {
      clearInterval(this.uiTimer);
      this.uiTimer = -1;
    }
  }

  async toggle(): Promise<void> {
    if (this.starting) {
      return;
    }
    tapFeedback();
    if (this.measuring) {
      await this.stopMeasure(true);
      return;
    }
    const started: boolean = await this.startPreview();
    if (started) {
      this.startMeasure();
    }
  }

  setWeighting(w: string): void {
    this.weighting = w;
    this.configureMeasurement();
    this.store.setWeighting(w);
  }

  setResponse(r: string): void {
    this.response = r;
    this.configureMeasurement();
    this.store.setResponse(r);
  }

  configureMeasurement(): void {
    this.measurement.configure(this.store.calibration, this.weighting, this.response, this.store.overLimitAlert);
  }

  refreshFromMeasurement(): void {
    const snapshot: DecibelMeasurementSnapshot = this.measurement.snapshot(Date.now());
    this.measuring = snapshot.measuring;
    this.previewing = snapshot.measuring;
    this.current = snapshot.current;
    this.count = snapshot.count;
    this.peak = snapshot.peak;
    this.avg = snapshot.avg;
    this.minDb = snapshot.min;
    this.elapsed = snapshot.elapsedSec;
    this.spectrum = snapshot.spectrum;
    this.needle = this.needleAngle();
  }

  // 是否有实时读数（预览或测量中）
  hasReading(): boolean {
    return this.previewing || this.measuring;
  }

  // dB -> 指针角度（30dB≈-80°，120dB≈+70°）
  needleAngle(): number {
    const db: number = this.hasReading() ? this.current : 30;
    const c: number = Math.max(30, Math.min(120, db));
    return -80 + (c - 30) / 90 * 150;
  }

  dispDb(): string {
    return this.hasReading() ? this.current.toString() : '--';
  }

  fmtElapsed(): string {
    const m: number = Math.floor(this.elapsed / 60);
    const s: number = this.elapsed % 60;
    return m.toString().padStart(2, '0') + ':' + s.toString().padStart(2, '0');
  }

  getHostContext(): common.UIAbilityContext | null {
    const host = this.getUIContext().getHostContext();
    if (host === undefined) {
      return null;
    }
    return host as common.UIAbilityContext;
  }

  async leavePage(): Promise<void> {
    this.detachPage();
    backPage(this.getUIContext());
  }
  // PH_DB

  build() {
    Column() {
      this.NavBar()
      Scroll() {
        Column() {
          this.Toggles()
          this.Gauge()
          if (this.hasReading()) {
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
            .margin({ top: 10 })
          }
          if (this.measuring) {
            this.Spectrum()
            this.Stats()
            this.StopBtn()
          } else {
            Text(this.starting ? '正在启动麦克风...' : '点击开始后才会请求麦克风并记录噪音变化')
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
        this.WeightSeg('dB(A)', 'A')
        this.WeightSeg('dB(C)', 'C')
      }
      .padding(2)
      .backgroundColor(this.th().surface)
      .borderRadius(9)
      .border({ width: 1, color: this.th().cardBorder })
      // 时间计权
      Row() {
        this.ResponseSeg('FAST')
        this.ResponseSeg('SLOW')
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
  WeightSeg(label: string, value: string) {
    Button(label)
    .width(72)
    .height(30)
    .fontSize(11)
    .fontFamily(MONO_B)
    .fontColor(this.weighting === value ? this.th().accentText : this.th().textTertiary)
    .backgroundColor(this.weighting === value ? TOOL_GREEN : '#00000000')
    .borderRadius(6)
    .stateEffect(true)
    .onClick(() => this.setWeighting(value))
  }

  @Builder
  ResponseSeg(value: string) {
    Button(value)
    .width(72)
    .height(30)
    .fontSize(11)
    .fontFamily(MONO_B)
    .fontColor(this.response === value ? this.th().accentText : this.th().textTertiary)
    .backgroundColor(this.response === value ? TOOL_INDIGO : '#00000000')
    .borderRadius(6)
    .stateEffect(true)
    .onClick(() => this.setResponse(value))
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
      // 彩色弧底盘：inset14 → 232 圆（设计稿 conic 缺口处露出的暗底）
      Circle().width(232).height(232)
        .fill(this.th().gaugeInner)
      // 彩色刻度弧：Canvas 硬边分段色带。标准 HTML5 角度(0°=3点钟,顺时针)。260 画布、圆心(130,130)、半径110。
      // 绿起左下(135°)，顺时针经左/顶/右，收红于右下(405°)；底部 45°→135°(90°) 透明缺口。
      Canvas(this.arcCtx)
        .width(260).height(260)
        .backgroundColor('#00000000')
        .opacity(this.hasReading() ? 1.0 : 0.45)
        .onReady(() => this.drawGaugeArc())
      // 中心遮罩（凹陷核心 + 下沿暗影）：inset26 → 208
      Circle().width(208).height(208)
        .fill(this.th().gaugeCore)
        .shadow({ radius: 6, color: this.th().isDark ? '#B3000000' : '#1A000000', offsetY: 1 })

      // 4 根主刻度
      this.Tick(-135)
      this.Tick(-45)
      this.Tick(45)
      this.Tick(135)

      // 指针（满尺寸容器旋转，三角尖朝圆心、底边贴弧，带等级辉光）
      Stack({ alignContent: Alignment.Top }) {
        Polygon()
          .points([[0, 0], [14, 0], [7, 15]])
          .width(14).height(15)
          .fill(this.hasReading() ? levelColor(this.current) : '#22C55E')
          .shadow({ radius: 7, color: withAlpha(this.hasReading() ? levelColor(this.current) : '#22C55E', 'B3') })
          .margin({ top: 22 })
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
        Text(this.hasReading() ? this.current.toString() : '--')
          .fontSize(60)
          .fontFamily(MONO_B)
          .fontColor(this.th().textPrimary)
          .letterSpacing(-2.4)
          .lineHeight(50)
          .margin({ top: 4 })
        Text('dB(' + this.weighting + ') · ' + this.response)
          .fontSize(13)
          .fontFamily(MONO)
          .fontColor(this.th().textSecondary)
          .letterSpacing(0.5)
          .margin({ top: 4 })
      }
      .width(208)

      // 刻度数字：与设计稿一致，中心点落在 (66,68)/(194,68)/(66,192)/(194,192)，
      // markAnchor 50% 复刻 translate(-50%,-50%)，半径约89落在指针尖(半径93)以内，永不被压。
      // 放最后渲染，双保险盖在指针之上。
      Text('30').fontSize(11).fontFamily(MONO).fontColor(this.th().textSecondary)
        .position({ x: 66, y: 192 }).markAnchor({ x: '50%', y: '50%' })
      Text('60').fontSize(11).fontFamily(MONO).fontColor(this.th().textSecondary)
        .position({ x: 66, y: 68 }).markAnchor({ x: '50%', y: '50%' })
      Text('90').fontSize(11).fontFamily(MONO).fontColor(this.th().textSecondary)
        .position({ x: 194, y: 68 }).markAnchor({ x: '50%', y: '50%' })
      Text('120').fontSize(11).fontFamily(MONO).fontColor(this.th().textSecondary)
        .position({ x: 194, y: 192 }).markAnchor({ x: '50%', y: '50%' })
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
      Text(this.starting ? '启动中' : '开始测量')
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
      .onClick(() => this.leavePage())
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
      .onClick(() => {
        AppStorage.setOrCreate('requestTab', 1);
        this.leavePage();
      })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 8 })
  }
}
