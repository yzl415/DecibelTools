import { router } from '@kit.ArkUI';
import { getTheme, AppTheme, levelColor, levelLabel, TOOL_GREEN, TOOL_INDIGO, TOOL_PURPLE, TOOL_ORANGE } from '../model/Theme';
import { RecordStore } from '../model/RecordStore';
import { AppIcon } from './AppIcon';

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
  @Prop recentDb: number;
  private recordStore: RecordStore = RecordStore.getInstance();

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  instruments(): Instrument[] {
    const t: AppTheme = this.th();
    return [
      new Instrument('decibel', 'wave', t.tintGreen, TOOL_GREEN, '分贝仪', '实时声压级测量',
        'pages/DecibelPage', '测量'),
      new Instrument('angle', 'angle', t.tintIndigo, TOOL_INDIGO, '角度仪', '倾角 / 坡度 / 水平',
        'pages/AnglePage', ''),
      new Instrument('compass', 'compass', t.tintPurple, TOOL_PURPLE, '指南针', '方位 / 朝向',
        'pages/CompassPage', ''),
      new Instrument('ruler', 'ruler', t.tintOrange, TOOL_ORANGE, '测距尺', '屏幕标尺 / 估距',
        'pages/RulerPage', ''),
    ];
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
              .fontFamily('HarmonyOS Sans')
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
          ForEach(this.instruments(), (ins: Instrument) => {
            this.InstrumentRow(ins)
          })
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
      .fontFamily('HarmonyOS Sans')
      .fontColor(this.th().textTertiary)
      .letterSpacing(2.2)
      .width('100%')
      .margin({ left: 2, bottom: 11 })
  }

  @Builder
  LiveCard() {
    Column() {
      Row() {
        Text('环境噪音 · 最近')
          .fontSize(11)
          .fontFamily('HarmonyOS Sans')
          .fontColor(this.th().textTertiary)
          .letterSpacing(1.4)
          .layoutWeight(1)
        Row() {
          Circle().width(6).height(6).fill(this.th().accent)
          Text('GO')
            .fontSize(10)
            .fontFamily('HarmonyOS Sans')
            .fontColor(this.th().accent)
            .letterSpacing(1)
            .margin({ left: 5 })
        }
      }
      .width('100%')
      .margin({ bottom: 14 })

      Row() {
        Text(this.recentDb > 0 ? this.recentDb.toString() : '--')
          .fontSize(46)
          .fontFamily('HarmonyOS Sans')
          .fontWeight(FontWeight.Bold)
          .fontColor(this.th().textPrimary)
        Text('dB')
          .fontSize(13)
          .fontFamily('HarmonyOS Sans')
          .fontColor(this.th().textSecondary)
          .margin({ left: 6, bottom: 8 })
        Blank().layoutWeight(1)
        // 迷你频谱
        Row({ space: 2.5 }) {
          ForEach([0.38, 0.6, 0.48, 0.82, 0.56, 0.7, 0.34, 0.52], (h: number, i: number) => {
            Column()
              .width(3.5)
              .height(36 * h)
              .borderRadius(2)
              .backgroundColor(i % 3 === 0 ? levelColor(50) : this.th().accent)
          })
        }
        .height(36)
        .alignItems(VerticalAlign.Bottom)
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      // 等级渐变条
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          Row()
            .width('100%')
            .height(4)
            .borderRadius(2)
            .linearGradient({
              angle: 90,
              colors: [['#22C55E', 0], ['#84CC16', 0.25], ['#EAB308', 0.5], ['#F59E0B', 0.75], ['#EF4444', 1]]
            })
            .opacity(0.85)
        }
        .layoutWeight(1)
        Text(this.recentDb > 0 ? levelLabel(this.recentDb) : '待测')
          .fontSize(11)
          .fontColor(this.th().textTertiary)
          .margin({ left: 10 })
      }
      .width('100%')
      .margin({ top: 14 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 18 })
    .backgroundColor(this.th().surface)
    .borderRadius(22)
    .border({ width: 1, color: this.th().cardBorder })
    .margin({ bottom: 22 })
    .onClick(() => router.pushUrl({ url: 'pages/DecibelPage' }))
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

      if (ins.value.length > 0) {
        Text(ins.value)
          .fontSize(13)
          .fontFamily('HarmonyOS Sans')
          .fontWeight(FontWeight.Bold)
          .fontColor(ins.accent)
      } else {
        Text('›')
          .fontSize(20)
          .fontColor(this.th().textTertiary)
      }
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 13, bottom: 13 })
    .backgroundColor(this.th().surface)
    .borderRadius(16)
    .border({ width: 1, color: this.th().cardBorder })
    .onClick(() => router.pushUrl({ url: ins.route }))
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
    .onClick(() => router.pushUrl({ url: route }))
  }
}
