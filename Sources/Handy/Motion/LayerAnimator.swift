import QuartzCore
import Foundation

// MARK: - Layer Animator
// Phase 0：专门用于 CALayer 的动画工具
// 为 Phase 1（卡片动画下沉）做准备

public enum LayerAnimator {

    // MARK: - Basic Animation

    /// 使用 CABasicAnimation 驱动属性动画
    public static func animate(
        layer: CALayer,
        keyPath: String,
        from: Any? = nil,
        to: Any,
        duration: TimeInterval,
        timingFunction: CAMediaTimingFunction = .init(name: .easeInEaseOut),
        fillMode: CAMediaTimingFillMode = .both,
        removeOnCompletion: Bool = true
    ) {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = duration
        animation.timingFunction = timingFunction
        animation.fillMode = fillMode
        animation.isRemovedOnCompletion = removeOnCompletion

        setModelValue(to, for: keyPath, on: layer)
        layer.add(animation, forKey: keyPath)
    }

    // MARK: - Spring Animation (推荐用于高级感)

    /// 使用 CASpringAnimation（更接近物理的弹性）
    public static func animateSpring(
        layer: CALayer,
        keyPath: String,
        from: Any? = nil,
        to: Any,
        config: HandyMotionTokens.SpringConfig,
        mass: CGFloat = 1.0,
        stiffness: CGFloat = 300,
        damping: CGFloat = 30,
        initialVelocity: CGFloat = 0,
        fillMode: CAMediaTimingFillMode = .both,
        removeOnCompletion: Bool = true
    ) {
        let animation = CASpringAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = to
        animation.mass = mass
        animation.stiffness = springStiffness(for: config, fallback: stiffness)
        animation.damping = springDamping(for: config, fallback: damping)
        animation.initialVelocity = initialVelocity

        animation.fillMode = fillMode
        animation.isRemovedOnCompletion = removeOnCompletion
        animation.duration = animation.settlingDuration

        setModelValue(to, for: keyPath, on: layer)
        layer.add(animation, forKey: keyPath)
    }

    /// 使用我们预定义的 SpringConfig 做弹性动画（推荐）
    public static func animateSpring(
        layer: CALayer,
        keyPath: String,
        to: Any,
        using config: HandyMotionTokens.SpringConfig
    ) {
        animateSpring(
            layer: layer,
            keyPath: keyPath,
            to: to,
            config: config
        )
    }

    // MARK: - Convenience Methods

    public static func animateOpacity(
        layer: CALayer,
        from: Float? = nil,
        to: Float,
        duration: TimeInterval,
        timingFunction: CAMediaTimingFunction = .init(name: .easeInEaseOut)
    ) {
        animate(
            layer: layer,
            keyPath: "opacity",
            from: from,
            to: to,
            duration: duration,
            timingFunction: timingFunction
        )
    }

    public static func animateScale(
        layer: CALayer,
        from: CGFloat? = nil,
        to: CGFloat,
        duration: TimeInterval,
        timingFunction: CAMediaTimingFunction = .init(name: .easeInEaseOut)
    ) {
        let fromTransform = from.map { CATransform3DMakeScale($0, $0, 1) }
        let toTransform = CATransform3DMakeScale(to, to, 1)

        animate(
            layer: layer,
            keyPath: "transform",
            from: fromTransform,
            to: toTransform,
            duration: duration,
            timingFunction: timingFunction
        )
    }

    public static func animatePosition(
        layer: CALayer,
        from: CGPoint? = nil,
        to: CGPoint,
        duration: TimeInterval,
        timingFunction: CAMediaTimingFunction = .init(name: .easeInEaseOut)
    ) {
        animate(
            layer: layer,
            keyPath: "position",
            from: from,
            to: to,
            duration: duration,
            timingFunction: timingFunction
        )
    }

    // MARK: - Stagger for Layers

    /// 对一组 Layer 做 stagger 动画（常用于卡片列表）
    @MainActor
    public static func stagger(
        layers: [CALayer],
        keyPath: String,
        toValues: [Any],
        baseDelay: TimeInterval = HandyMotionTokens.Stagger.base,
        duration: TimeInterval,
        timingFunction: CAMediaTimingFunction = .init(name: .easeOut)
    ) {
        guard layers.count == toValues.count else { return }

        for (index, layer) in layers.enumerated() {
            let delay = baseDelay * Double(index)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { @MainActor in
                animate(
                    layer: layer,
                    keyPath: keyPath,
                    to: toValues[index],
                    duration: duration,
                    timingFunction: timingFunction
                )
            }
        }
    }

    /// 使用 Spring 的 stagger（推荐用于卡片 hover/出现效果）
    @MainActor
    public static func staggerSpring(
        layers: [CALayer],
        keyPath: String,
        toValues: [Any],
        using config: HandyMotionTokens.SpringConfig,
        baseDelay: TimeInterval = HandyMotionTokens.Stagger.card
    ) {
        guard layers.count == toValues.count else { return }

        for (index, layer) in layers.enumerated() {
            let delay = baseDelay * Double(index)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { @MainActor in
                animateSpring(
                    layer: layer,
                    keyPath: keyPath,
                    to: toValues[index],
                    using: config
                )
            }
        }
    }

    private static func setModelValue(_ value: Any, for keyPath: String, on layer: CALayer) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        switch keyPath {
        case "transform":
            if let transform = value as? CATransform3D {
                layer.transform = transform
            } else {
                layer.setValue(value, forKeyPath: keyPath)
            }
        case "opacity":
            if let opacity = value as? Float {
                layer.opacity = opacity
            } else {
                layer.setValue(value, forKeyPath: keyPath)
            }
        case "position":
            if let position = value as? CGPoint {
                layer.position = position
            } else {
                layer.setValue(value, forKeyPath: keyPath)
            }
        default:
            layer.setValue(value, forKeyPath: keyPath)
        }
        CATransaction.commit()
    }

    private static func springStiffness(for config: HandyMotionTokens.SpringConfig, fallback: CGFloat) -> CGFloat {
        guard config.response > 0 else { return fallback }
        let angularFrequency = (2.0 * Double.pi) / config.response
        return CGFloat(angularFrequency * angularFrequency)
    }

    private static func springDamping(for config: HandyMotionTokens.SpringConfig, fallback: CGFloat) -> CGFloat {
        guard config.response > 0 else { return fallback }
        let angularFrequency = (2.0 * Double.pi) / config.response
        return CGFloat(2.0 * config.dampingFraction * angularFrequency)
    }
}
