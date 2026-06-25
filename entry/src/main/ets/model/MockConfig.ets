/**
 * 模拟器测试开关。
 *
 * 模拟器没有麦克风 / 传感器 / 闪光灯，真实硬件采集不到数据，界面无法验证。
 * 将 MOCK_HARDWARE 置 true 后，DecibelMeter / AngleSensor / CompassSensor /
 * TorchController 会改用内置假数据驱动 UI，便于在模拟器上验证界面与上层逻辑
 * （等级配色、记录存储、计权/响应切换、频闪/SOS 控件状态等）。
 *
 * ⚠️ 发布或真机调试前务必改回 false，否则会读到假数据。
 */
export const MOCK_HARDWARE: boolean = true;
