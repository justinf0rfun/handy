import SwiftUI
import Foundation

// MARK: - Handy Motion Coordinator
// Phase 0 核心：动画编排器
// 负责统一调度、组合动画（sequence / stagger / parallel）
// 为后续下沉 CALayer 做准备

@MainActor
public final class MotionCoordinator {

    public static let shared = MotionCoordinator()

    private init() {}

    // MARK: - Basic Animation

    /// 执行一个 SwiftUI Animation
    public func animate(
        _ animation: Animation,
        body: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        withAnimation(animation) {
            body()
        }

        // 简单 completion（SwiftUI withAnimation 没有原生 completion，这里用延迟近似）
        if let completion {
            let duration = estimatedDuration(of: animation)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                completion()
            }
        }
    }

    /// 使用 Handy 预设 Spring 执行动画
    public func animate(
        using spring: HandyMotionTokens.SpringConfig,
        body: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        animate(spring.animation, body: body, completion: completion)
    }

    // MARK: - Sequence

    /// 按顺序执行多个动画块
    public func sequence(
        _ animations: [AnimationBlock],
        completion: (() -> Void)? = nil
    ) {
        guard !animations.isEmpty else {
            completion?()
            return
        }

        var remaining = animations

        func runNext() {
            guard let next = remaining.first else {
                completion?()
                return
            }
            remaining.removeFirst()

            withAnimation(next.animation) {
                next.body()
            }

            let duration = estimatedDuration(of: next.animation)

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                runNext()
            }
        }

        runNext()
    }

    // MARK: - Stagger

    /// 带 stagger 的动画（常用于列表/卡片）
    public func stagger(
        count: Int,
        baseDelay: Double = HandyMotionTokens.Stagger.base,
        animation: Animation,
        bodyForIndex: @escaping (Int) -> Void
    ) {
        for index in 0..<count {
            let delay = baseDelay * Double(index)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(animation) {
                    bodyForIndex(index)
                }
            }
        }
    }

    /// 使用预设 Spring 的 stagger
    public func stagger(
        count: Int,
        baseDelay: Double = HandyMotionTokens.Stagger.base,
        using spring: HandyMotionTokens.SpringConfig,
        bodyForIndex: @escaping (Int) -> Void
    ) {
        stagger(count: count, baseDelay: baseDelay, animation: spring.animation, bodyForIndex: bodyForIndex)
    }

    // MARK: - Parallel

    /// 同时执行多个动画（目前简单实现，后续可优化）
    public func parallel(_ blocks: [AnimationBlock]) {
        for block in blocks {
            withAnimation(block.animation) {
                block.body()
            }
        }
    }

    // MARK: - Helper

    private func estimatedDuration(of animation: Animation) -> Double {
        // SwiftUI 的 Animation 目前没有公开 duration，这里做个保守估算
        // 后续可以根据需要做更精确的实现
        return 0.4
    }
}

// MARK: - Animation Block

public struct AnimationBlock {
    public let animation: Animation
    public let body: () -> Void

    public init(animation: Animation, body: @escaping () -> Void) {
        self.animation = animation
        self.body = body
    }

    public static func spring(
        _ config: HandyMotionTokens.SpringConfig,
        body: @escaping () -> Void
    ) -> AnimationBlock {
        AnimationBlock(animation: config.animation, body: body)
    }
}