//
//  UnifiedComponents.swift
//  FermentPal
//
//  统一UI组件库 - iOS原生体验
//  卡片、按钮、徽章等通用组件
//

import SwiftUI

// MARK: - 统一卡片组件（扁平化）

struct UnifiedCard<Content: View>: View {
    let content: Content
    var padding: EdgeInsets = .card
    var cornerRadius: CGFloat = .cardCornerRadius
    var style: CardStyle = .bordered
    var backgroundColor: Color = .cardBackground

    enum CardStyle {
        case bordered        // 边框样式（扁平）
        case filled          // 填充样式
        case elevated        // 微阴影（保留少量阴影）
        case coloredBorder   // 彩色边框
    }

    init(
        padding: EdgeInsets = .card,
        cornerRadius: CGFloat = .cardCornerRadius,
        style: CardStyle = .bordered,
        backgroundColor: Color = .cardBackground,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.style = style
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .modifier(CardStyleModifier(style: style, cornerRadius: cornerRadius))
    }
}

// MARK: - 卡片样式修饰符

private struct CardStyleModifier: ViewModifier {
    let style: UnifiedCard<AnyView>.CardStyle
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        switch style {
        case .bordered:
            content
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.borderPrimary, lineWidth: 1)
                )

        case .filled:
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.surfaceLight)
                )

        case .elevated:
            content
                .shadow(
                    color: Color.black.opacity(0.04),
                    radius: 4,
                    x: 0,
                    y: 2
                )

        case .coloredBorder:
            content
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.brandPrimary, lineWidth: 2)
                )
        }
    }
}

// MARK: - 主要按钮样式（扁平化）

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .buttonPaddingVertical)
            .padding(.horizontal, .buttonPaddingHorizontal)
            .background(isEnabled ? Color.brandPrimary : Color.gray.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: .buttonCornerRadius))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - 次要按钮样式（扁平化 - 边框风格）

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.button)
            .foregroundStyle(isEnabled ? Color.brandPrimary : Color.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .buttonPaddingVertical)
            .padding(.horizontal, .buttonPaddingHorizontal)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: .buttonCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: .buttonCornerRadius)
                    .stroke(isEnabled ? Color.brandPrimary : Color.borderPrimary, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
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

// MARK: - 浮动操作按钮（扁平化）

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
                    color: color.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
    }
}

// MARK: - 增强的徽章组件（扁平化）

struct EnhancedBadge: View {
    let text: String
    var icon: String? = nil
    var color: Color = .brandPrimary
    var size: BadgeSize = .medium
    var style: BadgeStyle = .filled

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

    enum BadgeStyle {
        case filled     // 填充样式
        case outlined   // 边框样式（扁平）
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
        .background(backgroundForStyle)
        .foregroundStyle(foregroundForStyle)
        .clipShape(Capsule())
        .overlay(overlayForStyle)
    }

    private var backgroundForStyle: Color {
        switch style {
        case .filled:
            return color.opacity(0.15)
        case .outlined:
            return Color.clear
        }
    }

    private var foregroundForStyle: Color {
        color
    }

    private var overlayForStyle: some View {
        Group {
            if style == .outlined {
                Capsule()
                    .stroke(color, lineWidth: 1.5)
            }
        }
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

#Preview("卡片 - 扁平化") {
    ScrollView {
        VStack(spacing: .spacingLG) {
            // 边框样式（默认扁平）
            UnifiedCard(style: .bordered) {
                VStack(alignment: .leading, spacing: .spacingMD) {
                    Text("扁平卡片 - 边框样式")
                        .font(.cardTitle)
                    Text("简约扁平设计，使用边框区分层次")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            // 彩色边框
            UnifiedCard(style: .coloredBorder) {
                VStack(alignment: .leading, spacing: .spacingMD) {
                    Text("扁平卡片 - 彩色边框")
                        .font(.cardTitle)
                    Text("使用品牌色边框突出重点")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            // 填充样式
            UnifiedCard(style: .filled) {
                VStack(alignment: .leading, spacing: .spacingMD) {
                    Text("扁平卡片 - 填充样式")
                        .font(.cardTitle)
                    Text("使用背景色区分")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            // 微阴影样式（保留少量阴影）
            UnifiedCard(style: .elevated) {
                VStack(alignment: .leading, spacing: .spacingMD) {
                    Text("微阴影卡片")
                        .font(.cardTitle)
                    Text("保留轻微阴影效果")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding()
        .background(Color.listBackground)
    }
}

#Preview("按钮 - 扁平化") {
    VStack(spacing: .spacingLG) {
        Button("主要按钮 - 扁平填充") {}
            .buttonStyle(PrimaryButtonStyle())

        Button("次要按钮 - 边框样式") {}
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
    .background(Color.listBackground)
}

#Preview("徽章 - 扁平化") {
    VStack(spacing: .spacingLG) {
        // 填充样式（默认）
        HStack(spacing: 12) {
            EnhancedBadge(text: "进行中", color: .success, style: .filled)
            EnhancedBadge(text: "已完成", color: .info, style: .filled)
        }

        // 边框样式（扁平）
        HStack(spacing: 12) {
            EnhancedBadge(text: "进行中", color: .success, style: .outlined)
            EnhancedBadge(text: "已完成", color: .info, style: .outlined)
        }

        EnhancedBadge(text: "3条建议", icon: "lightbulb.fill", color: .info)

        EnhancedBadge(
            text: "重要",
            icon: "exclamationmark.triangle.fill",
            color: .danger,
            size: .small,
            style: .outlined
        )

        EnhancedBadge(text: "大徽章", icon: "star.fill", color: .warning, size: .large)
    }
    .padding()
    .background(Color.listBackground)
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
