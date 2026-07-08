import { getTheme, AppTheme, TOOL_ORANGE, withAlpha , MONO, MONO_B } from '../model/Theme';
import display from '@ohos.display';
import { SettingsStore } from '../model/SettingsStore';
import { tapFeedback } from '../model/Haptics';
import { backPage } from '../model/NavigationHelper';
import { calibratedPxPerCm, resolvedRulerPxPerCm, RULER_CALIBRATION_PRESETS, RulerCalibrationPreset,
  rulerDistance, shouldAcceptCalibration, systemPxPerCm } from '../model/RulerCalibration';

@Entry
@Component
struct RulerPage {
  @StorageProp('themeDark') themeDark: boolean = false;
  @State unit: string = 'cm';
  @State topY: number = 44;       // 上标线位置（vp，相对标尺区顶部）
  @State botY: number = 204;      // 下标线位置
  @State calMode: boolean = false; // 校准模式
  @State pxPerCm: number = 38;
  @State systemPpc: number = 0;
  @State calibMessage: string = '';
  private store: SettingsStore = SettingsStore.getInstance();
  private dragTop: number = 0;
  private dragBot: number = 0;
  private rulerH: number = 380;

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  aboutToAppear(): void {
    this.unit = this.store.unit;
    this.systemPpc = this.readSystemPxPerCm();
    this.pxPerCm = resolvedRulerPxPerCm(this.store.pxPerCm, this.systemPpc);
  }

  // 当前两线间距离（按单位）
  distance(): number {
    return rulerDistance(this.botY - this.topY, this.pxPerCm, this.unit);
  }

  // 生成刻度（每 0.5cm 一短线，每 1cm 一长线带数字），覆盖 rulerH
  ticks(): number[] {
    const arr: number[] = [];
    const stepVp: number = this.pxPerCm / 2; // 0.5cm
    let y: number = 10;
    let i: number = 0;
    while (y < this.rulerH - 6) {
      arr.push(y);
      y += stepVp;
      i++;
    }
    return arr;
  }

  isMajor(idx: number): boolean {
    return idx % 2 === 0;
  }

  majorLabel(idx: number): string {
    return (idx / 2).toFixed(0);
  }

  setUnit(u: string): void {
    this.unit = u;
    this.store.setUnit(u);
  }

  zero(): void {
    this.topY = 44;
    this.botY = 44 + this.pxPerCm * 5;
  }

  // 校准：用户用实物（如硬币 / 银行卡 8.56cm）对齐两线，按实际厘米反算 px/cm。
  applyCalib(realCm: number): void {
    tapFeedback();
    const vp: number = Math.abs(this.botY - this.topY);
    if (!shouldAcceptCalibration(vp, realCm, this.systemPpc)) {
      this.calibMessage = '当前两条标线还没有夹住该参考物，请先对齐实物两端';
      return;
    }
    const ppc: number = calibratedPxPerCm(vp, realCm, this.pxPerCm);
    this.pxPerCm = ppc;
    this.store.setPxPerCm(this.pxPerCm);
    this.calibMessage = '';
    this.calMode = false;
  }

  toggleCalMode(): void {
    this.calibMessage = '';
    this.calMode = !this.calMode;
  }

  readSystemPxPerCm(): number {
    try {
      const d: display.Display = display.getDefaultDisplaySync();
      return systemPxPerCm(d.densityDPI, d.densityPixels);
    } catch (e) {
      return 0;
    }
  }

  build() {
    Column() {
      this.NavBar()
      Column() {
        // 标尺区
        Stack({ alignContent: Alignment.TopStart }) {
          // 刻度列
          Column()
            .width('100%').height(this.rulerH)
            .backgroundColor(this.th().surface)
            .borderRadius(18)
            .border({ width: 1, color: this.th().cardBorder })

          ForEach(this.ticks(), (y: number, idx: number) => {
            Row() {
              Column()
                .width(this.isMajor(idx) ? 34 : 18)
                .height(1.5)
                .backgroundColor(this.isMajor(idx) ? this.th().textSecondary : this.th().textTertiary)
              if (this.isMajor(idx)) {
                Text(this.majorLabel(idx))
                  .fontSize(11)
                  .fontFamily(MONO)
                  .fontColor(this.th().textSecondary)
                  .margin({ left: 6 })
              }
            }
            .position({ x: 0, y: y })
          })

          // 测量区域高亮
          Column()
            .width('92%')
            .height(Math.abs(this.botY - this.topY))
            .borderRadius(6)
            .backgroundColor(withAlpha(TOOL_ORANGE, '12'))
            .border({ width: 1.5, color: withAlpha(TOOL_ORANGE, '80'), style: BorderStyle.Dashed })
            .position({ x: '6%', y: Math.min(this.topY, this.botY) })

          // 上标线（可拖）
          this.MarkLine(this.topY, true)
          // 下标线（可拖）
          this.MarkLine(this.botY, false)

          // 距离气泡
          Row() {
            Text(this.distance().toFixed(this.unit === 'in' ? 2 : 1) + ' ' + this.unit)
              .fontSize(15)
              .fontFamily(MONO_B)
              .fontColor(this.th().accentText)
          }
          .padding({ left: 11, right: 11, top: 5, bottom: 5 })
          .backgroundColor(TOOL_ORANGE)
          .borderRadius(9)
          .position({ x: '64%', y: (this.topY + this.botY) / 2 - 14 })
        }
        .width('100%')
        .height(this.rulerH)

        Text(this.calMode
          ? '先让两条标线夹住参考物两端，再选择参考物的实际长度'
          : '拖动两条标线测量物体长度 · 先校准屏幕更准确')
          .fontSize(11)
          .fontColor(this.th().textTertiary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 14, bottom: 12 })

        Row({ space: 9 }) {
          this.ActionBtn('校准', false, () => this.toggleCalMode())
          this.ActionBtn('归零', true, () => this.zero())
        }
        .width('100%')

        if (this.calMode) {
          this.CalibPanel()
        }
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 22, right: 22 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.th().bg)
  }
  // PH_RULER

  @Builder
  MarkLine(y: number, isTop: boolean) {
    Row() {
      Circle().width(14).height(14).fill(TOOL_ORANGE)
        .shadow({ radius: 8, color: withAlpha(TOOL_ORANGE, '99') })
      Column().layoutWeight(1).height(2).backgroundColor(TOOL_ORANGE)
        .shadow({ radius: 8, color: withAlpha(TOOL_ORANGE, '80') })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .position({ x: 0, y: y - 7 })
    .gesture(
      PanGesture()
        .onActionStart(() => {
          if (isTop) {
            this.dragTop = this.topY;
          } else {
            this.dragBot = this.botY;
          }
        })
        .onActionUpdate((e: GestureEvent) => {
          if (isTop) {
            let v: number = this.dragTop + e.offsetY;
            this.topY = Math.max(8, Math.min(this.rulerH - 8, v));
          } else {
            let v: number = this.dragBot + e.offsetY;
            this.botY = Math.max(8, Math.min(this.rulerH - 8, v));
          }
        })
    )
  }

  @Builder
  ActionBtn(label: string, filled: boolean, cb: () => void) {
    Row() {
      Column().width(12).height(12)
        .borderRadius(filled ? 3 : 6)
        .backgroundColor(filled ? TOOL_ORANGE : '#00000000')
        .border(filled ? { width: 0 } : { width: 2, color: this.th().textSecondary })
      Text(label)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.th().textPrimary)
        .margin({ left: 8 })
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .padding({ top: 14, bottom: 14 })
    .backgroundColor(this.th().surface)
    .borderRadius(15)
    .border({ width: 1, color: this.th().cardBorder })
    .onClick(cb)
  }

  @Builder
  CalibPanel() {
    Column() {
      Text('选择参考物的实际长度')
        .fontSize(12)
        .fontColor(this.th().textSecondary)
        .width('100%')
        .margin({ bottom: 10 })
      Row({ space: 8 }) {
        ForEach(RULER_CALIBRATION_PRESETS, (preset: RulerCalibrationPreset) => {
          this.CalibChip(preset)
        })
      }
      .width('100%')
      if (this.calibMessage.length > 0) {
        Text(this.calibMessage)
          .fontSize(11)
          .fontColor(this.th().danger)
          .lineHeight(16)
          .width('100%')
          .margin({ top: 10 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.th().surface)
    .borderRadius(16)
    .border({ width: 1, color: this.th().cardBorder })
    .margin({ top: 12 })
  }

  @Builder
  CalibChip(preset: RulerCalibrationPreset) {
    Button(preset.label)
      .fontSize(11)
      .fontColor(this.th().textPrimary)
      .layoutWeight(1)
      .padding({ top: 10, bottom: 10 })
      .backgroundColor(this.th().surfaceAlt)
      .borderRadius(10)
      .border({ width: 1, color: this.th().cardBorder })
      .stateEffect(true)
      .onClick(() => this.applyCalib(preset.cm))
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
      Text('测距尺')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.th().textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Row() {
        this.UnitSeg('cm')
        this.UnitSeg('in')
      }
      .padding(2)
      .backgroundColor(this.th().surface)
      .borderRadius(9)
      .border({ width: 1, color: this.th().cardBorder })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 8 })
  }

  @Builder
  UnitSeg(u: string) {
    Text(u)
      .fontSize(11)
      .fontFamily(MONO_B)
      .fontColor(this.unit === u ? this.th().accentText : this.th().textTertiary)
      .padding({ left: 9, right: 9, top: 4, bottom: 4 })
      .backgroundColor(this.unit === u ? TOOL_ORANGE : '#00000000')
      .borderRadius(6)
      .onClick(() => this.setUnit(u))
  }
}
