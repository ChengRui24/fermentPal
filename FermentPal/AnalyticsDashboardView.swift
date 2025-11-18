//
//  AnalyticsDashboardView.swift
//  FermentPal
//
//  数据分析仪表盘 - P2功能UI
//  全局统计、趋势分析和智能洞察
//

import SwiftUI
import SwiftData
import Charts

// MARK: - 数据分析仪表盘

struct AnalyticsDashboardView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var statistics: FermentationStatistics?
    @State private var insights: [Insight] = []
    @State private var trends: TrendData?
    @State private var selectedPeriod: TimePeriod = .month

    private var service: FermentationService {
        FermentationService(modelContext: modelContext)
    }

    var body: some View {
        List {
            // 概览统计
            if let statistics = statistics {
                overviewSection(statistics)
            }

            // 趋势分析
            if let trends = trends {
                trendsSection(trends)
            }

            // 智能洞察
            if !insights.isEmpty {
                insightsSection
            }

            // 空状态
            if statistics == nil || (statistics?.total ?? 0) == 0 {
                emptyStateSection
            }
        }
        .navigationTitle("数据分析")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAnalytics()
        }
        .refreshable {
            loadAnalytics()
        }
    }

    // MARK: - 视图组件

    private func overviewSection(_ stats: FermentationStatistics) -> some View {
        Section {
            // 总数和成功率
            HStack(spacing: 20) {
                StatCard(
                    title: "总发酵罐",
                    value: "\(stats.total)",
                    icon: "archivebox.fill",
                    color: .blue
                )

                StatCard(
                    title: "成功率",
                    value: stats.successRatePercentage,
                    icon: "checkmark.seal.fill",
                    color: .green
                )
            }

            // 活跃数和根数
            HStack(spacing: 20) {
                StatCard(
                    title: "进行中",
                    value: "\(stats.active)",
                    icon: "flame.fill",
                    color: .orange
                )

                StatCard(
                    title: "根批次",
                    value: "\(stats.roots)",
                    icon: "tree.fill",
                    color: .purple
                )
            }

            // 平均时长和活跃度
            if let avgDuration = stats.averageDuration {
                HStack(spacing: 20) {
                    StatCard(
                        title: "平均时长",
                        value: "\(avgDuration)天",
                        icon: "clock.fill",
                        color: .cyan
                    )

                    StatCard(
                        title: "活跃度",
                        value: stats.activityScore,
                        icon: "chart.line.uptrend.xyaxis",
                        color: .pink
                    )
                }
            }
        } header: {
            Text("概览")
        }
    }

    private func trendsSection(_ trends: TrendData) -> some View {
        Section {
            // 月度趋势图表
            if !trends.monthlyStats.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("月度趋势")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Chart {
                        ForEach(trends.monthlyStats) { stat in
                            BarMark(
                                x: .value("月份", stat.month),
                                y: .value("数量", stat.count)
                            )
                            .foregroundStyle(.blue.gradient)
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel()
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            // 类型分布
            if !trends.typeDistribution.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("类型分布")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(Array(trends.typeDistribution.sorted(by: { $0.value > $1.value })), id: \.key) { type, count in
                        HStack {
                            Text(type.isEmpty ? "未分类" : type)
                            Spacer()
                            Text("\(count)")
                                .foregroundStyle(.secondary)

                            // 简单进度条
                            let maxCount = trends.typeDistribution.values.max() ?? 1
                            let percentage = Double(count) / Double(maxCount)
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: geometry.size.width * percentage)
                                }
                            }
                            .frame(width: 60, height: 8)
                            .clipShape(Capsule())
                        }
                        .font(.caption)
                    }
                }
                .padding(.vertical, 8)
            }

            // 成功率趋势
            if !trends.successRateTrend.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("成功率趋势")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Chart {
                        ForEach(trends.successRateTrend) { point in
                            LineMark(
                                x: .value("时间", point.period),
                                y: .value("成功率", point.rate * 100)
                            )
                            .foregroundStyle(.green.gradient)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("时间", point.period),
                                y: .value("成功率", point.rate * 100)
                            )
                            .foregroundStyle(.green.opacity(0.1).gradient)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .frame(height: 150)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let rate = value.as(Double.self) {
                                    Text("\(Int(rate))%")
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("趋势分析")
        }
    }

    private var insightsSection: some View {
        Section {
            ForEach(insights) { insight in
                InsightRow(insight: insight)
            }
        } header: {
            Text("智能洞察")
        }
    }

    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 60))
                    .foregroundStyle(.gray.opacity(0.5))

                Text("暂无数据")
                    .font(.headline)

                Text("开始创建发酵罐后，这里会显示详细的数据分析")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
    }

    // MARK: - 辅助方法

    private func loadAnalytics() {
        statistics = service.getAnalytics()
        insights = service.getInsights()
        trends = service.getTrends()
    }
}

// MARK: - 统计卡片视图

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 洞察行视图

struct InsightRow: View {
    let insight: Insight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: typeIcon)
                    .foregroundStyle(typeColor)

                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if let badge = insight.badge {
                    Text(badge)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(typeColor.opacity(0.15))
                        .foregroundStyle(typeColor)
                        .clipShape(Capsule())
                }
            }

            Text(insight.message)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let suggestion = insight.suggestion {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                    Text(suggestion)
                        .font(.caption)
                }
                .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }

    private var typeIcon: String {
        switch insight.type {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .suggestion: return "lightbulb.fill"
        case .pattern: return "sparkles"
        }
    }

    private var typeColor: Color {
        switch insight.type {
        case .success: return .green
        case .warning: return .orange
        case .suggestion: return .blue
        case .pattern: return .purple
        }
    }
}

// MARK: - 时间周期枚举

enum TimePeriod: String, CaseIterable {
    case week = "周"
    case month = "月"
    case quarter = "季度"
    case year = "年"
}

// MARK: - 扩展统计数据

extension FermentationStatistics {
    var successRatePercentage: String {
        guard total > 0 else { return "0%" }
        let rate = Double(completed) / Double(total) * 100
        return String(format: "%.0f%%", rate)
    }

    var activityScore: String {
        guard total > 0 else { return "0%" }
        let score = Double(active) / Double(total) * 100
        return String(format: "%.0f%%", score)
    }
}

// MARK: - 预览

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fermentation.self, configurations: config)

    // 添加测试数据
    for i in 1...10 {
        let f = Fermentation(name: "测试\(i)", status: i % 3 == 0 ? "completed" : "active")
        container.mainContext.insert(f)
    }

    return NavigationStack {
        AnalyticsDashboardView()
            .modelContainer(container)
    }
}
