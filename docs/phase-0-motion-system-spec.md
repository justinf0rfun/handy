# Phase 0: Motion System & Visual Foundation — Implementation Spec

**版本**: v1.0  
**目标阶段**: Phase 0（基础建设）  
**负责人**: Grok（设计 + 核心输出）  
**执行者**: 后续由 Justin 决定合并方式  
**Codex 状态**: 已暂停此项目

---

## 1. Phase 0 总体目标

建立 Handy 整个重构的 **Motion 语言** 和 **Visual 基础设施**，让后面所有阶段都有一个统一、专业、可扩展的系统可以依赖。

**成功标准**：
- 有一个清晰、可直接使用的 `HandyMotion` 系统。
- Visual Tokens 已经落地成可维护的 Swift 代码。
- 后续阶段（尤其是 Phase 1 的卡片动画）能基于这个系统快速且一致地实现高级感。

---

## 2. 交付物清单（必须完成）

### 2.1 代码交付物

1. **Motion Token 系统**
   - 动画曲线（Ease 函数）
   - Spring 参数配置
   - 时长规范
   - Stagger 规则

2. **MotionCoordinator / Animation System**
   - 一个可复用的动画协调机制
   - 支持 sequence、stagger、parallel 等组合方式
   - 便于在 SwiftUI 和 CALayer 之间切换使用

3. **Visual Tokens 实现**
   - `HandyColor`、`HandyShadow`、`HandyRadius`、`HandyTypography` 等结构
   - 与 `handy-premium-design-system.md` 中的定义保持一致

4. **基础使用示例**
   - 至少提供 2-3 个简单可运行的示例（按钮反馈、简单卡片 hover 模拟 等），用于验证系统

### 2.2 文档交付物

- 更新 `handy-premium-design-system.md`（补充实际落地细节）
- 本阶段完成报告（`Phase0-Completion-Report.md`）

---

## 3. 推荐架构（供讨论）

### 3.1 整体分层建议

```
HandyMotion/
├── Tokens/
│   ├── MotionTokens.swift          // 曲线、Spring、时长
│   └── VisualTokens.swift          // 颜色、阴影、圆角
├── Core/
│   ├── Animation.swift             // 基础动画描述
│   ├── MotionCoordinator.swift     // 动画编排器
│   └── LayerAnimator.swift         // 针对 CALayer 的工具
└── Examples/
    └── MotionExamples.swift
```

### 3.2 关键设计原则

- **Token 是唯一真相**：所有动画参数必须来自 Token，避免硬编码。
- **支持两种驱动方式**：
  - SwiftUI Animation（快速场景）
  - CALayer + CAAnimation（Phase 1 卡片等高要求场景）
- **Coordinator 负责编排**，而不是让每个 View 自己写复杂动画逻辑。
- 保持相对轻量，不要过度工程化。

---

## 4. 第一步建议（立即开始）

我建议按以下顺序推进 Phase 0：

**Step 1（当前）**：确认本 Spec 的架构方向 + Token 定义优先级  
**Step 2**：先落地 `MotionTokens.swift` + `VisualTokens.swift`（最基础）  
**Step 3**：设计并实现 `MotionCoordinator` 的核心接口  
**Step 4**：实现 `LayerAnimator` 工具类（为 Phase 1 做准备）  
**Step 5**：写示例 + 完成报告

---

## 5. 风险与注意事项

- 不要在 Phase 0 就尝试把现有卡片全部重写（这是 Phase 1 的事）。
- 不要过度抽象动画系统，先做出“能用且好用”的版本。
- 所有 Spring 参数和曲线都要和 `handy-premium-design-system.md` 对齐。

---

## 6. 下一步行动

请 Justin 确认：

1. 这个整体方向是否可以开始？
2. 在 Token 定义上，你是否有特别强的偏好（比如 Spring 参数想更偏向哪个风格）？
3. 我是否可以现在开始输出 **MotionTokens.swift** 的第一版定义？

---

**一旦你确认，我会立刻开始输出具体代码结构和实现。**