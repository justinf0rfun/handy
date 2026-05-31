# Handy Premium Design System
## Engineer-Focused Visual & Motion Language (Raycast / Warp / Arc 调性)

**版本**: v1.0  
**日期**: 2026-06  
**目的**: 本文档是 Handy 视觉与动效的**重构级规范**，用于指导从当前实现升级到真正工程师向高端专业工具的体验。目标是达到 Raycast、Warp、Arc 这类产品在工程师心中的高级感，而非消费级漂亮工具风格。

---

## 1. 核心定位与设计原则

Handy 不是一个“漂亮的剪贴板管理器”，而是一个**给 AI-native 工程师使用的精准上下文召唤与组织工具**。

### 核心气质（必须严格遵守）
- **Quiet Power**：安静、有力、精确、克制
- **Professional Clarity**：专业、清晰、尊重智力
- **Responsive Precision**：极致响应感与确定感（不是花哨动画）
- **Technical Elegance**：有技术感，但绝不冰冷或幼稚

**禁止出现的感觉**：
- 消费级漂亮卡片风格（Supaste 类柔和阴影、大面积金色、甜美感）
- 过度装饰的渐变与高光
- 为了好看而做的多余动画

**必须追求的感觉**：
- Raycast 的极致键盘流畅 + 干净利落
- Warp 的现代专业细节与反馈质量
- Arc 的空间感与材料克制使用

---

## 2. 视觉系统（Visual Tokens）

### 2.1 颜色系统

```swift
// 基础色板（严格克制）
Background.App          = #0F1112
Background.Panel        = #141617          // 主面板，极深且干净
Background.Card         = #1A1C1E          // 卡片底色，比面板略亮
Background.CardHover    = #1F2124
Background.Control      = rgba(255,255,255,0.06)

Text.Primary            = #F4F1EA          // 米白色，温暖但不黄
Text.Secondary          = rgba(244,241,234,0.72)
Text.Muted              = rgba(244,241,234,0.45)
Text.Code               = #C5C5C5

Accent.Primary          = #C9A66B          // 工程师向金色（比当前更低饱和、更克制）
Accent.Subtle           = rgba(201,166,107,0.18)  // 仅用于极轻强调

Border.Subtle           = rgba(255,255,255,0.08)
Border.Active           = rgba(201,166,107,0.35)  // 选中态只用极淡描边
Shadow.Strong           = rgba(0,0,0,0.55)
```

**使用规则**：
- 金色（Accent）**大幅降低使用面积**。只允许出现在：
  - 主要 CTA（Compose / Copy）
  - 当前激活的卡片极细边框
  - 极少数关键状态反馈
- 大部分选中状态用**阴影加深 + 背景微亮 + 极淡边框**实现，禁止粗金框。

### 2.2 阴影系统（比当前实现更硬、更功能化）

```swift
Shadow.Panel            = 0 42px 110px rgba(0,0,0,0.58)
Shadow.Card.Default     = 0 8px 20px rgba(0,0,0,0.32)
Shadow.Card.Hover       = 0 12px 28px rgba(0,0,0,0.38)
Shadow.Card.Selected    = 0 14px 32px rgba(0,0,0,0.45)
Shadow.Card.Active      = 0 10px 24px rgba(0,0,0,0.40)
```

阴影原则：
- 更少、更硬、更具方向性（接近 Raycast/Warp 的感觉）
- Hover 和 Selected 主要通过**阴影变化 + 背景微调**建立层级，而不是靠边框粗细

### 2.3 圆角系统

```swift
Radius.Panel            = 28pt
Radius.Card             = 20pt
Radius.Media            = 14pt
Radius.Search           = 16pt
Radius.Pill             = 999
Radius.Control          = 12pt
```

### 2.4 排版

- 主标题（Handy）：42pt / 720 weight（大屏），短屏降到 32pt
- 卡片标题：17pt / 700 weight
- 卡片正文：13pt / 400，行高 1.45
- 代码预览：11-12pt，JetBrains Mono 或 SF Mono，行高 1.55
- 强调色文字保持低饱和

---

## 3. Motion 系统（Motion Language）

这是本次重构**最核心**的部分。当前实现最大的问题就是动效“正确但没灵魂”。

### 3.1 基础曲线（严格对齐 Raycast/Warp 常用曲线）

```text
Ease.Out                = cubic-bezier(0.16, 1.0, 0.3, 1.0)     // 主要进入
Ease.In                 = cubic-bezier(0.4, 0.0, 0.6, 1.0)
Ease.Standard           = cubic-bezier(0.2, 0.0, 0.0, 1.0)
Spring.Snappy           = response: 0.28, damping: 0.82         // 卡片 hover、按钮反馈
Spring.Smooth           = response: 0.42, damping: 0.78         // 面板进入、内容 reveal
Spring.Precise          = response: 0.22, damping: 0.88         // 微调反馈
```

### 3.2 时长规范

| 行为                  | 推荐时长     | 曲线                  | 备注 |
|-----------------------|--------------|-----------------------|------|
| Panel Summon 进入     | 380-420ms    | Ease.Out + Spring     | 根层用 CASpringAnimation |
| Panel Exit            | 160-180ms    | Ease.In               | 更快退出 |
| Content Stagger Reveal| 40-48ms      | Ease.Out              | 每层递增 |
| Card Hover            | 140-160ms    | Spring.Snappy         | 媒体抬升 + 阴影变化分开 |
| Card Selection        | 180ms        | Spring.Smooth         | 脉冲可选项 |
| Peek 打开/关闭        | 200-220ms    | Spring.Smooth         | 带轻微 scale |
| Draft 出现            | 220-240ms    | Ease.Out              | y + opacity |
| Copy Feedback         | 160ms        | Spring.Snappy         | 按钮 scale + 文字变化 |
| Invalid Nudge         | 180ms        | Ease.Standard         | 左右晃动 3-4px |

**重要原则**：
- 所有 hover、selection、反馈动画**必须独立控制**，禁止用同一个 state 绑死多个元素的动画。
- 卡片媒体抬升、阴影变化、toolbar 出现必须是**三个独立动画**。

### 3.3 关键交互的 Motion 要求

**Summon（最重要）**：
- 根面板使用 `CASpringAnimation`（推荐 response 0.38, damping 0.78）
- 内容 reveal 分层 stagger，不能一次性全部出现
- 推荐：Search 先，Pills 延迟 50ms，Goal 再延迟，Cards 用 38ms stagger

**Card Hover**：
- Media：y -2pt + scale 1.015 + 轻微高光（独立 layer 驱动）
- Shadow：从 Default → Hover（更深、更锐利）
- Toolbar：opacity 0→1 + scale 0.96→1，anchor topTrailing
- 禁止整个卡片 scale 动画（会影响滚动容器）

**Selection 反馈**：
- 推荐从卡片向 tray 发送一个**极轻的脉冲**（可选，但能极大提升高级感）
- 选中卡片阴影明显加深 + 背景微亮

---

## 4. 关键组件改造要求

### 4.1 Panel Shell
- 背景处理从当前多层手动渐变，简化为**更干净的深色 + 极轻内高光**。
- 推荐使用 `NSVisualEffectView`（material: .menu 或 .popover）+ 极轻 tint overlay 的混合方式，减少“代码味”。

### 4.2 Context Cards（本次重构最高优先级）
这是目前视觉和动效差距最大的地方，必须重做。

**要求**：
- 媒体区域必须用独立 `CALayer` 驱动 hover 动画。
- 卡片整体不 scale，只做内部元素动画。
- 选中状态强烈建议用**阴影 + 背景 + 极细描边**三者结合，彻底放弃粗金框。
- Hover toolbar 必须真正“浮”在媒体上方，有清晰的 z 轴关系。

### 4.3 Peek & Draft
- 必须解决当前硬编码 offset 问题，改用基于 Geometry 的 overlay 定位。
- 打开和关闭都要有 spring 物理反馈。
- Peek 内部操作的反馈要极致精准（这对工程师用户非常重要）。

### 4.4 底部操作区
- 降低金色使用面积。
- “2 selected” 的视觉权重要明显低于 Intent 和 CTA。
- Compose/Copy 按钮的反馈要非常 crisp（这是最后一步操作，用户对这里最敏感）。

---

## 5. 技术实现路线（重构建议）

由于用户接受更底层实现，推荐以下分层策略：

**Layer 1（推荐重度使用）**：
- Panel 根层动画 + 卡片 hover 媒体动画 + 关键反馈 → **直接使用 CALayer + CASpringAnimation**
- 放弃在 SwiftUI 里硬做这些高要求动画

**Layer 2**：
- 静态布局、文字、简单状态 → 继续用 SwiftUI（效率更高）

**Layer 3**：
- 复杂焦点管理（FocusCoordinator）建议单独抽成一个对象，彻底减少对 `@FocusState` 的依赖。

**强烈建议**：本次重构至少把 **ContextCard 的 hover / selection / 媒体动画** 这一块下沉到 CALayer 驱动，否则很难达到 Raycast/Warp 级别的手感。

---

## 6. 重构优先级（推荐执行顺序）

**P0（必须先做，影响最大）**
1. Card Hover + Selection + Media 动画重构（下沉 CALayer）
2. 建立统一的 Motion Token + 动画协调器
3. 金色使用面积大幅收窄 + 视觉 token 替换

**P1（强烈建议）**
4. Panel Summon 动画从 SwiftUI 升级为 CASpringAnimation
5. Peek / Draft 定位方式重构（去魔法数字）
6. 清理所有 Task.sleep 抢 focus 逻辑，建立 FocusCoordinator

**P2**
7. 底部操作区视觉与反馈精调
8. 搜索、Pill 的微反馈补齐
9. 整体表面材料感收敛（减少手动渐变）

---

## 7. 与现有文档的关系

- 本文档**优先级高于** `prototype-to-native-spec.md` 中的视觉描述。
- 保留原型中已验证的**交互契约**（键盘流、Escape 分层、Peek focus trap 等），只升级视觉语言和动效质量。
- 保留边缘定位、注意力锚点等核心能力，但要让它们的视觉呈现也符合本系统的克制专业调性。

---

## 8. 交付要求（给实现者）

如果你负责本次重构，请在回复中明确：

1. 你是否完全认同本系统的调性定位？
2. 你计划先从 P0 的哪一块开始？
3. 在 Card 动画下沉 CALayer 这件事上，你是否需要我（或 Justin）提供更具体的代码结构示例？
4. 你对时间评估的看法（分阶段）。

---

**结束语**

Handy 的价值完全建立在“感觉”上。  
如果这次重构做不到 Raycast / Warp / Arc 在工程师心中的那个高级水准，那产品就失去了最核心的差异化。

这次不是小修小补，是**重构级改造**。请用对待严肃工程项目的态度来对待本规范。

---

*文档由 Grok 生成，供 Codex / 实现者使用。*