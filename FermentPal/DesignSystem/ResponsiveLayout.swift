//
//  ResponsiveLayout.swift
//  FermentPal
//
//  响应式布局系统 - iPhone & iPad适配
//  简约扁平设计
//

import SwiftUI

// MARK: - 设备类型检测

enum DeviceType {
    case phone      // iPhone
    case pad        // iPad
    case compact    // iPhone小屏
    case regular    // iPad或iPhone横屏

    static var current: DeviceType {
        #if os(iOS)
        let idiom = UIDevice.current.userInterfaceIdiom
        switch idiom {
        case .phone:
            return .phone
        case .pad:
            return .pad
        default:
            return .phone
        }
        #else
        return .regular
        #endif
    }
}

// MARK: - 响应式布局配置

struct ResponsiveLayoutConfig {
    // 列数配置
    let columns: Int
    let spacing: CGFloat
    let padding: EdgeInsets

    // 最大宽度（用于iPad居中内容）
    let maxWidth: CGFloat?

    // iPhone配置
    static let phonePortrait = ResponsiveLayoutConfig(
        columns: 1,
        spacing: 12,
        padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        maxWidth: nil
    )

    // iPhone横屏配置
    static let phoneLandscape = ResponsiveLayoutConfig(
        columns: 2,
        spacing: 16,
        padding: EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20),
        maxWidth: nil
    )

    // iPad竖屏配置
    static let padPortrait = ResponsiveLayoutConfig(
        columns: 2,
        spacing: 20,
        padding: EdgeInsets(top: 24, leading: 32, bottom: 24, trailing: 32),
        maxWidth: 800
    )

    // iPad横屏配置
    static let padLandscape = ResponsiveLayoutConfig(
        columns: 3,
        spacing: 24,
        padding: EdgeInsets(top: 24, leading: 40, bottom: 24, trailing: 40),
        maxWidth: 1200
    )
}

// MARK: - 环境值扩展

private struct DeviceTypeKey: EnvironmentKey {
    static let defaultValue: DeviceType = .current
}

private struct ResponsiveLayoutKey: EnvironmentKey {
    static let defaultValue: ResponsiveLayoutConfig = .phonePortrait
}

extension EnvironmentValues {
    var deviceType: DeviceType {
        get { self[DeviceTypeKey.self] }
        set { self[DeviceTypeKey.self] = newValue }
    }

    var responsiveLayout: ResponsiveLayoutConfig {
        get { self[ResponsiveLayoutKey.self] }
        set { self[ResponsiveLayoutKey.self] = newValue }
    }
}

// MARK: - 响应式修饰符

struct ResponsiveLayoutModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    func body(content: Content) -> some View {
        content
            .environment(\.deviceType, DeviceType.current)
            .environment(\.responsiveLayout, layoutConfig)
    }

    private var layoutConfig: ResponsiveLayoutConfig {
        let deviceType = DeviceType.current

        switch deviceType {
        case .pad:
            return horizontalSizeClass == .regular ? .padLandscape : .padPortrait
        case .phone:
            return verticalSizeClass == .compact ? .phoneLandscape : .phonePortrait
        default:
            return .phonePortrait
        }
    }
}

extension View {
    /// 应用响应式布局
    func responsiveLayout() -> some View {
        modifier(ResponsiveLayoutModifier())
    }
}

// MARK: - 响应式网格

struct ResponsiveGrid<Content: View>: View {
    @Environment(\.responsiveLayout) var layout

    let content: Content
    let minItemWidth: CGFloat

    init(minItemWidth: CGFloat = 300, @ViewBuilder content: () -> Content) {
        self.minItemWidth = minItemWidth
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: gridColumns,
            spacing: layout.spacing
        ) {
            content
        }
        .padding(layout.padding)
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: layout.spacing), count: layout.columns)
    }
}

// MARK: - 响应式容器

struct ResponsiveContainer<Content: View>: View {
    @Environment(\.responsiveLayout) var layout

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Group {
            if let maxWidth = layout.maxWidth {
                content
                    .frame(maxWidth: maxWidth)
                    .frame(maxWidth: .infinity)
            } else {
                content
            }
        }
        .padding(layout.padding)
    }
}

// MARK: - 响应式间距

extension CGFloat {
    /// 响应式间距 - 根据设备自适应
    static func responsive(_ phone: CGFloat, _ pad: CGFloat) -> CGFloat {
        DeviceType.current == .pad ? pad : phone
    }

    /// 小间距 - 响应式
    static var spacingSmallResponsive: CGFloat {
        responsive(8, 12)
    }

    /// 中间距 - 响应式
    static var spacingMediumResponsive: CGFloat {
        responsive(12, 16)
    }

    /// 大间距 - 响应式
    static var spacingLargeResponsive: CGFloat {
        responsive(16, 24)
    }
}

// MARK: - 预览

#Preview("响应式布局 - iPhone") {
    ScrollView {
        ResponsiveGrid(minItemWidth: 150) {
            ForEach(0..<6) { i in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brandPrimary)
                    .frame(height: 100)
                    .overlay(
                        Text("项目 \(i+1)")
                            .foregroundStyle(.white)
                    )
            }
        }
    }
    .background(Color.listBackground)
    .responsiveLayout()
}

#Preview("响应式容器") {
    ResponsiveContainer {
        VStack(spacing: 20) {
            Text("响应式内容")
                .font(.title)

            Text("在iPad上会居中且有最大宽度\n在iPhone上会使用全宽")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.textSecondary)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color.brandPrimary)
                .frame(height: 200)
        }
    }
    .background(Color.listBackground)
    .responsiveLayout()
}
