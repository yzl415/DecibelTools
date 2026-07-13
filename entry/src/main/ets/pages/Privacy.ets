import { getTheme, AppTheme } from '../model/Theme';
import { APP_DISPLAY_NAME } from '../model/AppMetadata';
import { backPage } from '../model/NavigationHelper';

/** 隐私政策页：说明数据收集、存储、权限用途。 */
@Entry
@Component
struct Privacy {
  @StorageProp('themeDark') themeDark: boolean = false;

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  build() {
    Column() {
      this.NavBar()
      Scroll() {
        Column() {
          this.Section('引言',
            '感谢你使用「' + APP_DISPLAY_NAME + '」。我们非常重视你的隐私与个人信息保护。本政策说明我们如何处理你的信息。简而言之：本应用所有功能均在本机完成，不收集、不上传、不与任何第三方共享你的任何信息。')
          this.Section('我们收集的信息',
            '本应用不收集任何个人身份信息，不需要注册或登录，无需联网即可使用全部功能。')
          this.Section('权限说明',
            '麦克风权限：仅用于分贝仪实时测量环境噪音的响度。音频数据在设备本地实时计算分贝值后即丢弃，全程不录音、不保存音频文件、不上传。你可随时在系统设置中关闭该权限，关闭后分贝仪将无法使用，其他工具不受影响。相机/闪光灯：手电筒频闪功能需要控制闪光灯硬件，不会拍摄或采集任何影像。传感器：角度仪需读取重力/加速度传感器数据以计算倾角，数据仅用于本机实时显示。')
          this.Section('数据存储与安全',
            '应用仅在本地保存主题、校准值、测量历史等偏好数据，受设备系统安全机制保护。卸载应用会一并删除这些数据。')
          this.Section('数据共享',
            '我们不会将你的任何数据出售、出租或共享给第三方。应用内无广告 SDK、无统计 SDK，不进行任何形式的网络数据传输。')
          this.Section('未成年人保护',
            '本应用适合所有年龄段使用。若你是未成年人，建议在监护人指导下使用。')
          this.Section('政策更新',
            '我们可能适时更新本政策，更新后会在应用内提示。继续使用即表示你接受更新后的政策。')
          this.Section('联系我们',
            '如对本隐私政策有任何疑问，可通过应用市场页面的开发者联系方式与我们联系。')
          Text('最后更新：2026年7月')
            .fontSize(12)
            .fontColor(this.th().textTertiary)
            .width('100%')
            .margin({ top: 20, bottom: 10 })
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
  NavBar() {
    Row() {
      Text('‹ 返回')
        .fontSize(16)
        .fontColor(this.th().accent)
        .onClick(() => backPage(this.getUIContext()))
        .layoutWeight(1)
      Text('隐私政策')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.th().textPrimary)
      Blank().layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 14, bottom: 10 })
  }

  @Builder
  Section(title: string, body: string) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.th().textPrimary)
        .width('100%')
        .margin({ bottom: 8 })
      Text(body)
        .fontSize(14)
        .lineHeight(22)
        .fontColor(this.th().textSecondary)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ top: 18 })
  }
}
