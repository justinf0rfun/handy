import SwiftUI

// MARK: - 兼容层（Phase 0 迁移期）
// 旧代码仍然可以继续使用 HandyColor / HandyMetric
// 新代码请直接使用 HandyVisualTokens 和 HandyMotionTokens

// 颜色系统已迁移至新规范
enum HandyColor {
    static let appBackground     = HandyVisualTokens.Colors.appBackground
    static let panel             = HandyVisualTokens.Colors.panelBackground
    static let card              = HandyVisualTokens.Colors.cardBackground
    static let cardHover         = HandyVisualTokens.Colors.cardHoverBackground
    static let control           = HandyVisualTokens.Colors.controlBackground
    static let primaryText       = HandyVisualTokens.Colors.textPrimary
    static let secondaryText     = HandyVisualTokens.Colors.textSecondary
    static let mutedText         = HandyVisualTokens.Colors.textMuted
    static let accent            = HandyVisualTokens.Colors.accentPrimary
    static let line              = HandyVisualTokens.Colors.borderSubtle
}

// 尺寸与圆角系统（部分已对齐新规范，逐步收敛）
enum HandyMetric {
    static let preferredPanelSize = CGSize(width: 640, height: 600)
    static let panelRadius        = HandyVisualTokens.Radius.panel
    static let cardRadius         = HandyVisualTokens.Radius.card
    static let mediaRadius        = HandyVisualTokens.Radius.media
    static let searchRadius       = HandyVisualTokens.Radius.search
    static let controlRadius      = HandyVisualTokens.Radius.control

    // 以下尺寸仍保留旧值（Phase 1 再统一检视）
    static let cardWidth          = CGFloat(228)
    static let cardHeight         = CGFloat(216)
    static let shortCardHeight    = CGFloat(216)
}

// Font 工具暂时保留（后续可考虑迁移到 Typography 系统）
extension Font {
    static func handyDisplay(size: CGFloat, weight: Weight = .regular) -> Font {
        .custom("Avenir Next", size: size).weight(weight)
    }

    static func handyMono(size: CGFloat) -> Font {
        .system(size: size, design: .monospaced)
    }
}

