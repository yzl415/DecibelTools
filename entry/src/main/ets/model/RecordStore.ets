/**
 * 测量历史仓库：保存每次分贝测量的结果（地点名 / 时间戳 / 均值 / 峰值 / 最小 / 时长）。
 * 以 JSON 数组序列化进 preferences，单例。仅本地存储，不上传。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME: string = 'decibel_records';
const KEY_RECORDS: string = 'records';
const MAX_RECORDS: number = 100;

/** 一条测量记录 */
export class MeasureRecord {
  id: number = 0;
  name: string = '未命名';
  time: number = 0;     // 开始时间戳（ms）
  durationSec: number = 0;
  min: number = 0;
  avg: number = 0;
  peak: number = 0;

  constructor(id: number, name: string, time: number, durationSec: number,
    min: number, avg: number, peak: number) {
    this.id = id;
    this.name = name;
    this.time = time;
    this.durationSec = durationSec;
    this.min = min;
    this.avg = avg;
    this.peak = peak;
  }
}

export class RecordStore {
  private static instance: RecordStore | null = null;
  private store: preferences.Preferences | null = null;
  records: MeasureRecord[] = [];

  static getInstance(): RecordStore {
    if (RecordStore.instance === null) {
      RecordStore.instance = new RecordStore();
    }
    return RecordStore.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.store !== null) {
      return;
    }
    try {
      this.store = await preferences.getPreferences(context, STORE_NAME);
      const raw: string = await this.store.get(KEY_RECORDS, '[]') as string;
      this.records = this.parse(raw);
    } catch (e) {
      this.store = null;
      this.records = [];
    }
  }

  private parse(raw: string): MeasureRecord[] {
    try {
      const arr: object[] = JSON.parse(raw) as object[];
      const out: MeasureRecord[] = [];
      for (const o of arr) {
        const r = o as MeasureRecord;
        out.push(new MeasureRecord(r.id, r.name, r.time, r.durationSec, r.min, r.avg, r.peak));
      }
      return out;
    } catch (e) {
      return [];
    }
  }

  /** 新增一条记录（插到最前）。返回新记录 */
  async add(name: string, durationSec: number, min: number, avg: number, peak: number): Promise<MeasureRecord> {
    const rec: MeasureRecord = new MeasureRecord(
      Date.now(), name, Date.now(), durationSec, min, avg, peak);
    this.records.unshift(rec);
    if (this.records.length > MAX_RECORDS) {
      this.records = this.records.slice(0, MAX_RECORDS);
    }
    await this.flush();
    return rec;
  }

  async remove(id: number): Promise<void> {
    this.records = this.records.filter((r: MeasureRecord) => r.id !== id);
    await this.flush();
  }

  async clear(): Promise<void> {
    this.records = [];
    await this.flush();
  }

  /** 最近 n 天的均值（用于趋势卡）。返回每天均值（无数据为 0） */
  recentAvg(): number {
    if (this.records.length === 0) {
      return 0;
    }
    let sum: number = 0;
    for (const r of this.records) {
      sum += r.avg;
    }
    return Math.round(sum / this.records.length);
  }

  /** 历史峰值 */
  peakOverall(): number {
    let p: number = 0;
    for (const r of this.records) {
      if (r.peak > p) {
        p = r.peak;
      }
    }
    return p;
  }

  private async flush(): Promise<void> {
    if (this.store === null) {
      return;
    }
    await this.store.put(KEY_RECORDS, JSON.stringify(this.records));
    await this.store.flush();
  }
}
