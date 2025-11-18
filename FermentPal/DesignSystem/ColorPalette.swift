//
//  ColorPalette.swift
//  FermentPal
//
//  统一色彩系统 - 简约扁平设计
//  支持暗色模式，响应式适配
//

import SwiftUI

// MARK: - 色彩系统

extension Color {
    // MARK: - 品牌色（简约扁平）

    /// 主品牌色 - 柔和绿色（生命、发酵、成长）
    static let brandPrimary = Color(red: 0.4, green: 0.76, blue: 0.65)  // #66C2A5 薄荷绿

    /// 辅助品牌色 - 琥珀色（发酵、温暖）
    static let brandSecondary = Color(red: 0.99, green: 0.71, blue: 0.38)  // #FCB562 琥珀色

    /// 强调色 - 深青色（专业、科技）
    static let brandAccent = Color(red: 0.27, green: 0.58, blue: 0.76)  // #4594C2 深青色

    // MARK: - 语义色（扁平化）

    /// 成功色 - 柔和绿
    static let success = Color(red: 0.4, green: 0.76, blue: 0.65)

    /// 警告色 - 柔和橙
    static let warning = Color(red: 0.99, green: 0.71, blue: 0.38)

    /// 危险色 - 柔和红
    static let danger = Color(red: 0.95, green: 0.45, blue: 0.45)  // #F27272

    /// 信息色 - 柔和蓝
    static let info = Color(red: 0.4, green: 0.68, blue: 0.92)  // #66AEE9

    // MARK: - 状态色（扁平化）

    /// 进行中状态 - 活力绿
    static let statusActive = Color(red: 0.4, green: 0.76, blue: 0.65)

    /// 已完成状态 - 沉稳蓝
    static let statusCompleted = Color(red: 0.4, green: 0.68, blue: 0.92)

    /// 已废弃状态 - 中性灰
    static let statusDiscarded = Color(red: 0.62, green: 0.64, blue: 0.68)  // #9EA3AD

    // MARK: - 功能色（扁平化）

    /// 投料色 - 新鲜绿
    static let feedingGreen = Color(red: 0.4, green: 0.76, blue: 0.65)

    /// 环境色 - 清新蓝
    static let environmentBlue = Color(red: 0.4, green: 0.68, blue: 0.92)

    /// 推荐色 - 温暖橙
    static let recommendationOrange = Color(red: 0.99, green: 0.71, blue: 0.38)

    /// 智能色 - 优雅紫
    static let intelligentPurple = Color(red: 0.67, green: 0.55, blue: 0.85)  // #AB8DD9

    // MARK: - 背景色（自适应暗色模式 + 扁平化）

    /// 卡片背景 - 纯白/纯黑
    static let cardBackground = Color(.systemBackground)

    /// 列表背景 - 浅灰/深灰
    static let listBackground = Color(.systemGroupedBackground)

    /// 次级背景 - 微灰
    static let secondaryBackground = Color(.secondarySystemGroupedBackground)

    /// 浅色背景 - 用于卡片内的次级区域
    static let surfaceLight = Color(light: Color(red: 0.98, green: 0.98, blue: 0.98),
                                     dark: Color(red: 0.15, green: 0.15, blue: 0.15))

    // MARK: - 文本色（优化对比度）

    /// 主要文本
    static let textPrimary = Color.primary

    /// 次要文本
    static let textSecondary = Color.secondary

    /// 三级文本
    static let textTertiary = Color(.tertiaryLabel)

    // MARK: - 边框色（扁平设计关键）

    /// 主要边框 - 浅灰
    static let borderPrimary = Color(light: Color(red: 0.9, green: 0.9, blue: 0.9),
                                     dark: Color(red: 0.25, green: 0.25, blue: 0.25))

    /// 次要边框 - 极浅灰
    static let borderSecondary = Color(light: Color(red: 0.95, green: 0.95, blue: 0.95),
                                       dark: Color(red: 0.2, green: 0.2, blue: 0.2))

    /// 分隔线
    static let separator = Color(.separator)
}

// MARK: - 辅助方法

extension Color {
    /// 支持明暗模式的颜色初始化
    static func color(light: Color, dark: Color) -> Color {
        Color(light: light, dark: dark)
    }

    /// 适配明暗模式的颜色
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        self = light
        #endif
    }
}

// MARK: - 色彩辅助方法

extension Color {
    /// 根据状态获取颜色
    static func forStatus(_ status: String) -> Color {
        switch status {
        case "active": return .statusActive
        case "completed": return .statusCompleted
        case "discarded": return .statusDiscarded
        default: return .gray
        }
    }

    /// 根据优先级获取颜色
    static func forPriority(_ priority: RecommendationPriority) -> Color {
        switch priority {
        case .high: return .danger
        case .medium: return .warning
        case .low: return .info
        }
    }
}

// MARK: - 预览

#Preview("色彩系统") {
    ScrollView {
        VStack(spacing: 32) {
            // 品牌色
            VStack(alignment: .leading, spacing: 16) {
                Text("品牌色 - 简约扁平").font(.headline)
                HStack(spacing: 16) {
                    colorSwatch("薄荷绿", Color.brandPrimary)
                    colorSwatch("琥珀色", Color.brandSecondary)
                    colorSwatch("深青色", Color.brandAccent)
                }
            }

            // 语义色
            VStack(alignment: .leading, spacing: 16) {
                Text("语义色").font(.headline)
                HStack(spacing: 16) {
                    colorSwatch("成功", Color.success)
                    colorSwatch("警告", Color.warning)
                    colorSwatch("危险", Color.danger)
                    colorSwatch("信息", Color.info)
                }
            }

            // 状态色
            VStack(alignment: .leading, spacing: 16) {
                Text("状态色").font(.headline)
                HStack(spacing: 16) {
                    colorSwatch("进行中", Color.statusActive)
                    colorSwatch("已完成", Color.statusCompleted)
                    colorSwatch("已废弃", Color.statusDiscarded)
                }
            }

            // 边框示例
            VStack(alignment: .leading, spacing: 16) {
                Text("扁平化卡片示例").font(.headline)

                // 有边框的卡片
                VStack(spacing: 12) {
                    Text("扁平卡片（边框）")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderPrimary, lineWidth: 1)
                        )

                    Text("彩色边框卡片")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.brandPrimary, lineWidth: 2)
                        )
                }
            }
        }
        .padding()
        .background(Color.listBackground)
    }
}

private func colorSwatch(_ name: String, _ color: Color) -> some View {
    VStack(spacing: 8) {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 60, height: 60)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
        Text(name)
            .font(.caption)
            .foregroundStyle(Color.textSecondary)
    }
}

