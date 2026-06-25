/**
 * 设计令牌系统 · 仪表风格（方向 A）。
 * 亮色 / 暗色两套，组件通过 @StorageProp('themeDark') 订阅，getTheme(isDark) 取色。
 *
 * 主强调色 #00D68F；噪音等级令牌全局统一：
 *   安静 #22C55E · 适中 #84CC16 · 一般 #EAB308 · 较吵 #F59E0B · 吵闹 #EF4444。
 * 数字读数使用等宽字体（mono）。
 */

/** 全局噪音等级色阶（两套主题共用） */
export const LEVEL_QUIET: string = '#22C55E';    // 安静
export const LEVEL_MODERATE: string = '#84CC16'; // 适中
export const LEVEL_NORMAL: string = '#EAB308';   // 一般
export const LEVEL_LOUD: string = '#F59E0B';     // 较吵
export const LEVEL_NOISY: string = '#EF4444';    // 吵闹

/** 工具主题色（图标 / 局部强调，两套主题共用） */
export const TOOL_GREEN: string = '#00D68F';
export const TOOL_INDIGO: string = '#6D78FF';
export const TOOL_PURPLE: string = '#C084FC';
export const TOOL_ORANGE: string = '#F59E0B';

/**
 * 等宽字体族（数字读数）— JetBrains Mono，于 EntryAbility 注册。
 * MONO 常规、MONO_B 加粗（注册为独立 family，避免 faux-bold 失真）。
 * 数字读数一律用这两个，贴合声级计仪表质感。
 */
export const MONO: string = 'JBMono';
export const MONO_B: string = 'JBMonoB';

export class AppTheme {
  isDark: boolean = false;
  bg: string = '#EBECF0';            // 页面 / 手机屏背景
  surface: string = '#FFFFFF';       // 卡片背景
  surfaceAlt: string = '#F0F1F4';    // 次级表面（chip / 分段控件 / 图标按钮）
  navBar: string = '#FFFFFFF2';      // 底部 Tab 背景
  textPrimary: string = '#1A1C20';   // 主文字
  textSecondary: string = '#6B7280'; // 次文字
  textTertiary: string = '#98A0AD';  // 最弱文字 / 占位 / 标签
  accent: string = '#00D68F';        // 品牌强调色
  accentStrong: string = '#00B377';  // 强调色在浅底上的文字色（保证对比度）
  accentText: string = '#0B0C10';    // 强调色填充上的文字色
  divider: string = '#E7E8EC';       // 分隔线 / 卡片描边
  success: string = '#16A34A';
  danger: string = '#EF4444';
  warn: string = '#F59E0B';
  cardBorder: string = '#E7E8EC';    // 卡片描边
  shadowColor: string = '#14000000'; // 卡片阴影色（暗色为透明）
  shadowRadius: number = 10;
  track: string = '#E7E8EC';         // 进度槽底色
  accentSoft: string = '#E6F6EC';    // 强调色浅填充（图标圆底）
  // 仪表盘表面渐变两端（径向）
  gaugeOuter: string = '#FFFFFF';    // 外圈径向渐变亮端（偏上高光）
  gaugeEdge: string = '#D5D8E0';     // 外圈径向渐变暗端（边缘），制造凸起金属圈
  gaugeHighlight: string = '#FFFFFF'; // 表盘顶部内高光（叠加白，弱透明）
  gaugeInner: string = '#E4E6EC';
  gaugeCore: string = '#EBECF0';     // 表盘中心遮罩色（=屏背景）
  // 工具图标圆底（浅色 tint）
  tintGreen: string = '#E6F6EC';
  tintIndigo: string = '#EBEDFE';
  tintPurple: string = '#F3EAFB';
  tintOrange: string = '#FDF3E2';
  // 状态条 / 刻度文字
  tick: string = '#17181C';          // 表盘主刻度
  statusFg: string = '#E6E8EC';      // 状态栏图标（亮色下为深色 -> 用 textPrimary 覆盖）
}

/** 亮色主题：浅灰蓝表面 + 近黑文字 + 翠绿强调，发丝描边 + 微阴影 */
export const LIGHT_THEME: AppTheme = new AppTheme();

/** 暗色主题：近黑分层表面 + 翠绿强调 + 描边分层，无阴影 */
export const DARK_THEME: AppTheme = (() => {
  const t: AppTheme = new AppTheme();
  t.isDark = true;
  t.bg = '#0B0C10';
  t.surface = '#13151B';
  t.surfaceAlt = '#15171D';
  t.navBar = '#0B0C10F2';
  t.textPrimary = '#F2F3F5';
  t.textSecondary = '#9CA3AF';
  t.textTertiary = '#5B6470';
  t.accent = '#00D68F';
  t.accentStrong = '#00D68F';
  t.accentText = '#0B0C10';
  t.divider = '#232831';
  t.success = '#22C55E';
  t.danger = '#FF6B6B';
  t.warn = '#F59E0B';
  t.cardBorder = '#232831';
  t.shadowColor = '#00000000';
  t.shadowRadius = 0;
  t.track = '#232831';
  t.accentSoft = '#16201E';
  t.gaugeOuter = '#1A1D24';
  t.gaugeEdge = '#0E1014';
  t.gaugeHighlight = '#FFFFFF';
  t.gaugeInner = '#0E1014';
  t.gaugeCore = '#0B0C10';
  t.tintGreen = '#16201E';
  t.tintIndigo = '#1A1E2A';
  t.tintPurple = '#251E2A';
  t.tintOrange = '#26221A';
  t.tick = '#E6E8EC';
  t.statusFg = '#E6E8EC';
  return t;
})();

/** 根据是否暗色返回对应主题 */
export function getTheme(isDark: boolean): AppTheme {
  return isDark ? DARK_THEME : LIGHT_THEME;
}

/** 在某色上叠加透明度（hex 8 位 #AARRGGBB）。alpha 为两位十六进制 00~FF */
export function withAlpha(color: string, alphaHex: string): string {
  return '#' + alphaHex + color.substring(1);
}

/**
 * 噪音分贝 -> 等级色。阈值与设计稿一致：
 * <40 安静 · <55 适中 · <70 一般 · <85 较吵 · 否则 吵闹。
 */
export function levelColor(db: number): string {
  if (db < 40) {
    return LEVEL_QUIET;
  } else if (db < 55) {
    return LEVEL_MODERATE;
  } else if (db < 70) {
    return LEVEL_NORMAL;
  } else if (db < 85) {
    return LEVEL_LOUD;
  }
  return LEVEL_NOISY;
}

/** 噪音分贝 -> 等级中文标签（短） */
export function levelLabel(db: number): string {
  if (db < 40) {
    return '安静';
  } else if (db < 55) {
    return '适中';
  } else if (db < 70) {
    return '一般';
  } else if (db < 85) {
    return '较吵';
  }
  return '吵闹';
}

/** 噪音分贝 -> 等级描述（长，用于状态胶囊） */
export function levelDesc(db: number): string {
  if (db < 40) {
    return '安静 · 适合休息';
  } else if (db < 55) {
    return '适中 · 安静环境';
  } else if (db < 70) {
    return '一般 · 相当于正常对话';
  } else if (db < 85) {
    return '较吵 · 相当于繁忙街道';
  }
  return '吵闹 · 注意听力保护';
}
