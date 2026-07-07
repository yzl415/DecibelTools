# Claude 后续整改任务清单

## 背景

参考设计稿：

- `/Users/joey/Downloads/声活-终稿-暗色.dc-2.html`

当前工程已经完成大部分视觉和交互改造：首页实时卡、分贝仪预览/记录拆分、历史趋势曲线、计时器复位按钮、指南针状态文案等主体能力已经接近设计稿。

本文件只列审计后仍未闭环、或无法通过工程验收的事项。请按优先级逐项处理，严格保持现有 ArkTS 架构与 `Theme.ets` 令牌，不扩大重构范围。

对照来源：

- `docs/claude-design-gap-tasks.md`
- 本轮代码审计结果

## 总体要求

- 只修改本清单涉及的文件和必要的测试文件。
- 新增测试必须按 AAA 结构组织，测试名使用英文。
- 不使用 `sleep()` 或硬编码等待；异步/定时逻辑请用可控时钟、同步状态或可测试抽象。
- UI 测试只查稳定语义或公开状态，不验证像素位置、样式细节或深层组件树。
- 亮色 / 暗色都要验收，不允许只改一套颜色。
- 完成后执行构建/静态检查/测试，并在结果中说明未能执行的原因。

## P0：测试与验收闭环

### 1. 补齐核心逻辑测试

涉及文件：

- `entry/src/test/LocalUnit.test.ets`
- `entry/src/test/List.test.ets`
- `entry/src/ohosTest/ets/test/Ability.test.ets`
- `entry/src/ohosTest/ets/test/List.test.ets`
- 必要时新增可测试的 model/helper 文件

当前问题：

- 以上测试文件目前只有占位注释，没有真实测试。
- 设计稿改造涉及实时预览、记录测量、历史趋势聚合、计时器复位、频闪状态等行为，但没有测试覆盖。

建议实现：

- 抽出纯逻辑 helper，优先测试公共函数/公开状态，不测试私有方法。
- 至少覆盖：
  - 首页：实时源启停策略；麦克风不可用时不混用“最近”数据；角度/指南针摘要无数据时显示占位。
  - 分贝仪：预览态不累计统计、不保存记录；开始测量后累计 min/avg/peak；停止后按条件保存；切换 dB(A)/dB(C)、FAST/SLOW 同时影响预览和记录测量。
  - 历史：今天/7 天/30 天聚合；空数据、单条数据、多条数据；峰值时间选择；最近 7 天 x 轴桶顺序稳定。
  - 计时器：开始、停止、计次、运行中复位会停止并清零。
  - 手电筒：常亮/频闪/SOS 模式切换互不污染；频闪频率更新不依赖真实等待。

验收标准：

- 测试文件不再是占位。
- 测试名为英文，例如 `test_preview_does_not_persist_record`。
- 测试内部无 `if/else`、`switch`。
- 不使用 `sleep()`、固定超时等待或真实时间推进。

### 2. 清理构建与静态检查 warning

涉及文件：

- `entry/src/main/ets/model/SettingsStore.ets`
- `entry/src/main/ets/model/RecordStore.ets`
- `entry/src/main/ets/components/HomeView.ets`
- `entry/src/main/ets/components/SettingsView.ets`
- `entry/src/main/ets/pages/Index.ets`
- `entry/src/main/ets/pages/DecibelPage.ets`
- `entry/src/main/ets/pages/AnglePage.ets`
- `entry/src/main/ets/pages/CompassPage.ets`
- `entry/src/main/ets/pages/RulerPage.ets`
- `entry/src/main/ets/pages/FlashlightPage.ets`
- `entry/src/main/ets/pages/TimerPage.ets`
- `entry/src/main/ets/pages/CalibratePage.ets`
- `entry/src/main/ets/pages/Privacy.ets`

当前问题：

- `hvigorw PackageApp` 的 ArkTS 编译阶段存在多条 warning：
  - `Function may throw exceptions. Special handling is required.`
  - `pushUrl` / `back` / `AlertDialog.show` / `getContext` deprecated。
- 任务要求静态检查零 warning 零 error，当前未达标。
- 本机 `PackageHap` 阶段还因缺少 Java Runtime 失败，需要安装/配置 JDK 后再完整验证。

建议实现：

- 对会抛异常的 preferences 操作加明确 `try/catch`，失败时保持安全默认值或静默降级。
- 将 deprecated router/API 按当前 HarmonyOS 推荐 API 替换；优先查项目 SDK 文档或 DevEco 提示，不猜接口。
- 若某些 deprecated warning 受 SDK 版本限制无法消除，在结果中逐条说明原因和风险。

验收标准：

- ArkTS 编译阶段 warning 清零，或对无法清零项给出明确技术原因。
- `PackageApp` 在配置好 JDK 后能成功完成。

## P1：设计稿差异决策

### 3. 详情页右上角图标与设计稿不一致

涉及文件：

- `entry/src/main/ets/pages/DecibelPage.ets`
- `entry/src/main/ets/pages/AnglePage.ets`
- `entry/src/main/ets/pages/CompassPage.ets`
- `entry/src/main/ets/pages/RulerPage.ets`
- `entry/src/main/ets/pages/FlashlightPage.ets`
- `entry/src/main/ets/pages/TimerPage.ets`
- 可能涉及 `entry/src/main/ets/pages/Index.ets`

设计稿要求：

- 分贝仪右上角是圆形信息图标，或与其他详情页保持统一留白/信息规则。

当前问题：

- 当前右上角是历史列表入口，点击后设置 `requestTab = 1` 并返回首页历史 Tab。
- 其他详情页大多已经是信息图标或功能区，但仍需统一核对：信息、单位切换、留白、历史入口不能混用而无说明。

建议实现：

- 若严格贴设计稿：改为信息图标，并显示简短说明弹窗；历史入口从底部 Tab 进入。
- 若保留历史入口：请补充差异说明文档，明确这是产品决策，不再视为设计未完成项。

验收标准：

- 分贝仪、角度仪、指南针、手电筒、计时器等详情页导航栏右侧语义统一。
- 不出现同一位置有的表示信息、有的表示历史而无说明的情况。

### 4. 手电筒亮度控制与设计稿存在降级

涉及文件：

- `entry/src/main/ets/pages/FlashlightPage.ets`
- `entry/src/main/ets/model/TorchController.ets`

设计稿要求：

- 常亮模式显示 `亮度 80%`，滑块可用。
- 频闪和 SOS 是模式切换。

当前实现：

- 常亮/SOS 显示 `亮度 / 不可调`，滑块禁用。
- 频闪模式下滑块用于频率控制。

建议实现：

- 查阅 HarmonyOS Camera/Torch 官方 API 或本项目 SDK 类型，确认是否支持 torch 强度。
- 若支持：在 `TorchController` 增加亮度设置，并让常亮模式滑块真实生效。
- 若不支持：保留当前诚实降级，但补充注释/说明文档，明确不是遗漏，而是系统能力限制。

验收标准：

- UI 不表现成“可调但实际无效”。
- 常亮、频闪、SOS 的 slider 含义清晰且状态互不污染。
- 对频闪逻辑补测试，不能使用真实等待。

### 5. 设置页超出设计稿范围，需产品确认

涉及文件：

- `entry/src/main/ets/components/SettingsView.ets`

设计稿包含：

- 分贝仪：麦克风校准、默认计权、超标提醒。
- 通用：深色外观、单位、震动反馈。
- 页脚版本信息。

当前额外包含：

- 时间计权。
- 屏幕校准。
- 数据：清空测量历史。
- 关于：隐私政策。

建议实现：

- 不建议直接删除，因为这些涉及实际产品能力和上架合规。
- 请明确产品决策：
  - 严格贴设计稿：删除/移动额外项。
  - 保留实际能力：保持现状，但确保视觉密度、行高、图标、分隔线与设计稿一致，并补充差异说明。

验收标准：

- 设置项保留与否有明确结论。
- 保留项不破坏设计稿节奏。

### 6. 指南针精度文案需确认是否严格贴稿

涉及文件：

- `entry/src/main/ets/pages/CompassPage.ets`
- `entry/src/main/ets/model/CompassSensor.ets`

原 gap 清单要求：

- 状态卡左侧为 `磁偏角已校正`。
- 状态卡右侧为 `精度 ±2°`。
- 无传感器数据时错误态明确，不能显示虚假的“已校正”。

当前实现：

- 已接入 `CompassSensor` accuracy，左侧会按精度显示 `磁偏角已校正` / `建议校准` / `请校准`。
- 右侧高精度时显示 `精度 ±2°`，中等精度时显示 `精度 ±5°`，低精度时显示 `精度较低`。

建议实现：

- 若严格贴设计稿：高/中精度都按设计稿主文案展示 `磁偏角已校正` 与 `精度 ±2°`，低精度/无数据进入明确错误或校准态。
- 若保留真实精度：补充差异说明，明确这是比设计稿更真实的状态反馈，不再作为未完成项。

验收标准：

- 设计稿主文案和真实传感器状态之间有明确产品取舍。
- 无传感器数据时不显示 `磁偏角已校正`。
- 增加精度状态映射测试，测试名使用英文。

## P2：细节质量

### 7. 首页实时预览权限体验

涉及文件：

- `entry/src/main/ets/pages/Index.ets`
- `entry/src/main/ets/components/HomeView.ets`

当前实现：

- 首页工具 Tab 前台运行实时麦克风预览。
- 麦克风拒绝后首页显示 `--`。

建议确认：

- 首页打开即请求麦克风是否符合产品预期。
- 若不希望首页主动弹权限，可将首页文案改为“最近”语义，或只在用户进入分贝仪后启动实时预览。

验收标准：

- “实时”与实际行为一致，不混用“最近”数据。
- 权限拒绝态文案明确且不误导。

### 8. 设计稿已完成项需保留防回归说明

涉及文件：

- `entry/src/main/ets/components/HomeView.ets`
- `entry/src/main/ets/pages/DecibelPage.ets`
- `entry/src/main/ets/components/HistoryView.ets`
- `entry/src/main/ets/pages/TimerPage.ets`

当前状态：

- 原 gap 清单中的首页实时卡、分贝仪待测实时读数、历史趋势曲线、计时器右侧复位按钮，代码层面已基本完成。

剩余风险：

- 这些项的验收依赖测试和构建 warning 清零，目前仍没有真实测试兜底。
- Claude 后续修 warning 或抽 helper 时，不能回退这些已经对齐设计稿的视觉/行为。

验收标准：

- 保留首页 `环境噪音 · 实时`、`LIVE`、实时 dB、迷你频谱、等级条指示点、工具行摘要值。
- 保留分贝仪待测态实时读数、等级胶囊和 `开始测量` 记录语义。
- 保留历史折线/面积趋势图、y 轴 90/60/30、x 轴标签、峰值时间。
- 保留计时器三按钮布局：`计次` / 中间开始停止 / `复位`。

## 验证命令参考

当前本机可用命令：

```bash
rtk proxy env DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw PackageApp --no-daemon
```

注意：

- 审计时该命令能进入 ArkTS 编译，但存在 warning。
- `PackageHap` 阶段因本机缺少 Java Runtime 失败。请先配置 JDK 后再跑完整构建。
- 如果项目配置了集成测试、ohosTest、真机测试或 mock 硬件测试标记，请在单元测试后额外执行对应测试集。
- 如果项目新增了可运行测试命令，请一并写入 README 或本文件，并执行全量测试。
