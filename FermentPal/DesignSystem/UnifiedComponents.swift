//
//  UnifiedComponents.swift
//  FermentPal
//
//  统一UI组件库 - iOS原生体验
//  卡片、按钮、徽章等通用组件
//

import SwiftUI

// MARK: - 统一卡片组件

struct UnifiedCard<Content: View>: View {
    let content: Content
    var padding: EdgeInsets = .card
    var cornerRadius: CGFloat = .cardCornerRadius
    var showShadow: Bool = true
    var backgroundColor: Color = .cardBackground

    init(
        padding: EdgeInsets = .card,
        cornerRadius: CGFloat = .cardCornerRadius,
        showShadow: Bool = true,
        backgroundColor: Color = .cardBackground,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.showShadow = showShadow
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: showShadow ? Color.black.opacity(0.05) : .clear,
                radius: .cardShadowRadius,
                x: 0,
                y: 2
            )
    }
}

// MARK: - 主要按钮样式

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .buttonPaddingVertical)
            .padding(.horizontal, .buttonPaddingHorizontal)
            .background(isEnabled ? Color.brandPrimary : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: .buttonCornerRadius))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .shadow(
                color: configuration.isPressed ? .clear : Color.black.opacity(0.1),
                radius: .buttonShadowRadius,
                x: 0,
                y: 1
            )
    }
}

// MARK: - 次要按钮样式

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.button)
            .foregroundStyle(isEnabled ? Color.brandPrimary : Color.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .buttonPaddingVertical)
            .padding(.horizontal, .buttonPaddingHorizontal)
            .background(
                isEnabled ?
                Color.brandPrimary.opacity(0.1) :
                    Color.gray.opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: .buttonCornerRadius))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 小按钮样式

struct SmallButtonStyle: ButtonStyle {
    let color: Color

    init(color: Color = .brandPrimary) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonSmall)
            .foregroundStyle(.white)
            .padding(.vertical, .buttonSmallPaddingVertical)
            .padding(.horizontal, .buttonSmallPaddingHorizontal)
            .background(color)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 浮动操作按钮（FAB）

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 56
    var color: Color = .brandPrimary

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(color)
                .clipShape(Circle())
                .shadow(
                    color: .black.opacity(0.2),
                    radius: .fabShadowRadius,
                    x: 0,
                    y: 4
                )
        }
    }
}

// MARK: - 增强的徽章组件

struct EnhancedBadge: View {
    let text: String
    var icon: String? = nil
    var color: Color = .brandPrimary
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small
        case medium
        case large

        var font: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .badge
            case .large: return .label
            }
        }

        var paddingVertical: CGFloat {
            switch self {
            case .small: return .badgeSmallPaddingVertical
            case .medium: return .badgePaddingVertical
            case .large: return .badgePaddingVertical + 2
            }
        }

        var paddingHorizontal: CGFloat {
            switch self {
            case .small: return .badgeSmallPaddingHorizontal
            case .medium: return .badgePaddingHorizontal
            case .large: return .badgePaddingHorizontal + 4
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(size.font)
            }
            Text(text)
                .font(size.font)
                .fontWeight(.medium)
        }
        .padding(.horizontal, size.paddingHorizontal)
        .padding(.vertical, size.paddingVertical)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

// MARK: - 空状态组件

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: .spacingXL) {
            // 图标
            Image(systemName: icon)
                .font(.system(size: .iconSizeXXLarge * 1.5))
                .foregroundStyle(.gray.opacity(0.5))

            // 文本
            VStack(spacing: .spacingSM) {
                Text(title)
                    .font(.appTitle3)
                    .foregroundStyle(Color.textPrimary)

                Text(message)
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .bodyTextStyle()
            }

            // 行动按钮
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 280)
            }
        }
        .padding(.horizontal, .pageMargin * 2)
        .padding(.vertical, .spacing4XL)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 加载指示器

struct LoadingView: View {
    var message: String = "加载中..."

    var body: some View {
        VStack(spacing: .spacingLG) {
            ProgressView()
                .scaleEffect(1.2)

            Text(message)
                .font(.callout)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, .spacing4XL)
    }
}

// MARK: - 骨架屏加载

struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.2),
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.2)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - 分隔器

struct AppDivider: View {
    var color: Color = .separator
    var height: CGFloat = 1

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
    }
}

// MARK: - 标签组件

struct LabelView: View {
    let icon: String
    let text: String
    var iconColor: Color = .brandPrimary

    var body: some View {
        HStack(spacing: .spacingSM) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.footnote)

            Text(text)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
        }
    }
}

// MARK: - 预览

#Preview("卡片") {
    ScrollView {
        VStack(spacing: .spacingLG) {
            UnifiedCard {
                VStack(alignment: .leading, spacing: .spacingMD) {
                    Text("标准卡片")
                        .font(.cardTitle)
                    Text("这是一个使用统一卡片组件的示例")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            UnifiedCard(showShadow: false) {
                Text("无阴影卡片")
                    .font(.cardTitle)
            }
        }
        .padding()
    }
}

#Preview("按钮") {
    VStack(spacing: .spacingLG) {
        Button("主要按钮") {}
            .buttonStyle(PrimaryButtonStyle())

        Button("次要按钮") {}
            .buttonStyle(SecondaryButtonStyle())

        Button("禁用按钮") {}
            .buttonStyle(PrimaryButtonStyle())
            .disabled(true)

        HStack {
            Button("小按钮") {}
                .buttonStyle(SmallButtonStyle())

            Button("危险按钮") {}
                .buttonStyle(SmallButtonStyle(color: .danger))
        }

        FloatingActionButton(icon: "plus") {}
    }
    .padding()
}

#Preview("徽章") {
    VStack(spacing: .spacingLG) {
        EnhancedBadge(text: "进行中", color: .success)

        EnhancedBadge(text: "3条建议", icon: "lightbulb.fill", color: .info)

        EnhancedBadge(
            text: "重要",
            icon: "exclamationmark.triangle.fill",
            color: .danger,
            size: .small
        )

        EnhancedBadge(text: "大徽章", icon: "star.fill", color: .warning, size: .large)
    }
    .padding()
}

#Preview("空状态") {
    EmptyState(
        icon: "tray",
        title: "暂无数据",
        message: "开始创建你的第一个发酵罐",
        actionTitle: "创建发酵罐"
    ) {
        print("Create")
    }
}

#Preview("加载") {
    LoadingView(message: "正在加载数据...")
}
