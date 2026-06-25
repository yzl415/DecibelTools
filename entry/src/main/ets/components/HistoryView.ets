import { getTheme, AppTheme, levelColor } from '../model/Theme';
import { RecordStore, MeasureRecord } from '../model/RecordStore';

/** 历史 · 趋势与记录 */
@Component
export struct HistoryView {
  @StorageProp('themeDark') themeDark: boolean = false;
  @Prop records: MeasureRecord[];
  @State range: number = 1; // 0=今天 1=7天 2=30天
  private store: RecordStore = RecordStore.getInstance();

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  avgDb(): number {
    if (this.records.length === 0) {
      return 0;
    }
    let s: number = 0;
    for (const r of this.records) {
      s += r.avg;
    }
    return Math.round(s / this.records.length);
  }

  peakDb(): number {
    let p: number = 0;
    for (const r of this.records) {
      if (r.peak > p) {
        p = r.peak;
      }
    }
    return p;
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
        Text('环境噪音记录与趋势')
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
        if (this.records.length === 0) {
          this.EmptyState()
        } else {
          Column({ space: 9 }) {
            ForEach(this.records.slice(0, 20), (r: MeasureRecord) => {
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
      .fontFamily('HarmonyOS Sans')
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
            .fontFamily('HarmonyOS Sans')
            .fontWeight(FontWeight.Bold)
            .fontColor(this.th().textPrimary)
          Text(' dB 均值')
            .fontSize(12)
            .fontFamily('HarmonyOS Sans')
            .fontColor(this.th().textTertiary)
            .margin({ bottom: 2 })
        }
        .alignItems(VerticalAlign.Bottom)
        .layoutWeight(1)

        Column() {
          Text('峰值 ' + (this.peakDb() > 0 ? this.peakDb().toString() : '--'))
            .fontSize(12)
            .fontFamily('HarmonyOS Sans')
            .fontWeight(FontWeight.Bold)
            .fontColor(this.th().danger)
          Text(this.records.length + ' 条记录')
            .fontSize(10)
            .fontColor(this.th().textTertiary)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .margin({ bottom: 14 })

      // 柱状趋势（最近 7 条均值）
      Row() {
        if (this.records.length === 0) {
          Text('暂无趋势数据')
            .fontSize(12)
            .fontColor(this.th().textTertiary)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 30, bottom: 30 })
        } else {
          Row({ space: 6 }) {
            ForEach(this.trendBars(), (db: number) => {
              Column()
                .layoutWeight(1)
                .height(this.barH(db))
                .borderRadius(3)
                .backgroundColor(levelColor(db))
            })
          }
          .width('100%')
          .height(100)
          .alignItems(VerticalAlign.Bottom)
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.th().surface)
    .borderRadius(20)
    .border({ width: 1, color: this.th().cardBorder })
    .margin({ bottom: 14 })
  }

  // 取最近若干条均值（倒序变正序）做柱
  trendBars(): number[] {
    const n: number = Math.min(7, this.records.length);
    const arr: number[] = [];
    for (let i = n - 1; i >= 0; i--) {
      arr.push(this.records[i].avg);
    }
    return arr;
  }

  barH(db: number): number {
    // 30~100 dB -> 20~100 px
    let n: number = (db - 30) / 70;
    if (n < 0.1) {
      n = 0.1;
    } else if (n > 1) {
      n = 1;
    }
    return 20 + n * 80;
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
          .fontFamily('HarmonyOS Sans')
          .fontWeight(FontWeight.Bold)
          .fontColor(levelColor(r.avg))
        Text('PEAK ' + r.peak)
          .fontSize(9)
          .fontFamily('HarmonyOS Sans')
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
