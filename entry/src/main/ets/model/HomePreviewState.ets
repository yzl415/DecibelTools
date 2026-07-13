import { CompassSensor } from './CompassSensor';

export function shouldRunHomeLive(pageShown: boolean, tabIndex: number,
  showWelcome: boolean, measurementStarted: boolean): boolean {
  return pageShown && tabIndex === 0 && !showWelcome && measurementStarted;
}

export function hasLiveDb(liveActive: boolean, homeDb: number): boolean {
  return liveActive && homeDb > 0;
}

export function homeDbSummary(liveActive: boolean, homeDb: number): string {
  return hasLiveDb(liveActive, homeDb) ? homeDb.toString() + ' dB' : '--';
}

export function homeNoiseTitle(liveActive: boolean): string {
  return liveActive ? '环境噪音 · 实时' : '环境噪音 · 待测';
}

export function angleSummary(homeTilt: number): string {
  return homeTilt >= 0 ? homeTilt.toFixed(1) + '°' : '--';
}

export function compassSummary(homeHeading: number): string {
  return homeHeading >= 0
    ? CompassSensor.dirAbbr(homeHeading) + ' ' + Math.round(homeHeading).toString() + '°'
    : '--';
}
