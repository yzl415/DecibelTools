import { getTheme, AppTheme } from '../model/Theme';

/**
 * 空状态矢量插画：圆形浅色背景 + 主题色图元，替代 emoji 当主视觉。
 * kind: sprout(今日空) / chart(统计空) / box(排序空)
 */
@Component
export struct EmptyArt {
  kind: string = 'sprout';
  accent: string = '#4F46E5';
  @StorageProp('themeDark') themeDark: boolean = false;
  private box: number = 120;

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  u(f: number): number {
    return this.box * f;
  }

  // 各空状态的主图元颜色
  motif(): string {
    if (this.kind === 'sprout') {
      return '#34C759';
    }
    if (this.kind === 'chart') {
      return this.accent;
    }
    return this.themeDark ? '#6B7280' : '#9AA0AC';
  }

  // 圆底色：在主色上加 alpha 前缀（ArkUI 为 #AARRGGBB）
  circleFill(): string {
    const a: string = this.themeDark ? '30' : '1A';
    return a + this.motif().substring(1);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 圆形浅色底
      Circle()
        .width(this.box)
        .height(this.box)
        .fill('#' + this.circleFill())
      if (this.kind === 'sprout') {
        this.Sprout()
      } else if (this.kind === 'chart') {
        this.Chart()
      } else if (this.kind === 'box') {
        this.Box()
      }
    }
    .width(this.box)
    .height(this.box)
  }

  // 嫩芽：茎 + 两片叶
  @Builder
  Sprout() {
    Stack({ alignContent: Alignment.Center }) {
      // 茎
      Column()
        .width(this.u(0.05))
        .height(this.u(0.4))
        .backgroundColor(this.motif())
        .borderRadius(this.u(0.025))
        .offset({ y: this.u(0.1) })
      // 左叶
      Ellipse()
        .width(this.u(0.28))
        .height(this.u(0.18))
        .fill(this.motif())
        .rotate({ angle: 32 })
        .offset({ x: -this.u(0.13), y: this.u(0.02) })
      // 右叶
      Ellipse()
        .width(this.u(0.28))
        .height(this.u(0.18))
        .fill(this.motif())
        .opacity(0.75)
        .rotate({ angle: -32 })
        .offset({ x: this.u(0.13), y: -this.u(0.06) })
    }
    .width(this.box)
    .height(this.box)
  }

  // 柱状图：三根柱子
  @Builder
  Chart() {
    Row({ space: this.u(0.06) }) {
      Column().width(this.u(0.1)).height(this.u(0.26)).backgroundColor(this.motif()).opacity(0.55).borderRadius(this.u(0.04))
      Column().width(this.u(0.1)).height(this.u(0.44)).backgroundColor(this.motif()).borderRadius(this.u(0.04))
      Column().width(this.u(0.1)).height(this.u(0.34)).backgroundColor(this.motif()).opacity(0.75).borderRadius(this.u(0.04))
    }
    .alignItems(VerticalAlign.Bottom)
    .height(this.u(0.5))
  }

  // 空盒子：梯形盖 + 方体
  @Builder
  Box() {
    Column() {
      Column()
        .width(this.u(0.5))
        .height(this.u(0.12))
        .backgroundColor(this.motif())
        .borderRadius(this.u(0.03))
      Column()
        .width(this.u(0.42))
        .height(this.u(0.28))
        .backgroundColor(this.motif())
        .opacity(0.6)
        .borderRadius({ bottomLeft: this.u(0.05), bottomRight: this.u(0.05) })
    }
  }
}
