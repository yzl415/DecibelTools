/**
 * 统一矢量图标：用基础图元（矩形/圆/旋转）按 iconSize 比例拼出，渲染可靠。
 * 颜色用 color；月亮/太阳缺口用 cutout（需与所在容器底色一致）。
 */
@Component
export struct AppIcon {
  name: string = '';
  color: string = '#000000';
  iconSize: number = 24;
  stroke: number = 2;
  cutout: string = '#FFFFFF';

  // 按比例换算尺寸
  u(f: number): number {
    return this.iconSize * f;
  }

  // 矩形条
  @Builder
  Bar(w: number, h: number, r: number) {
    Column().width(w).height(h).backgroundColor(this.color).borderRadius(r)
  }

  // 今日：日历（圆角描边方框 + 顶部实心条）
  @Builder
  IconToday() {
    Stack({ alignContent: Alignment.Top }) {
      Column()
        .width(this.u(0.74))
        .height(this.u(0.66))
        .borderRadius(this.u(0.16))
        .border({ width: Math.max(1.5, this.u(0.085)), color: this.color })
      Column()
        .width(this.u(0.74))
        .height(this.u(0.2))
        .backgroundColor(this.color)
        .borderRadius({ topLeft: this.u(0.14), topRight: this.u(0.14) })
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }

  // 统计：三根柱子
  @Builder
  IconStats() {
    Row({ space: this.u(0.09) }) {
      this.Bar(this.u(0.15), this.u(0.4), this.u(0.06))
      this.Bar(this.u(0.15), this.u(0.68), this.u(0.06))
      this.Bar(this.u(0.15), this.u(0.52), this.u(0.06))
    }
    .width(this.iconSize)
    .height(this.iconSize)
    .alignItems(VerticalAlign.Bottom)
    .justifyContent(FlexAlign.Center)
  }

  // 我的：人像（头 + 肩）
  @Builder
  IconMine() {
    Column() {
      Circle().width(this.u(0.34)).height(this.u(0.34)).fill(this.color)
      Column()
        .width(this.u(0.58))
        .height(this.u(0.32))
        .backgroundColor(this.color)
        .borderRadius({
          topLeft: this.u(0.29), topRight: this.u(0.29),
          bottomLeft: this.u(0.05), bottomRight: this.u(0.05)
        })
        .margin({ top: this.u(0.05) })
    }
    .width(this.iconSize)
    .height(this.iconSize)
    .justifyContent(FlexAlign.Center)
  }

  // 加号
  @Builder
  IconPlus() {
    Stack() {
      this.Bar(this.u(0.72), this.u(0.13), this.u(0.07))
      this.Bar(this.u(0.13), this.u(0.72), this.u(0.07))
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }

  // 排序：三条横线
  @Builder
  IconReorder() {
    Column({ space: this.u(0.2) }) {
      this.Bar(this.u(0.74), this.u(0.1), this.u(0.05))
      this.Bar(this.u(0.74), this.u(0.1), this.u(0.05))
      this.Bar(this.u(0.74), this.u(0.1), this.u(0.05))
    }
    .width(this.iconSize)
    .height(this.iconSize)
    .justifyContent(FlexAlign.Center)
  }

  // 奖杯：杯身 + 杯柄 + 底座
  @Builder
  IconTrophy() {
    Column() {
      Column()
        .width(this.u(0.42))
        .height(this.u(0.34))
        .backgroundColor(this.color)
        .borderRadius({
          topLeft: this.u(0.05), topRight: this.u(0.05),
          bottomLeft: this.u(0.18), bottomRight: this.u(0.18)
        })
      this.Bar(this.u(0.1), this.u(0.12), 0)
      this.Bar(this.u(0.42), this.u(0.09), this.u(0.04))
    }
    .width(this.iconSize)
    .height(this.iconSize)
    .justifyContent(FlexAlign.Center)
  }

  // 铃铛：钟身 + 底座 + 摆锤
  @Builder
  IconBell() {
    Column() {
      Column()
        .width(this.u(0.5))
        .height(this.u(0.44))
        .backgroundColor(this.color)
        .borderRadius({
          topLeft: this.u(0.25), topRight: this.u(0.25),
          bottomLeft: this.u(0.06), bottomRight: this.u(0.06)
        })
      this.Bar(this.u(0.66), this.u(0.1), this.u(0.05))
      Circle().width(this.u(0.14)).height(this.u(0.14)).fill(this.color).margin({ top: this.u(0.03) })
    }
    .width(this.iconSize)
    .height(this.iconSize)
    .justifyContent(FlexAlign.Center)
  }

  // 上箭头（导出）：竖杆 + 顶部人字头
  @Builder
  IconUpload() {
    Stack({ alignContent: Alignment.Center }) {
      this.Bar(this.u(0.12), this.u(0.62), this.u(0.06))
      Column().width(this.u(0.12)).height(this.u(0.3)).backgroundColor(this.color).borderRadius(this.u(0.06))
        .rotate({ angle: -38 }).offset({ x: -this.u(0.13), y: -this.u(0.22) })
      Column().width(this.u(0.12)).height(this.u(0.3)).backgroundColor(this.color).borderRadius(this.u(0.06))
        .rotate({ angle: 38 }).offset({ x: this.u(0.13), y: -this.u(0.22) })
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }

  // 下箭头（导入）：竖杆 + 底部人字头
  @Builder
  IconDownload() {
    Stack({ alignContent: Alignment.Center }) {
      this.Bar(this.u(0.12), this.u(0.62), this.u(0.06))
      Column().width(this.u(0.12)).height(this.u(0.3)).backgroundColor(this.color).borderRadius(this.u(0.06))
        .rotate({ angle: 38 }).offset({ x: -this.u(0.13), y: this.u(0.22) })
      Column().width(this.u(0.12)).height(this.u(0.3)).backgroundColor(this.color).borderRadius(this.u(0.06))
        .rotate({ angle: -38 }).offset({ x: this.u(0.13), y: this.u(0.22) })
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }

  // 太阳：光芒 + 圆心
  @Builder
  IconSun() {
    Stack({ alignContent: Alignment.Center }) {
      Column().width(this.u(0.08)).height(this.u(0.92)).backgroundColor(this.color).borderRadius(this.u(0.04))
      Column().width(this.u(0.08)).height(this.u(0.92)).backgroundColor(this.color).borderRadius(this.u(0.04))
        .rotate({ angle: 90 })
      Column().width(this.u(0.08)).height(this.u(0.92)).backgroundColor(this.color).borderRadius(this.u(0.04))
        .rotate({ angle: 45 })
      Column().width(this.u(0.08)).height(this.u(0.92)).backgroundColor(this.color).borderRadius(this.u(0.04))
        .rotate({ angle: -45 })
      Circle().width(this.u(0.72)).height(this.u(0.72)).fill(this.cutout)
      Circle().width(this.u(0.5)).height(this.u(0.5)).fill(this.color)
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }

  // 月亮：实心圆被同底色圆挖出月牙
  @Builder
  IconMoon() {
    Stack({ alignContent: Alignment.Center }) {
      Circle().width(this.u(0.78)).height(this.u(0.78)).fill(this.color)
      Circle().width(this.u(0.66)).height(this.u(0.66)).fill(this.cutout)
        .offset({ x: -this.u(0.22), y: -this.u(0.08) })
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }

  // 盾牌（隐私）：圆角盾形 + 内部对勾
  @Builder
  IconShield() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.u(0.56))
        .height(this.u(0.66))
        .backgroundColor(this.color)
        .borderRadius({
          topLeft: this.u(0.1), topRight: this.u(0.1),
          bottomLeft: this.u(0.28), bottomRight: this.u(0.28)
        })
      Column()
        .width(this.u(0.3))
        .height(this.u(0.3))
        .backgroundColor(this.cutout)
        .borderRadius(this.u(0.06))
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }

  // 对勾：两段旋转的短条组成 ✓（交点在底部偏左，短臂朝左上、长臂朝右上）
  @Builder
  IconCheck() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.u(0.16))
        .height(this.u(0.34))
        .backgroundColor(this.color)
        .borderRadius(this.u(0.08))
        .rotate({ angle: -45 })
        .offset({ x: -this.u(0.19), y: this.u(0.10) })
      Column()
        .width(this.u(0.16))
        .height(this.u(0.58))
        .backgroundColor(this.color)
        .borderRadius(this.u(0.08))
        .rotate({ angle: 40 })
        .offset({ x: this.u(0.10), y: -this.u(0.02) })
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }

  // 分贝/声波：三条高度递增的竖条（声波柱）
  @Builder
  IconWave() {
    Row({ space: this.u(0.1) }) {
      this.Bar(this.u(0.12), this.u(0.36), this.u(0.06))
      this.Bar(this.u(0.12), this.u(0.74), this.u(0.06))
      this.Bar(this.u(0.12), this.u(0.52), this.u(0.06))
      this.Bar(this.u(0.12), this.u(0.24), this.u(0.06))
    }
    .width(this.iconSize)
    .height(this.iconSize)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  // 角度仪：一条横边 + 一条斜边组成的夹角
  @Builder
  IconAngle() {
    Stack({ alignContent: Alignment.BottomStart }) {
      this.Bar(this.u(0.82), this.u(0.12), this.u(0.06))
      Column().width(this.u(0.12)).height(this.u(0.82)).backgroundColor(this.color).borderRadius(this.u(0.06))
        .rotate({ angle: 32, centerX: '50%', centerY: '100%' })
        .offset({ x: this.u(0.02), y: 0 })
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }

  // 手电筒：上宽下窄的灯头 + 灯柄
  @Builder
  IconFlash() {
    Column() {
      Column()
        .width(this.u(0.5))
        .height(this.u(0.2))
        .backgroundColor(this.color)
        .borderRadius({ topLeft: this.u(0.06), topRight: this.u(0.06) })
      Column()
        .width(this.u(0.36))
        .height(this.u(0.5))
        .backgroundColor(this.color)
        .borderRadius({ bottomLeft: this.u(0.05), bottomRight: this.u(0.05) })
        .margin({ top: this.u(0.04) })
    }
    .width(this.iconSize)
    .height(this.iconSize)
    .justifyContent(FlexAlign.Center)
  }

  // 齿轮（设置）：圆环 + 中心孔（简化）
  @Builder
  IconGear() {
    Stack({ alignContent: Alignment.Center }) {
      Circle().width(this.u(0.78)).height(this.u(0.78)).fill(this.color)
      Circle().width(this.u(0.3)).height(this.u(0.3)).fill(this.cutout)
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }

  // 指南针：圆环 + 中心指针（上红下灰用单色近似：菱形指针）
  @Builder
  IconCompass() {
    Stack({ alignContent: Alignment.Center }) {
      Circle().width(this.u(0.92)).height(this.u(0.92)).fill('#00000000')
        .border({ width: Math.max(1.6, this.u(0.1)), color: this.color })
      // 指针：细长菱形（用旋转方块近似）
      Column()
        .width(this.u(0.12))
        .height(this.u(0.5))
        .backgroundColor(this.color)
        .borderRadius(this.u(0.06))
        .rotate({ angle: 32 })
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }

  // 测距尺：方框 + 中间一条横线（标尺）
  @Builder
  IconRuler() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.u(0.86))
        .height(this.u(0.56))
        .borderRadius(this.u(0.08))
        .border({ width: Math.max(1.6, this.u(0.09)), color: this.color })
      this.Bar(this.u(0.58), this.u(0.09), this.u(0.04))
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }

  // 计时器：圆环 + 顶部按钮 + 指针
  @Builder
  IconTimer() {
    Stack({ alignContent: Alignment.Center }) {
      Circle().width(this.u(0.78)).height(this.u(0.78)).fill('#00000000')
        .border({ width: Math.max(1.6, this.u(0.1)), color: this.color })
      // 顶部按钮
      Column().width(this.u(0.2)).height(this.u(0.1)).backgroundColor(this.color)
        .borderRadius(this.u(0.04)).offset({ y: -this.u(0.46) })
      // 指针（竖直向上偏右）
      Column().width(this.u(0.08)).height(this.u(0.3)).backgroundColor(this.color)
        .borderRadius(this.u(0.04)).rotate({ angle: 40 })
        .offset({ x: this.u(0.06), y: -this.u(0.06) })
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }

  // 列表（历史）：三行点+线
  @Builder
  IconList() {
    Column({ space: this.u(0.16) }) {
      this.ListRow()
      this.ListRow()
      this.ListRow()
    }
    .width(this.iconSize)
    .height(this.iconSize)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ListRow() {
    Row({ space: this.u(0.12) }) {
      Circle().width(this.u(0.12)).height(this.u(0.12)).fill(this.color)
      this.Bar(this.u(0.56), this.u(0.1), this.u(0.05))
    }
    .alignItems(VerticalAlign.Center)
  }

  // 网格（工具）：四个小方块
  @Builder
  IconGrid() {
    Column({ space: this.u(0.12) }) {
      Row({ space: this.u(0.12) }) {
        this.GridCell()
        this.GridCell()
      }
      Row({ space: this.u(0.12) }) {
        this.GridCell()
        this.GridCell()
      }
    }
    .width(this.iconSize)
    .height(this.iconSize)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  GridCell() {
    Column().width(this.u(0.32)).height(this.u(0.32)).backgroundColor(this.color)
      .borderRadius(this.u(0.07))
  }

  build() {
    if (this.name === 'today') {
      this.IconToday()
    } else if (this.name === 'stats') {
      this.IconStats()
    } else if (this.name === 'mine') {
      this.IconMine()
    } else if (this.name === 'plus') {
      this.IconPlus()
    } else if (this.name === 'reorder') {
      this.IconReorder()
    } else if (this.name === 'trophy') {
      this.IconTrophy()
    } else if (this.name === 'bell') {
      this.IconBell()
    } else if (this.name === 'upload') {
      this.IconUpload()
    } else if (this.name === 'download') {
      this.IconDownload()
    } else if (this.name === 'sun') {
      this.IconSun()
    } else if (this.name === 'moon') {
      this.IconMoon()
    } else if (this.name === 'shield') {
      this.IconShield()
    } else if (this.name === 'check') {
      this.IconCheck()
    } else if (this.name === 'wave') {
      this.IconWave()
    } else if (this.name === 'angle') {
      this.IconAngle()
    } else if (this.name === 'flash') {
      this.IconFlash()
    } else if (this.name === 'gear') {
      this.IconGear()
    } else if (this.name === 'compass') {
      this.IconCompass()
    } else if (this.name === 'ruler') {
      this.IconRuler()
    } else if (this.name === 'timer') {
      this.IconTimer()
    } else if (this.name === 'list') {
      this.IconList()
    } else if (this.name === 'grid') {
      this.IconGrid()
    }
  }
}
