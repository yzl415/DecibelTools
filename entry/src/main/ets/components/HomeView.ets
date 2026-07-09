import { getTheme, AppTheme, levelColor, levelLabel, TOOL_GREEN, TOOL_INDIGO, TOOL_PURPLE, TOOL_ORANGE , MONO, MONO_B, withAlpha } from '../model/Theme';
import { AppIcon } from './AppIcon';
import { pushPage } from '../model/NavigationHelper';
import { angleSummary, compassSummary, hasLiveDb, homeDbSummary, homeNoiseTitle } from '../model/HomePreviewState';
import { decibelFromSpectrumHeight, normalizeDecibelDisplayDb } from '../model/DecibelDisplayRange';

/** 仪表项元数据 */
class Instrument {
  key: string = '';
  icon: string = '';
  tint: string = '';
  accent: string = '';
  title: string = '';
  desc: string = '';
  route: string = '';
  value: string = '';
  constructor(key: string, icon: string, tint: string, accent: string,
    title: string, desc: string, route: string, value: string) {
    this.key = key;
    this.icon = icon;
    this.tint = tint;
    this.accent = accent;
    this.title = title;
    this.desc = desc;
    this.route = route;
    this.value = value;
  }
}

/** 首页 · 工具台 */
@Component
export struct HomeView {
  @StorageProp('themeDark') themeDark: boolean = false;
  // 由 Index 下传的实时预览状态
  @Prop liveActive: boolean;
  @Prop homeDb: number;
  @Prop homeSpectrum: number[];
  @Prop homeTilt: number;      // <0 无数据
  @Prop homeHeading: number;   // <0 无数据

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  // 静态元数据（不含动态读数，读数在 InstrumentRow 内按 key 直接读 this.xxx）
  instruments(): Instrument[] {
    const t: AppTheme = this.th();
    return [
      new Instrument('decibel', 'wave', t.tintGreen, TOOL_GREEN, '分贝仪', '实时声压级测量',
        'pages/DecibelPage', ''),
      new Instrument('angle', 'angle', t.tintIndigo, TOOL_INDIGO, '角度仪', '倾角 / 坡度 / 水平',
        'pages/AnglePage', ''),
      new Instrument('compass', 'compass', t.tintPurple, TOOL_PURPLE, '指南针', '方位 / 朝向',
        'pages/CompassPage', ''),
      new Instrument('ruler', 'ruler', t.tintOrange, TOOL_ORANGE, '测距尺', '屏幕标尺 / 估距',
        'pages/RulerPage', ''),
    ];
  }

  // 首页大数字是否有实时读数
  hasDb(): boolean {
    return hasLiveDb(this.liveActive, this.homeDb);
  }

  // 等级渐变条上当前值指示点的横向百分比（与详情页表盘值域一致）
  dbPositionPct(): string {
    return (normalizeDecibelDisplayDb(this.homeDb) * 100).toFixed(1) + '%';
  }

  build() {
    Scroll() {
      Column() {
        // 顶部品牌
        Row() {
          Column() {
            Text('声活')
              .fontSize(27)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.th().textPrimary)
            Text('TOOLBOX · v2.0')
              .fontSize(11)
              .fontFamily(MONO)
              .fontColor(this.th().textTertiary)
              .letterSpacing(2)
              .margin({ top: 3 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Stack() {
            Column().width(40).height(40).borderRadius(12)
              .backgroundColor(this.th().surfaceAlt)
              .border({ width: this.th().isDark ? 1 : 0, color: this.th().cardBorder })
            Circle().width(15).height(15).fill('#00000000')
              .border({ width: 4, color: this.th().accent })
              .clip(true)
          }
        }
        .width('100%')
        .margin({ bottom: 18 })

        this.LiveCard()
        this.SectionLabel('测量仪表')
        Column({ space: 9 }) {
          // 显式调用而非 ForEach，规避 ForEach key 冻结导致动态读数不刷新
          this.InstrumentRow(this.instruments()[0])
          this.InstrumentRow(this.instruments()[1])
          this.InstrumentRow(this.instruments()[2])
          this.InstrumentRow(this.instruments()[3])
        }
        .width('100%')
        .margin({ bottom: 18 })

        this.SectionLabel('工具')
        Row({ space: 9 }) {
          this.ToolTile('flash', this.th().tintOrange, TOOL_ORANGE, '手电筒', 'pages/FlashlightPage')
          this.ToolTile('timer', this.th().tintIndigo, TOOL_INDIGO, '计时器', 'pages/TimerPage')
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 12, bottom: 24 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .align(Alignment.Top)
  }
  // PH_HOME

  @Builder
  SectionLabel(text: string) {
    Text(text)
      .fontSize(10)
      .fontFamily(MONO)
      .fontColor(this.th().textTertiary)
      .letterSpacing(2.2)
      .width('100%')
      .margin({ left: 2, bottom: 11 })
  }

  @Builder
  LiveCard() {
    Column() {
      Row() {
        Text(homeNoiseTitle(this.liveActive))
          .fontSize(11)
          .fontFamily(MONO)
          .fontColor(this.th().textTertiary)
          .letterSpacing(1.4)
          .layoutWeight(1)
        Row() {
          Circle().width(6).height(6)
            .fill(this.liveActive ? this.th().accent : this.th().textTertiary)
            .shadow(this.liveActive
              ? { radius: 7, color: withAlpha(this.th().accent, 'E6') }
              : { radius: 0, color: '#00000000' })
          Text(this.liveActive ? 'LIVE' : 'IDLE')
            .fontSize(10)
            .fontFamily(MONO)
            .fontColor(this.liveActive ? this.th().accent : this.th().textTertiary)
            .letterSpacing(1)
            .margin({ left: 5 })
        }
      }
      .width('100%')
      .margin({ bottom: 14 })

      Row() {
        Text(this.hasDb() ? this.homeDb.toString() : '--')
          .fontSize(46)
          .fontFamily(MONO_B)
          .fontColor(this.th().textPrimary)
        Text('dB')
          .fontSize(13)
          .fontFamily(MONO)
          .fontColor(this.th().textSecondary)
          .margin({ left: 6, bottom: 8 })
        Blank().layoutWeight(1)
        // 迷你频谱：实时时由 homeSpectrum 驱动，否则静态占位
        Row({ space: 2.5 }) {
          ForEach(this.miniSpectrum(), (h: number, i: number) => {
            Column()
              .width(3.5)
              .height(Math.max(3, 36 * h))
              .borderRadius(2)
              .backgroundColor(this.hasDb() ? levelColor(decibelFromSpectrumHeight(h))
                : (i % 3 === 0 ? levelColor(50) : this.th().accent))
          }, (h: number, i: number) => `${i}_${Math.round(h * 100)}`)
        }
        .height(36)
        .alignItems(VerticalAlign.Bottom)
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      // 等级渐变条 + 当前值指示点
      Row() {
        Stack({ alignContent: Alignment.Start }) {
          Row()
            .width('100%')
            .height(4)
            .borderRadius(2)
            .linearGradient({
              angle: 90,
              colors: [['#22C55E', 0], ['#84CC16', 0.25], ['#EAB308', 0.5], ['#F59E0B', 0.75], ['#EF4444', 1]]
            })
            .opacity(0.85)
          if (this.hasDb()) {
            Circle().width(9).height(9)
              .fill('#FFFFFF')
              .border({ width: 2, color: levelColor(this.homeDb) })
              .position({ x: this.dbPositionPct() })
              .markAnchor({ x: '50%', y: '50%' })
              .offset({ y: 2 })
          }
        }
        .layoutWeight(1)
        .height(9)
        Text(this.hasDb() ? levelLabel(this.homeDb) : '待测')
          .fontSize(11)
          .fontColor(this.th().textTertiary)
          .margin({ left: 10 })
      }
      .width('100%')
      .margin({ top: 14 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 18 })
    .linearGradient({
      angle: 150,
      colors: this.th().isDark
        ? [['#15181F', 0.0], ['#101216', 1.0]]
        : [['#FFFFFF', 0.0], ['#F4F5F8', 1.0]]
    })
    .borderRadius(22)
    .border({ width: 1, color: this.th().cardBorder })
    .shadow({ radius: this.th().isDark ? 0 : 12, color: '#14000000', offsetY: 5 })
    .margin({ bottom: 22 })
    .onClick(() => pushPage(this.getUIContext(), 'pages/DecibelPage'))
  }

  // 迷你频谱数据：有实时数据用 homeSpectrum（取前 8 条），否则静态占位
  miniSpectrum(): number[] {
    if (this.hasDb() && this.homeSpectrum.length > 0) {
      const out: number[] = [];
      const n: number = Math.min(8, this.homeSpectrum.length);
      for (let i = 0; i < n; i++) {
        out.push(this.homeSpectrum[i]);
      }
      return out;
    }
    return [0.38, 0.6, 0.48, 0.82, 0.56, 0.7, 0.34, 0.52];
  }

  // 工具行右侧摘要值（在 @Builder 内直接读 this.xxx，随实时状态刷新）；测距尺无摘要返回 ''
  summaryValue(key: string): string {
    if (key === 'decibel') {
      return homeDbSummary(this.liveActive, this.homeDb);
    }
    if (key === 'angle') {
      return angleSummary(this.homeTilt);
    }
    if (key === 'compass') {
      return compassSummary(this.homeHeading);
    }
    return '';
  }

  @Builder
  InstrumentRow(ins: Instrument) {
    Row() {
      Stack() {
        Column().width(40).height(40).borderRadius(12).backgroundColor(ins.tint)
        AppIcon({ name: ins.icon, color: ins.accent, iconSize: 20 })
      }
      .margin({ right: 14 })

      Column() {
        Text(ins.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.th().textPrimary)
        Text(ins.desc)
          .fontSize(12)
          .fontColor(this.th().textSecondary)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (ins.key === 'ruler') {
        Text('›')
          .fontSize(20)
          .fontColor(this.th().textTertiary)
      } else {
        Text(this.summaryValue(ins.key))
          .fontSize(13)
          .fontFamily(MONO_B)
          .fontColor(this.summaryValue(ins.key) === '--' ? this.th().textTertiary : ins.accent)
      }
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 13, bottom: 13 })
    .backgroundColor(this.th().surface)
    .borderRadius(16)
    .border({ width: 1, color: this.th().cardBorder })
    .onClick(() => pushPage(this.getUIContext(), ins.route))
  }

  @Builder
  ToolTile(icon: string, tint: string, accent: string, title: string, route: string) {
    Column() {
      Stack() {
        Column().width(36).height(36).borderRadius(11).backgroundColor(tint)
        AppIcon({ name: icon, color: accent, iconSize: 19 })
      }
      .margin({ bottom: 11 })
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.th().textPrimary)
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding(14)
    .backgroundColor(this.th().surface)
    .borderRadius(16)
    .border({ width: 1, color: this.th().cardBorder })
    .onClick(() => pushPage(this.getUIContext(), route))
  }
}
