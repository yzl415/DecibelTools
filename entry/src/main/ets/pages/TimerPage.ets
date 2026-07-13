import { getTheme, AppTheme, TOOL_INDIGO, withAlpha, MONO, MONO_B } from '../model/Theme';
import { tapFeedback } from '../model/Haptics';
import { AppIcon } from '../components/AppIcon';
import { backPage, showInfoDialog } from '../model/NavigationHelper';
import { TimerState } from '../model/TimerState';

@Entry
@Component
struct TimerPage {
  @StorageProp('themeDark') themeDark: boolean = false;
  @State elapsedMs: number = 0;
  @State running: boolean = false;
  @State laps: number[] = [];
  private timer: number = -1;
  private timerState: TimerState = new TimerState();

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  aboutToDisappear(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  toggle(): void {
    tapFeedback();
    if (this.running) {
      // 暂停
      const stopped = this.timerState.stop(Date.now());
      this.elapsedMs = stopped.elapsedMs;
      if (this.timer !== -1) {
        clearInterval(this.timer);
        this.timer = -1;
      }
      this.running = false;
    } else {
      this.timerState.start(Date.now());
      this.running = true;
      this.timer = setInterval(() => {
        this.elapsedMs = this.timerState.snapshot(Date.now()).elapsedMs;
      }, 31);
    }
  }

  // 左键：计次（仅运行中可用）
  lap(): void {
    if (!this.running) {
      return;
    }
    tapFeedback();
    this.laps = this.timerState.lap(Date.now()).laps;
  }

  // 右键：复位（运行中点则停止并清零）
  reset(): void {
    tapFeedback();
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
    this.running = false;
    this.elapsedMs = 0;
    this.laps = [];
    this.timerState.reset();
  }

  showInfo(): void {
    showInfoDialog(this.getUIContext(), '关于计时器',
      '中间按钮开始 / 停止计时。计时中点左侧"计次"记录当前分段，'
        + '点右侧"复位"停止并清零全部数据。');
  }

  // 主显示 mm:ss
  mmss(ms: number): string {
    const total: number = Math.floor(ms / 1000);
    const m: number = Math.floor(total / 60);
    const s: number = total % 60;
    return m.toString().padStart(2, '0') + ':' + s.toString().padStart(2, '0');
  }

  // 百分秒
  cs(ms: number): string {
    return '.' + Math.floor((ms % 1000) / 10).toString().padStart(2, '0');
  }

  // 环进度：秒针 0~60s 一圈
  ringAngle(): number {
    const sec: number = (this.elapsedMs / 1000) % 60;
    return sec / 60 * 360;
  }

  build() {
    Column() {
      this.NavBar()
      Column() {
        // 进度环 + 中央读数
        Stack({ alignContent: Alignment.Center }) {
          Progress({ value: this.ringAngle(), total: 360, type: ProgressType.Ring })
            .width(236).height(236)
            .color(TOOL_INDIGO)
            .backgroundColor(this.th().track)
            .style({ strokeWidth: 12 })
          Column() {
            Text(this.mmss(this.elapsedMs))
              .fontSize(50)
              .fontFamily(MONO_B)
              .fontColor(this.th().textPrimary)
            Text(this.cs(this.elapsedMs))
              .fontSize(14)
              .fontFamily(MONO)
              .fontColor(this.th().textTertiary)
              .margin({ top: 6 })
            Text(this.running ? '计时中' : '已用时')
              .fontSize(12)
              .fontColor(this.th().textSecondary)
              .margin({ top: 6 })
          }
        }
        .margin({ top: 14 })

        // 控制按钮：计次 / 开始停止 / 复位（三槽稳定占位）
        Row() {
          this.RoundBtn('计次', 60, true, () => this.lap())
          this.MainBtn()
          this.RoundBtn('复位', 60, false, () => this.reset())
        }
        .justifyContent(FlexAlign.SpaceEvenly)
        .width('100%')
        .margin({ top: 26, bottom: 18 })

        // 计次列表
        if (this.laps.length > 0) {
          Column() {
            ForEach(this.laps, (lap: number, idx: number) => {
              Column() {
                Row() {
                  Text('计次 ' + (this.laps.length - idx).toString().padStart(2, '0'))
                    .fontSize(13)
                    .fontFamily(MONO)
                    .fontColor(this.th().textSecondary)
                    .layoutWeight(1)
                  Text(this.mmss(lap) + this.cs(lap))
                    .fontSize(13)
                    .fontFamily(MONO)
                    .fontColor(this.th().textPrimary)
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 11, bottom: 11 })
                if (idx < this.laps.length - 1) {
                  Row().width('100%').height(1).backgroundColor(this.th().divider)
                }
              }
            }, (lap: number, idx: number) => `${idx}_${lap}`)
          }
          .width('100%')
          .backgroundColor(this.th().surface)
          .borderRadius(16)
          .border({ width: 1, color: this.th().cardBorder })
          .clip(true)
        }
        Blank().layoutWeight(1)
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 22, right: 22 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.th().bg)
  }
  // PH_TIMER

  @Builder
  RoundBtn(label: string, size: number, isLap: boolean, cb: () => void) {
    Text(label)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(isLap && this.running ? TOOL_INDIGO : this.th().textSecondary)
      .textAlign(TextAlign.Center)
      .width(size).height(size)
      .borderRadius(size / 2)
      .backgroundColor(isLap && this.running ? withAlpha(TOOL_INDIGO, '20') : this.th().surface)
      .border({ width: 1, color: isLap && this.running
        ? withAlpha(TOOL_INDIGO, '80') : this.th().cardBorder })
      .opacity(isLap && !this.running ? 0.45 : 1)
      .id(isLap ? 'timer-lap-button' : 'timer-reset-button')
      .onClick(cb)
  }

  @Builder
  MainBtn() {
    Stack({ alignContent: Alignment.Center }) {
      Circle().width(74).height(74)
        .fill(this.running ? (this.themeDark ? '#1E1416' : '#FBEAEA') : this.th().accentSoft)
        .border({ width: 1, color: this.running
          ? (this.themeDark ? '#45272A' : '#F3CFD0')
          : (this.themeDark ? '#15493A' : '#B5E8D6') })
      if (this.running) {
        Column().width(18).height(18).borderRadius(4).backgroundColor(this.th().danger)
      } else {
        Polygon().points([[0, 0], [0, 20], [18, 10]]).width(18).height(20)
          .fill(this.th().accentStrong).margin({ left: 4 })
      }
    }
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
      .onClick(() => backPage(this.getUIContext()))
      Text('计时器')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.th().textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Stack() {
        Column().width(36).height(36).borderRadius(11).backgroundColor(this.th().surfaceAlt)
          .border({ width: this.th().isDark ? 1 : 0, color: this.th().cardBorder })
        AppIcon({ name: 'info', color: this.th().textSecondary, iconSize: 16 })
      }
      .onClick(() => this.showInfo())
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 8 })
  }
}
