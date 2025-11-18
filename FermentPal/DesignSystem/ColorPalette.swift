//
//  ColorPalette.swift
//  FermentPal
//
//  统一色彩系统 - iOS原生体验
//  支持暗色模式，色盲友好
//

import SwiftUI

// MARK: - 色彩系统

extension Color {
    // MARK: - 品牌色

    /// 主品牌色 - 绿色（生命、发酵、成长）
    static let brandPrimary = Color.green

    /// 辅助品牌色 - 蓝色（智能、科技）
    static let brandSecondary = Color.blue

    // MARK: - 语义色

    /// 成功色
    static let success = Color.green

    /// 警告色
    static let warning = Color.orange

    /// 危险色
    static let danger = Color.red

    /// 信息色
    static let info = Color.blue

    // MARK: - 状态色

    /// 进行中状态
    static let statusActive = Color.green

    /// 已完成状态
    static let statusCompleted = Color.blue

    /// 已废弃状态
    static let statusDiscarded = Color.gray

    // MARK: - 功能色

    /// 投料绿色
    static let feedingGreen = Color.green.opacity(0.8)

    /// 环境蓝色
    static let environmentBlue = Color.cyan

    /// 推荐橙色
    static let recommendationOrange = Color.orange

    /// 智能紫色
    static let intelligentPurple = Color.purple

    // MARK: - 背景色（自适应暗色模式）

    /// 卡片背景
    static let cardBackground = Color(.systemBackground)

    /// 列表背景
    static let listBackground = Color(.systemGroupedBackground)

    /// 次级背景
    static let secondaryBackground = Color(.secondarySystemGroupedBackground)

    // MARK: - 文本色

    /// 主要文本
    static let textPrimary = Color.primary

    /// 次要文本
    static let textSecondary = Color.secondary

    /// 三级文本
    static let textTertiary = Color(.tertiaryLabel)

    // MARK: - 分隔线色

    /// 分隔线
    static let separator = Color(.separator)
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

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            // 品牌色
            colorSection(
                title: "品牌色",
                colors: [
                    ("主色", Color.brandPrimary),
                    ("辅助色", Color.brandSecondary)
                ]
            )

            // 语义色
            colorSection(
                title: "语义色",
                colors: [
                    ("成功", Color.success),
                    ("警告", Color.warning),
                    ("危险", Color.danger),
                    ("信息", Color.info)
                ]
            )

            // 状态色
            colorSection(
                title: "状态色",
                colors: [
                    ("进行中", Color.statusActive),
                    ("已完成", Color.statusCompleted),
                    ("已废弃", Color.statusDiscarded)
                ]
            )
        }
        .padding()
    }
}

private func colorSection(title: String, colors: [(String, Color)]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text(title)
            .font(.headline)

        HStack(spacing: 12) {
            ForEach(colors, id: \.0) { name, color in
                VStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
