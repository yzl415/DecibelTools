/**
 * 设计令牌系统：集中管理两套主题（亮色·极简高级 / 暗色·暗黑质感）。
 * 组件通过 @StorageProp('themeDark') 订阅，调用 getTheme(isDark) 取色。
 */

export class AppTheme {
  isDark: boolean;
  bg: string;            // 页面背景
  surface: string;       // 卡片背景
  surfaceAlt: string;    // 次级表面（输入框 / chip / 分段控件）
  navBar: string;        // 底部 Tab 背景
  textPrimary: string;   // 主文字
  textSecondary: string; // 次文字
  textTertiary: string;  // 最弱文字 / 占位
  accent: string;        // 品牌强调色
  accentText: string;    // 强调色上的文字（按钮内）
  divider: string;       // 分隔线
  success: string;
  danger: string;
  warn: string;
  // 卡片描边 / 阴影：亮色用极淡描边+微阴影，暗色用描边、无阴影
  cardBorder: string;
  shadowColor: string;
  shadowRadius: number;
  // 进度槽底色
  track: string;
  // 强调色的浅色填充（用于 chip / emoji 圆底兜底）
  accentSoft: string;

  constructor(isDark: boolean, bg: string, surface: string, surfaceAlt: string,
    navBar: string, textPrimary: string, textSecondary: string, textTertiary: string,
    accent: string, accentText: string, divider: string, success: string,
    danger: string, warn: string, cardBorder: string, shadowColor: string,
    shadowRadius: number, track: string, accentSoft: string) {
    this.isDark = isDark;
    this.bg = bg;
    this.surface = surface;
    this.surfaceAlt = surfaceAlt;
    this.navBar = navBar;
    this.textPrimary = textPrimary;
    this.textSecondary = textSecondary;
    this.textTertiary = textTertiary;
    this.accent = accent;
    this.accentText = accentText;
    this.divider = divider;
    this.success = success;
    this.danger = danger;
    this.warn = warn;
    this.cardBorder = cardBorder;
    this.shadowColor = shadowColor;
    this.shadowRadius = shadowRadius;
    this.track = track;
    this.accentSoft = accentSoft;
  }
}

/** 亮色主题：暖中性背景 + 近黑文字 + 沉稳靛蓝，发丝描边、极微阴影 */
export const LIGHT_THEME: AppTheme = new AppTheme(
  false,
  '#F5F6F8',   // bg
  '#FFFFFF',   // surface
  '#EEF0F4',   // surfaceAlt
  '#FFFFFFF2', // navBar (近白略透)
  '#17181C',   // textPrimary
  '#6B7280',   // textSecondary
  '#A1A7B3',   // textTertiary
  '#4F46E5',   // accent (靛蓝)
  '#FFFFFF',   // accentText
  '#ECEDF1',   // divider
  '#16A34A',   // success
  '#E5484D',   // danger
  '#F59E0B',   // warn
  '#00000000', // cardBorder (亮色不描边)
  '#14000000', // shadowColor (极淡)
  10,          // shadowRadius
  '#E6E8EE',   // track
  '#EEEDFB'    // accentSoft
);

/** 暗色主题：近黑分层表面 + 高亮靛蓝 + 描边分层，无阴影 */
export const DARK_THEME: AppTheme = new AppTheme(
  true,
  '#0E0F13',   // bg
  '#1A1C22',   // surface
  '#24262E',   // surfaceAlt
  '#15161B',   // navBar
  '#F2F3F5',   // textPrimary
  '#9CA3AF',   // textSecondary
  '#6B7280',   // textTertiary
  '#6D78FF',   // accent (高亮靛蓝)
  '#FFFFFF',   // accentText
  '#2A2D36',   // divider
  '#34D399',   // success
  '#F87171',   // danger
  '#FBBF24',   // warn
  '#2A2D36',   // cardBorder (描边分层)
  '#00000000', // shadowColor (暗色不投影)
  0,           // shadowRadius
  '#2A2D36',   // track
  '#2A2740'    // accentSoft
);

/** 根据是否暗色返回对应主题 */
export function getTheme(isDark: boolean): AppTheme {
  return isDark ? DARK_THEME : LIGHT_THEME;
}

/** 在某色上叠加透明度后缀（hex 8 位），alpha 为 00~FF 的两位十六进制 */
export function withAlpha(color: string, alphaHex: string): string {
  return color + alphaHex;
}
