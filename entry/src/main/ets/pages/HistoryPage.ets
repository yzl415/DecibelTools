import { common } from '@kit.AbilityKit';
import { HistoryView } from '../components/HistoryView';
import { MeasureRecord, RecordStore } from '../model/RecordStore';
import { AppTheme, getTheme } from '../model/Theme';
import { backPage } from '../model/NavigationHelper';

@Entry
@Component
struct HistoryPage {
  @StorageProp('themeDark') themeDark: boolean = false;
  @State records: MeasureRecord[] = [];
  private store: RecordStore = RecordStore.getInstance();

  th(): AppTheme {
    return getTheme(this.themeDark);
  }

  async aboutToAppear(): Promise<void> {
    const host = this.getUIContext().getHostContext();
    if (host !== undefined) {
      await this.store.init(host as common.UIAbilityContext);
    }
    this.refreshRecords();
  }

  refreshRecords(): void {
    this.records = this.store.records.slice(0);
  }

  build() {
    Column() {
      this.NavBar()
      HistoryView({
        records: this.records,
        showHeading: false,
        onRecordsChanged: () => this.refreshRecords()
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.th().bg)
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
      Text('分贝历史')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.th().textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Column().width(36).height(36)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 8 })
  }
}
