import Foundation
import SwiftUI

// MARK: - Handy Motion Tokens
// Phase 0 基础：统一的动画语言
// 这个文件是整个 Motion 系统的唯一真相来源

public enum HandyMotionTokens {

    // MARK: - Easing Curves

    /// 主要进入曲线（推荐用于面板出现、内容进入）
    public static let easeOut = Animation.timingCurve(0.16, 1.0, 0.3, 1.0, duration: 1.0)

    /// 快速退出曲线
    public static let easeIn = Animation.timingCurve(0.4, 0.0, 0.6, 1.0, duration: 1.0)

    /// 标准线性感曲线
    public static let easeStandard = Animation.timingCurve(0.2, 0.0, 0.0, 1.0, duration: 1.0)

    // MARK: - Spring Configurations

    public struct SpringConfig: Sendable {
        public let response: Double
        public let dampingFraction: Double
        public let blendDuration: Double

        public init(response: Double, dampingFraction: Double, blendDuration: Double = 0.0) {
            self.response = response
            self.dampingFraction = dampingFraction
            self.blendDuration = blendDuration
        }

        /// 转换为 SwiftUI Animation
        public var animation: Animation {
            .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
        }
    }

    // MARK: - 推荐 Spring 预设（与设计系统对齐）

    /// 敏捷反馈（卡片 hover、按钮按下、小元素反馈）
    public static let springSnappy = SpringConfig(response: 0.28, dampingFraction: 0.82)

    /// 平稳大动效（面板进入、内容 reveal、Peek 打开）
    public static let springSmooth = SpringConfig(response: 0.42, dampingFraction: 0.78)

    /// 精确微调（Copy 反馈、Nudge、无效状态提示）
    public static let springPrecise = SpringConfig(response: 0.22, dampingFraction: 0.88)

    // MARK: - 常用时长规范（单位：秒）

    public enum Duration {
        public static let fast: Double = 0.16          // 微反馈
        public static let normal: Double = 0.22        // 常规反馈
        public static let medium: Double = 0.32        // 中等过渡
        public static let slow: Double = 0.42          // 重要进入（面板召唤等）
        public static let exit: Double = 0.18          // 退出动画（需更快）
    }

    // MARK: - Stagger 规则

    public enum Stagger {
        /// 内容分层 reveal 时的基础延迟
        public static let base: Double = 0.045

        /// 卡片 stagger 延迟
        public static let card: Double = 0.035

        /// 选中元素脉冲等较长的 stagger
        public static let long: Double = 0.06
    }
}

// MARK: - 便捷扩展

extension Animation {
    /// Handy 推荐的 Snappy Spring
    @MainActor public static var handySnappy: Animation {
        HandyMotionTokens.springSnappy.animation
    }

    /// Handy 推荐的 Smooth Spring
    @MainActor public static var handySmooth: Animation {
        HandyMotionTokens.springSmooth.animation
    }

    /// Handy 推荐的 Precise Spring
    @MainActor public static var handyPrecise: Animation {
        HandyMotionTokens.springPrecise.animation
    }
}