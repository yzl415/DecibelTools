import { getTheme, AppTheme, levelColor, withAlpha , MONO, MONO_B } from '../model/Theme';
import { RecordStore, MeasureRecord } from '../model/RecordStore';
import { tapFeedback } from '../model/Haptics';
import { averageDb, dayBuckets, filterRecordsByRange, peakDb, peakRecord, peakTimeLabel, todayRecords,
  trendSeries, TrendPoint } from '../model/HistoryAnalysis';

// 趋势图 dB 值域（纵轴 30~90，与 90/60/30 标记一致）
const TREND_MIN: number = 30;
const TREND_MAX: number = 90;

/** 历史 · 趋势与记录 */
@Component
export struct HistoryView {
  @StorageProp('themeDark') themeDark: boolean = false;
  @Prop records: MeasureRecord[];
  @State range: number = 1; // 0=今天 1=7天 2=30天
  private store: RecordStore = RecordStore.getInstance();
  // 趋势折线图 Canvas
  private chartSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private chartCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.chartSettings);

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  // 按当前选中区间过滤记录（0=今天 1=7天 2=30天）
  filtered(): MeasureRecord[] {
    return filterRecordsByRange(this.records, this.range, Date.now());
  }

  avgDb(): number {
    return averageDb(this.filtered());
  }

  peakDb(): number {
    return peakDb(this.filtered());
  }

  // 峰值发生的记录（区间内 peak 最大者）
  peakRecord(): MeasureRecord | null {
    return peakRecord(this.filtered());
  }

  // 峰值时间标签（如「周三 下午」）
  peakTimeLabel(): string {
    return peakTimeLabel(this.peakRecord());
  }

  // 区间副标题
  rangeSubtitle(): string {
    if (this.range === 0) {
      return '今天环境噪音趋势';
    }
    if (this.range === 2) {
      return '最近 30 天环境噪音趋势';
    }
    return '最近 7 天环境噪音趋势';
  }

  // 今日按日历日筛选（区别于 filtered() 的滚动 24h），最旧在前
  todayRecords(): MeasureRecord[] {
    return todayRecords(this.records, Date.now());
  }

  // 按天聚合最近 days 天（今天在最右），返回每天均值桶
  dayBuckets(days: number): TrendPoint[] {
    return dayBuckets(this.records, days, Date.now());
  }

  // 当前区间的趋势序列
  trendSeries(): TrendPoint[] {
    return trendSeries(this.records, this.range, Date.now());
  }

  // dB -> Canvas y 坐标（30 底、90 顶，含上下内边距）
  mapY(db: number, h: number): number {
    const pad: number = 4;
    const c: number = Math.max(TREND_MIN, Math.min(TREND_MAX, db));
    const r: number = (c - TREND_MIN) / (TREND_MAX - TREND_MIN);
    return pad + (1 - r) * (h - pad * 2);
  }

  // 绘制趋势折线 / 面积图（分区背景 + 虚线网格 + 面积 + 折线 + 峰值点）
  drawChart(): void {
    const ctx: CanvasRenderingContext2D = this.chartCtx;
    const w: number = ctx.width;
    const h: number = ctx.height;
    ctx.clearRect(0, 0, w, h);
    const series: TrendPoint[] = this.trendSeries();
    const n: number = series.length;

    // 分区背景（较吵 >70 红 / 一般 55~70 黄 / 安静 <55 绿），低透明
    const y70: number = this.mapY(70, h);
    const y55: number = this.mapY(55, h);
    ctx.fillStyle = withAlpha('#EF4444', '10');
    ctx.fillRect(0, 0, w, y70);
    ctx.fillStyle = withAlpha('#EAB308', '10');
    ctx.fillRect(0, y70, w, y55 - y70);
    ctx.fillStyle = withAlpha('#22C55E', '10');
    ctx.fillRect(0, y55, w, h - y55);

    // 虚线网格（分区边界）
    ctx.setLineDash([3, 4]);
    ctx.strokeStyle = this.th().divider;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, y70);
    ctx.lineTo(w, y70);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(0, y55);
    ctx.lineTo(w, y55);
    ctx.stroke();
    ctx.setLineDash([]);

    // 有数据点的坐标（按桶均匀分布 x）
    const xs: number[] = [];
    const ys: number[] = [];
    for (let i = 0; i < n; i++) {
      if (series[i].has) {
        const x: number = n <= 1 ? w / 2 : (i / (n - 1)) * w;
        xs.push(x);
        ys.push(this.mapY(series[i].value, h));
      }
    }
    const m: number = xs.length;
    if (m === 0) {
      return;
    }

    const line: string = this.th().accentStrong;
    if (m === 1) {
      // 单点：只画一个圆点
      ctx.beginPath();
      ctx.fillStyle = line;
      ctx.arc(xs[0], ys[0], 4, 0, Math.PI * 2);
      ctx.fill();
      return;
    }

    // 面积填充（折线下方到底边）
    const grad = ctx.createLinearGradient(0, 0, 0, h);
    grad.addColorStop(0, withAlpha(this.th().accent, '47')); // ≈0.28
    grad.addColorStop(1, withAlpha(this.th().accent, '00'));
    ctx.beginPath();
    ctx.moveTo(xs[0], ys[0]);
    for (let i = 1; i < m; i++) {
      ctx.lineTo(xs[i], ys[i]);
    }
    ctx.lineTo(xs[m - 1], h);
    ctx.lineTo(xs[0], h);
    ctx.closePath();
    ctx.fillStyle = grad;
    ctx.fill();

    // 折线
    ctx.beginPath();
    ctx.moveTo(xs[0], ys[0]);
    for (let i = 1; i < m; i++) {
      ctx.lineTo(xs[i], ys[i]);
    }
    ctx.strokeStyle = line;
    ctx.lineWidth = 2.5;
    ctx.lineJoin = 'round';
    ctx.lineCap = 'round';
    ctx.stroke();

    // 峰值点（值最大处）
    let pk: number = 0;
    for (let i = 1; i < m; i++) {
      if (ys[i] < ys[pk]) {
        pk = i;
      }
    }
    ctx.beginPath();
    ctx.fillStyle = line;
    ctx.arc(xs[pk], ys[pk], 4, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.strokeStyle = this.th().surface;
    ctx.lineWidth = 2.5;
    ctx.arc(xs[pk], ys[pk], 4, 0, Math.PI * 2);
    ctx.stroke();
  }

  // 图表签名：主题 / 区间 / 数据变化时改变，用作 Canvas 的 ForEach key 强制重建以重绘
  chartSignature(): string {
    return `${this.themeDark ? 'd' : 'l'}_${this.range}_${this.filtered().length}_${this.avgDb()}_${this.peakDb()}`;
  }

  fmtTime(ms: number): string {
    const d: Date = new Date(ms);
    const now: Date = new Date();
    const hh: string = d.getHours().toString().padStart(2, '0');
    const mm: string = d.getMinutes().toString().padStart(2, '0');
    const sameDay: boolean = d.getFullYear() === now.getFullYear()
      && d.getMonth() === now.getMonth() && d.getDate() === now.getDate();
    const prefix: string = sameDay ? '今天' : `${d.getMonth() + 1}月${d.getDate()}日`;
    return `${prefix} ${hh}:${mm}`;
  }

  fmtDur(sec: number): string {
    const m: number = Math.floor(sec / 60);
    const s: number = sec % 60;
    return `${m}:${s.toString().padStart(2, '0')}`;
  }

  build() {
    Scroll() {
      Column() {
        Text('测量历史')
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.th().textPrimary)
          .width('100%')
          .margin({ bottom: 4 })
        Text(this.rangeSubtitle())
          .fontSize(12)
          .fontColor(this.th().textSecondary)
          .width('100%')
          .margin({ bottom: 16 })

        // 区间分段
        Row() {
          this.RangeTab('今天', 0)
          this.RangeTab('7 天', 1)
          this.RangeTab('30 天', 2)
        }
        .width('100%')
        .padding(3)
        .backgroundColor(this.th().surface)
        .borderRadius(12)
        .border({ width: 1, color: this.th().cardBorder })
        .margin({ bottom: 16 })

        this.TrendCard()

        this.SectionLabel('最近记录')
        if (this.filtered().length === 0) {
          this.EmptyState()
        } else {
          Column({ space: 9 }) {
            ForEach(this.filtered().slice(0, 20), (r: MeasureRecord) => {
              this.RecordRow(r)
            }, (r: MeasureRecord) => r.id.toString())
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 12, bottom: 24 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }
  // PH_HISTORY

  @Builder
  RangeTab(label: string, idx: number) {
    Text(label)
      .fontSize(12)
      .fontWeight(this.range === idx ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.range === idx ? this.th().accentText : this.th().textTertiary)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .padding({ top: 8, bottom: 8 })
      .backgroundColor(this.range === idx ? this.th().accent : '#00000000')
      .borderRadius(9)
      .onClick(() => this.range = idx)
  }

  @Builder
  SectionLabel(text: string) {
    Text(text)
      .fontSize(10)
      .fontFamily(MONO)
      .fontColor(this.th().textTertiary)
      .letterSpacing(1.4)
      .width('100%')
      .margin({ left: 2, top: 4, bottom: 10 })
  }

  @Builder
  TrendCard() {
    Column() {
      Row() {
        Row() {
          Text(this.avgDb() > 0 ? this.avgDb().toString() : '--')
            .fontSize(24)
            .fontFamily(MONO_B)
            .fontColor(this.th().textPrimary)
          Text(' dB 均值')
            .fontSize(12)
            .fontFamily(MONO)
            .fontColor(this.th().textTertiary)
            .margin({ bottom: 2 })
        }
        .alignItems(VerticalAlign.Bottom)
        .layoutWeight(1)

        Column() {
          Text('峰值 ' + (this.peakDb() > 0 ? this.peakDb().toString() : '--'))
            .fontSize(12)
            .fontFamily(MONO_B)
            .fontColor(this.th().danger)
          Text(this.peakTimeLabel().length > 0 ? this.peakTimeLabel() : (this.filtered().length + ' 条记录'))
            .fontSize(10)
            .fontColor(this.th().textTertiary)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .margin({ bottom: 14 })

      if (this.filtered().length === 0) {
        Text('暂无趋势数据')
          .fontSize(12)
          .fontColor(this.th().textTertiary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 30, bottom: 30 })
      } else {
        Row({ space: 8 }) {
          // y 轴刻度
          Column() {
            Text('90').fontSize(9).fontFamily(MONO).fontColor(this.th().textTertiary)
            Blank().layoutWeight(1)
            Text('60').fontSize(9).fontFamily(MONO).fontColor(this.th().textTertiary)
            Blank().layoutWeight(1)
            Text('30').fontSize(9).fontFamily(MONO).fontColor(this.th().textTertiary)
          }
          .height(130)
          .padding({ top: 2, bottom: 16 })

          Column() {
            // 用签名做 key 的 ForEach 包裹 Canvas：主题/区间/数据变化时重建组件，重新触发 onReady 重绘
            ForEach([this.chartSignature()], (sig: string) => {
              Canvas(this.chartCtx)
                .width('100%')
                .height(130)
                .onReady(() => this.drawChart())
            }, (sig: string) => sig)
            // x 轴标签
            Row() {
              ForEach(this.trendSeries(), (p: TrendPoint, i: number) => {
                Text(p.label)
                  .fontSize(9)
                  .fontFamily(MONO)
                  .fontColor(this.th().textTertiary)
                  .layoutWeight(1)
                  .textAlign(i === 0 ? TextAlign.Start
                    : (i === this.trendSeries().length - 1 ? TextAlign.End : TextAlign.Center))
              }, (p: TrendPoint, i: number) => `${i}_${p.label}`)
            }
            .width('100%')
            .margin({ top: 7 })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.th().surface)
    .borderRadius(20)
    .border({ width: 1, color: this.th().cardBorder })
    .margin({ bottom: 14 })
  }

  @Builder
  RecordRow(r: MeasureRecord) {
    Row() {
      Column()
        .width(4)
        .height(34)
        .borderRadius(2)
        .backgroundColor(levelColor(r.avg))
        .margin({ right: 12 })
      Column() {
        Text(r.name)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.th().textPrimary)
        Text(this.fmtTime(r.time) + ' · 时长 ' + this.fmtDur(r.durationSec))
          .fontSize(11)
          .fontColor(this.th().textSecondary)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column() {
        Text(r.avg.toString())
          .fontSize(18)
          .fontFamily(MONO_B)
          .fontColor(levelColor(r.avg))
        Text('PEAK ' + r.peak)
          .fontSize(9)
          .fontFamily(MONO)
          .fontColor(this.th().textTertiary)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(this.th().surface)
    .borderRadius(14)
    .border({ width: 1, color: this.th().cardBorder })
    .gesture(
      LongPressGesture().onAction(() => {
        tapFeedback();
        this.store.remove(r.id);
        this.records = this.store.records.slice(0);
      })
    )
  }

  @Builder
  EmptyState() {
    Column() {
      Text('还没有测量记录')
        .fontSize(14)
        .fontColor(this.th().textSecondary)
      Text('在分贝仪中开始一次计时测量，结束后即可保存到这里')
        .fontSize(12)
        .fontColor(this.th().textTertiary)
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
  }
}
