import { MeasureRecord } from './RecordStore';

export const HISTORY_RANGE_TODAY: number = 0;
export const HISTORY_RANGE_7_DAYS: number = 1;
export const HISTORY_RANGE_30_DAYS: number = 2;

const DAY_MS: number = 24 * 3600 * 1000;
const WEEKDAY_CN: string[] = ['日', '一', '二', '三', '四', '五', '六'];

export class TrendPoint {
  label: string = '';
  value: number = 0;
  has: boolean = false;

  constructor(label: string, value: number, has: boolean) {
    this.label = label;
    this.value = value;
    this.has = has;
  }
}

export function filterRecordsByRange(records: MeasureRecord[], range: number, nowMs: number): MeasureRecord[] {
  const days: number = range === HISTORY_RANGE_TODAY ? 1 : range === HISTORY_RANGE_7_DAYS ? 7 : 30;
  const cutoff: number = nowMs - days * DAY_MS;
  return records.filter((r: MeasureRecord) => r.time >= cutoff);
}

export function averageDb(records: MeasureRecord[]): number {
  if (records.length === 0) {
    return 0;
  }
  let sum: number = 0;
  for (const r of records) {
    sum += r.avg;
  }
  return Math.round(sum / records.length);
}

export function peakDb(records: MeasureRecord[]): number {
  let peak: number = 0;
  for (const r of records) {
    if (r.peak > peak) {
      peak = r.peak;
    }
  }
  return peak;
}

export function peakRecord(records: MeasureRecord[]): MeasureRecord | null {
  let best: MeasureRecord | null = null;
  for (const r of records) {
    if (best === null || r.peak > best.peak) {
      best = r;
    }
  }
  return best;
}

export function peakTimeLabel(record: MeasureRecord | null): string {
  if (record === null) {
    return '';
  }
  const d: Date = new Date(record.time);
  const part: string = d.getHours() < 12 ? '上午' : '下午';
  return `周${WEEKDAY_CN[d.getDay()]} ${part}`;
}

export function todayRecords(records: MeasureRecord[], nowMs: number): MeasureRecord[] {
  const now: Date = new Date(nowMs);
  const start: number = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  const list: MeasureRecord[] = records.filter((r: MeasureRecord) => r.time >= start);
  return list.sort((a: MeasureRecord, b: MeasureRecord) => a.time - b.time);
}

export function dayBuckets(records: MeasureRecord[], days: number, nowMs: number): TrendPoint[] {
  const now: Date = new Date(nowMs);
  const todayStart: number = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  const out: TrendPoint[] = [];
  for (let d = days - 1; d >= 0; d--) {
    const start: number = todayStart - d * DAY_MS;
    const end: number = start + DAY_MS;
    const recs: MeasureRecord[] = records.filter((r: MeasureRecord) => r.time >= start && r.time < end);
    const idx: number = days - 1 - d;
    let label: string = '';
    if (days === 7) {
      label = WEEKDAY_CN[new Date(start).getDay()];
    } else if (days === 30 && (idx % 6 === 0 || idx === days - 1)) {
      const dt: Date = new Date(start);
      label = `${dt.getMonth() + 1}/${dt.getDate()}`;
    }
    out.push(new TrendPoint(label, averageDb(recs), recs.length > 0));
  }
  return out;
}

export function trendSeries(records: MeasureRecord[], range: number, nowMs: number): TrendPoint[] {
  if (range === HISTORY_RANGE_7_DAYS) {
    return dayBuckets(records, 7, nowMs);
  }
  if (range === HISTORY_RANGE_30_DAYS) {
    return dayBuckets(records, 30, nowMs);
  }
  const list: MeasureRecord[] = todayRecords(records, nowMs);
  const out: TrendPoint[] = [];
  const n: number = list.length;
  for (let i = 0; i < n; i++) {
    const r: MeasureRecord = list[i];
    const d: Date = new Date(r.time);
    let label: string = '';
    if (i === 0 || i === n - 1 || i === Math.floor(n / 2)) {
      label = d.getHours().toString().padStart(2, '0') + ':' + d.getMinutes().toString().padStart(2, '0');
    }
    out.push(new TrendPoint(label, r.avg, true));
  }
  return out;
}
