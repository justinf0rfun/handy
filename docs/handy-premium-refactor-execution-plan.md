# Handy Premium Refactor - Execution Plan

**版本**: v1.0  
**日期**: 2026-06  
**策略**: 顺序开发（Sequential Development）  
**目标受众**: Justin + Codex（或未来任何执行者）

---

## 1. 总体策略与原则

### 1.1 为什么选择顺序开发

本次重构属于**重构级**改造，核心目标是把视觉和交互高级感提升到与 Raycast、Warp、Arc 同等水准。

并行开发虽然理论上更快，但会带来以下高风险：
- Motion 系统和状态管理交叉极深，容易产生隐性冲突
- 动效手感高度依赖全局一致性，局部并行容易导致体验割裂
- 你作为非前端负责人，review 并行改动成本过高

**因此决定采用严格的顺序开发**：
- 每个阶段完成并验证后再进入下一个阶段
- 物理上避免代码冲突
- 通过高质量文档实现上下文传递

### 1.2 核心成功标准

本次重构成功的标志不是“功能没问题”，而是：

> **当用户（尤其是重度使用 Raycast / Warp / Arc 的工程师）实际使用 Handy 时，能明显感觉到“这个工具的手感和细节是同一个级别的”。**

具体表现为：
- 召唤那一刻的稳定与响应感
- 卡片 hover 与选择的物理反馈质量
- 整个操作流程的确定感和流畅度
- 整体视觉克制、专业、不廉价

---

## 2. 阶段划分（严格顺序）

本次重构共分为 **5 个顺序阶段**。

每个阶段必须满足「进入条件」才能开始，完成「退出条件」才能进入下一阶段。

### 阶段概览

| 阶段 | 名称 | 核心产出 | 主要风险 | 建议主导方 | 预计耗时参考 |
|------|------|----------|----------|------------|--------------|
| **Phase 0** | 基础建设 | Motion System + Visual Tokens + 动画协调框架 | 低 | Grok | 较短 |
| **Phase 1** | 卡片核心动画 | ContextCard 的 hover / selection / 媒体动画（下沉 CALayer） | 高 | Grok | 最长 |
| **Phase 2** | 面板与召唤动画 | Panel 根动画 + 内容 reveal 序列 + 边缘定位视觉增强 | 中高 | Grok | 中 |
| **Phase 3** | 复杂交互与焦点 | Peek、Draft、FocusCoordinator、定位重构 | 中 | Codex（Grok 提供接口） | 中 |
| **Phase 4** | 全局收尾与一致性 | 剩余组件打磨、反馈补齐、整体一致性验证 | 低 | Codex | 较短 |

**重要说明**：
- Phase 0 和 Phase 1 是本次重构的**最高风险、最高价值**两个阶段。
- 只有 Phase 1 手感验证通过后，才值得继续投入 Phase 2~4。

---

## 3. 各阶段详细规范

### Phase 0: 基础建设（Motion + Visual Foundation）

**目标**：
建立整个重构的“语言”和“基础设施”，让后续阶段有统一的规范可以遵守。

**进入条件**：
- `handy-premium-design-system.md` 已 review 通过

**核心工作内容**：
- 定义并实现 `HandyMotionSystem`（Token + 曲线 + Spring 配置 + 协调器）
- 实现可复用的动画原语（`animateSpring(...)`、`animateSequence(...)` 等）
- 完成 Visual Tokens 的 Swift 实现（颜色、阴影、圆角等）
- 建立动画调试辅助工具（可选但推荐）
- 输出 Phase 0 完成报告

**必须产出的文档**：
- 更新后的 `handy-premium-design-system.md`（补充实现细节）
- `Phase0-Completion-Report.md`（包含：已实现的 API 列表、示例代码、已知限制）

**退出条件（必须全部满足）**：
- Motion Token 可以在代码中实际使用
- 有至少一个简单示例能跑通（比如按钮反馈）
- Codex 能看懂如何在后续阶段使用这些原语

**主导方建议**：Grok

**风险**：低，但如果这个阶段做得马虎，后续所有阶段都会翻车。

---

### Phase 1: 卡片核心动画重构（最高优先级）

**目标**：
把 Context Card 的 hover、selection、媒体抬升、toolbar 出现等核心交互手感做到明显高级。

这是本次整个重构里**最重要**的一个阶段。

**进入条件**：
- Phase 0 完成并通过验证

**核心工作内容**：
- 重构 `ContextCardView`（或新建 `PremiumContextCard`）
- 媒体区域 hover 动画下沉到独立 `CALayer` 驱动
- 实现独立的 hover / selection / active 动画控制
- 按照设计系统调整阴影、边框、金色使用策略
- 实现从卡片到选中 tray 的轻微脉冲反馈（可选但建议尝试）
- 输出可运行的卡片 Demo 状态

**禁止事项**（重要）：
- 此阶段不要大规模修改 `PanelState`
- 不要动 Peek 和 Draft 的定位逻辑
- 不要做全局 token 替换（留到 Phase 4）

**必须产出的文档**：
- `Phase1-Completion-Report.md`
- 卡片动画调用示例
- 当前手感与目标的差距记录（诚实评估）

**退出条件**：
- 在实际运行中，卡片 hover 和 selection 的手感比当前版本有**明显提升**
- Justin 实际测试后确认“这个方向是对的”
- 手感可以作为后续阶段的参考基准

**主导方建议**：Grok 主导实现，Codex 协助集成与状态对接

**风险**：**最高**。这个阶段如果做不好，后面的所有努力价值都会大打折扣。

---

### Phase 2: 面板召唤与根动画

**目标**：
让 Handy 真正“召唤出来”的那一刻，拥有专业工具应有的稳定、快速、精准感。

**进入条件**：
- Phase 1 已完成且手感验证通过

**核心工作内容**：
- Panel 根层进入/退出动画从 SwiftUI 升级为 `CASpringAnimation`
- 实现分层的内容 reveal 序列（Search → Pills → Goal → Cards）
- 优化边缘定位时的视觉表现（Attention 锚点、Beam 的精致度）
- 保证动画过程中不出现布局跳动或闪烁

**必须产出的文档**：
- `Phase2-Completion-Report.md`
- Summon 动画参数与时序说明

**退出条件**：
- 召唤体验比当前版本有明显提升
- 在不同屏幕位置召唤时都保持稳定

**主导方建议**：Grok

---

### Phase 3: 复杂交互组件与焦点管理

**目标**：
解决 Peek、Draft、Focus 管理这些当前实现中比较脆弱的部分，并让它们符合新的高级感标准。

**进入条件**：
- Phase 2 完成

**核心工作内容**：
- 重构 Peek 和 Draft 的定位方式（去除魔法数字）
- 建立 `FocusCoordinator`，逐步减少对 `Task.sleep` 的依赖
- 按照新 Motion 系统实现 Peek 和 Draft 的打开/关闭/反馈动画
- 优化 Compose 流程中的状态反馈

**必须产出的文档**：
- `Phase3-Completion-Report.md`
- FocusCoordinator 的设计与使用说明

**主导方建议**：Codex 主导，Grok 提供 Motion 和 Focus 管理的接口支持

---

### Phase 4: 全局收尾与一致性打磨

**目标**：
把前面阶段建立的高级感真正铺满整个产品，避免“核心高级、边缘廉价”的割裂感。

**进入条件**：
- Phase 3 完成

**核心工作内容**：
- 剩余组件（Search、Pills、Goal、Footer 等）的视觉 token 替换与反馈补齐
- 全局微交互（pill 切换、搜索清空、invalid compose nudge 等）补齐
- 整体一致性审查
- 性能与 reduced-motion 适配检查

**必须产出的文档**：
- `Phase4-Completion-Report.md`
- 最终的视觉与动效一致性 checklist

**主导方建议**：Codex

---

## 4. 跨阶段通用规则

### 4.1 文档更新要求

每个阶段完成后，**必须**更新或产出以下内容，否则视为阶段未完成：

1. 更新 `handy-premium-design-system.md` 中与本阶段相关的部分
2. 产出本阶段的 `PhaseX-Completion-Report.md`
3. 在报告中明确写出「下一阶段的进入条件」
4. 记录本次阶段中发现的、需要未来回头的改进点

### 4.2 Git 与分支策略

- 每个阶段使用独立分支：`refactor/phase-0-foundation`、`refactor/phase-1-card-animation` 等
- 主分支（`main`）只在阶段完整验收通过后才合并
- 禁止跨阶段在同一分支上持续开发

### 4.3 阶段验收机制

每个阶段结束时，Justin 需要实际运行并给出明确反馈：
- “这个阶段手感方向正确，可以进入下一阶段”
- “这个阶段手感没达到预期，需要返工”

不要用“差不多”“可以了”这种模糊表述。

---

## 5. 风险与应对

| 风险 | 影响阶段 | 应对方式 |
|------|----------|----------|
| Phase 1 手感始终达不到预期 | 最高 | 允许在 Phase 1 多次小迭代，但不要无限拖延 |
| Motion System 设计过于复杂，后续难以维护 | Phase 0 | 在 Phase 0 结束时做一次简化评审 |
| 文档写得不够，Codex 接手时理解偏差 | 全阶段 | 每阶段报告必须包含“如何验证”和“已知坑” |
| 中途发现原有架构严重阻碍高级感实现 | Phase 1-2 | 允许在 Phase 2 结束后做一次架构调整决策 |

---

## 6. 下一步行动

1. Justin review 本文档和 `handy-premium-design-system.md`
2. 确认阶段划分是否合理
3. 决定是否启动 Phase 0（由 Grok 负责输出 Motion System 框架）
4. 建立阶段之间的文档模板（可选但推荐）

---

**附：推荐的阶段文档模板结构**

每个 `PhaseX-Completion-Report.md` 应包含：
- 本阶段目标回顾
- 实际完成内容
- 手感验证结果（含截图/录屏建议）
- 与设计系统的符合度
- 已知问题与技术债务
- 对下一阶段的具体建议
- 代码改动清单

---

*本文档是本次顺序重构的最高层执行计划。所有阶段工作都应以此为准。*