//
//  FermentationCard.swift
//  FermentPal
//
//  优化的发酵罐卡片组件 - iOS原生体验
//  应用所有Quick Wins优化
//

import SwiftUI
import SwiftData

// MARK: - 发酵罐卡片（优化版）

struct FermentationCard: View {
    let fermentation: Fermentation
    var recommendationCount: Int = 0
    var hasHighPriority: Bool = false

    var body: some View {
        UnifiedCard(style: .bordered) {  // 使用扁平边框样式
            VStack(alignment: .leading, spacing: .spacingMD) {
                // 头部：名称 + 徽章组
                HStack(alignment: .top) {
                    // 左侧：名称和元数据
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text(fermentation.name)
                            .font(.cardTitle)
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(2)

                        // 元数据行
                        HStack(spacing: .spacingMD) {
                            LabelView(
                                icon: "clock.fill",
                                text: "\(fermentation.durationDays)天",
                                iconColor: .brandSecondary
                            )

                            if fermentation.records.count > 0 {
                                LabelView(
                                    icon: "doc.text.fill",
                                    text: "\(fermentation.records.count)条",
                                    iconColor: .brandSecondary
                                )
                            }
                        }
                    }

                    Spacer(minLength: .spacingSM)

                    // 右侧：徽章组（垂直排列）
                    VStack(alignment: .trailing, spacing: .spacingSM) {
                        // 推荐徽章
                        if recommendationCount > 0 {
                            EnhancedBadge(
                                text: "\(recommendationCount)",
                                icon: hasHighPriority ? "exclamationmark.triangle.fill" : "lightbulb.fill",
                                color: hasHighPriority ? .danger : .info,
                                size: .small
                            )
                        }

                        // 状态徽章
                        EnhancedBadge(
                            text: fermentation.safeStatus.displayName,
                            color: Color.forStatus(fermentation.status),
                            size: .small
                        )
                    }
                }

                // 进度条（仅活跃批次）
                if fermentation.safeStatus == .active {
                    ProgressBar(
                        progress: min(Double(fermentation.durationDays) / 14.0, 1.0),
                        color: .brandPrimary
                    )
                }

                // 最后操作时间
                HStack {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.textTertiary)

                    Text("更新于 \(fermentation.updatedAt, style: .relative)")
                        .font(.caption2)
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
    }
}

// MARK: - 进度条组件

struct ProgressBar: View {
    let progress: Double
    var color: Color = .brandPrimary
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                Rectangle()
                    .fill(color.opacity(0.15))

                // 前景
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
    }
}

// MARK: - 紧凑卡片（用于次要列表）

struct CompactFermentationCard: View {
    let fermentation: Fermentation

    var body: some View {
        HStack(spacing: .spacingMD) {
            // 状态指示器
            Circle()
                .fill(Color.forStatus(fermentation.status))
                .frame(width: 8, height: 8)

            // 信息
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(fermentation.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text("\(fermentation.durationDays)天 · \(fermentation.records.count)条记录")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            // 箭头
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.vertical, .spacingSM)
    }
}

// MARK: - 预览

#Preview("标准卡片") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fermentation.self, configurations: config)

    let f1 = Fermentation(
        name: "苹果鲁邦 第6代",
        status: "active",
        createdAt: Date().addingTimeInterval(-86400 * 5)
    )
    container.mainContext.insert(f1)

    // 添加一些记录
    for i in 1...3 {
        let record = Record(
            fermentation: f1,
            content: "测试记录 \(i)",
            status: "normal",
            createdAt: Date().addingTimeInterval(-86400 * Double(i))
        )
        container.mainContext.insert(record)
    }

    return ScrollView {
        VStack(spacing: .cardSpacing) {
            FermentationCard(
                fermentation: f1,
                recommendationCount: 3,
                hasHighPriority: true
            )

            FermentationCard(
                fermentation: f1,
                recommendationCount: 1,
                hasHighPriority: false
            )

            FermentationCard(
                fermentation: f1,
                recommendationCount: 0
            )
        }
        .padding()
        .background(Color.listBackground)
    }
    .modelContainer(container)
}

#Preview("紧凑卡片") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fermentation.self, configurations: config)

    let f = Fermentation(
        name: "康普茶 第3代",
        status: "active",
        createdAt: Date().addingTimeInterval(-86400 * 7)
    )
    container.mainContext.insert(f)

    return List {
        CompactFermentationCard(fermentation: f)
        CompactFermentationCard(fermentation: f)
        CompactFermentationCard(fermentation: f)
    }
    .modelContainer(container)
}

#Preview("对比") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fermentation.self, configurations: config)

    let fermentations = [
        Fermentation(name: "苹果鲁邦", status: "active", createdAt: Date().addingTimeInterval(-86400 * 5)),
        Fermentation(name: "康普茶", status: "completed", createdAt: Date().addingTimeInterval(-86400 * 10)),
        Fermentation(name: "泡菜", status: "discarded", createdAt: Date().addingTimeInterval(-86400 * 3))
    ]

    fermentations.forEach { container.mainContext.insert($0) }

    return ScrollView {
        VStack(alignment: .leading, spacing: .sectionSpacing) {
            // 新设计
            VStack(alignment: .leading, spacing: .spacingSM) {
                Text("新设计")
                    .font(.headline)

                ForEach(fermentations) { f in
                    FermentationCard(
                        fermentation: f,
                        recommendationCount: Int.random(in: 0...5),
                        hasHighPriority: Bool.random()
                    )
                }
            }

            Divider()

            // 旧设计（对比）
            VStack(alignment: .leading, spacing: .spacingSM) {
                Text("旧设计（对比）")
                    .font(.headline)

                ForEach(fermentations) { f in
                    // 旧式卡片（简化版）
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(f.name)
                                .font(.headline)
                            Spacer()
                            Text(f.safeStatus.displayName)
                                .font(.caption2)
                        }
                        Text(f.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color.listBackground)
    }
    .modelContainer(container)
}
