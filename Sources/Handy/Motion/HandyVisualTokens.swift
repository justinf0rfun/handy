import SwiftUI

// MARK: - Handy Visual Tokens
// Phase 0 视觉基础
// 与 handy-premium-design-system.md 保持一致
// 这是视觉系统的唯一真相来源

public enum HandyVisualTokens {

    // MARK: - Colors

    public enum Colors {
        // 背景
        public static let appBackground     = Color(hex: "#0E1010")
        public static let panelBackground   = Color(hex: "#141617")
        public static let cardBackground    = Color(hex: "#1A1C1E")
        public static let cardHoverBackground = Color(hex: "#1F2124")
        public static let controlBackground = Color.white.opacity(0.055)

        // 文字
        public static let textPrimary       = Color(hex: "#F4F1EA")
        public static let textSecondary     = Color(hex: "#F4F1EA").opacity(0.72)
        public static let textMuted         = Color(hex: "#F4F1EA").opacity(0.45)
        public static let textCode          = Color(hex: "#C5C5C5")

        // 强调色：只作为暖白金属感点缀，不承担大面积填充
        public static let accentPrimary     = Color(hex: "#D8CBB3")
        public static let accentSubtle      = Color(hex: "#D8CBB3").opacity(0.14)

        // 边框
        public static let borderSubtle      = Color.white.opacity(0.10)
        public static let borderActive      = Color(hex: "#D8CBB3").opacity(0.26)

        // 阴影基色
        public static let shadowBase        = Color.black
    }

    // MARK: - Shadows

    public enum Shadows {
        /// 面板主阴影
        @MainActor public static let panel = ShadowStyle(
            color: Colors.shadowBase.opacity(0.58),
            radius: 55,
            x: 0,
            y: 42
        )

        /// 卡片默认状态
        @MainActor public static let cardDefault = ShadowStyle(
            color: Colors.shadowBase.opacity(0.32),
            radius: 20,
            x: 0,
            y: 8
        )

        /// 卡片 Hover 状态
        @MainActor public static let cardHover = ShadowStyle(
            color: Colors.shadowBase.opacity(0.38),
            radius: 28,
            x: 0,
            y: 12
        )

        /// 卡片选中状态
        @MainActor public static let cardSelected = ShadowStyle(
            color: Colors.shadowBase.opacity(0.45),
            radius: 32,
            x: 0,
            y: 14
        )

        /// 卡片激活状态（键盘焦点等）
        @MainActor public static let cardActive = ShadowStyle(
            color: Colors.shadowBase.opacity(0.40),
            radius: 24,
            x: 0,
            y: 10
        )
    }

    // MARK: - Radius

    public enum Radius {
        public static let panel: CGFloat = 28
        public static let card: CGFloat = 20
        public static let media: CGFloat = 14
        public static let search: CGFloat = 20
        public static let pill: CGFloat = 999
        public static let control: CGFloat = 12
    }

    // MARK: - Typography (轻量起步)

    public enum Typography {
        /// 主标题（Handy）
        public static let titleSize: CGFloat = 42
        public static let titleWeight: Font.Weight = .semibold

        /// 卡片标题
        public static let cardTitleSize: CGFloat = 17
        public static let cardTitleWeight: Font.Weight = .bold

        /// 卡片正文
        public static let cardBodySize: CGFloat = 13

        /// 代码预览
        public static let codePreviewSize: CGFloat = 11
    }
}

// MARK: - ShadowStyle Helper

public struct ShadowStyle: Sendable {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - Color Hex 扩展（临时放这里，后续可迁移）

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex.replacingOccurrences(of: "#", with: ""))
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
