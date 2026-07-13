import { DEBUG } from 'BuildProfile';

/**
 * 模拟器测试开关。
 *
 * 模拟器没有麦克风 / 传感器 / 闪光灯，真实硬件采集不到数据，界面无法验证。
 * 将 ENABLE_DEBUG_HARDWARE_MOCK 置 true 后，DecibelMeter / AngleSensor / CompassSensor /
 * TorchController 会改用内置假数据驱动 UI，便于在模拟器上验证界面与上层逻辑
 * （等级配色、记录存储、计权/响应切换、频闪/SOS 控件状态等）。
 *
 * release 构建始终禁用模拟数据；真机 debug 调试前需将开关改为 false。
 */
const ENABLE_DEBUG_HARDWARE_MOCK: boolean = false;

export const MOCK_HARDWARE: boolean = DEBUG && ENABLE_DEBUG_HARDWARE_MOCK;
