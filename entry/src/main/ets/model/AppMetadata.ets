import { bundleManager } from '@kit.AbilityKit';

export const APP_DISPLAY_NAME: string = '声活工具箱';

export function getAppVersionName(): string {
  try {
    return bundleManager.getBundleInfoForSelfSync(
      bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT).versionName;
  } catch (e) {
    return '--';
  }
}

export function formatVersionLabel(versionName: string): string {
  return `VERSION ${versionName}`;
}

export function formatToolboxVersionLabel(versionName: string): string {
  return `TOOLBOX · v${versionName}`;
}
