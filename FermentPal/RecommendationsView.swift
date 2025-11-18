//
//  RecommendationsView.swift
//  FermentPal
//
//  智能推荐界面 - P1/P2功能UI
//  基于发酵状态的智能建议和推荐
//

import SwiftUI
import SwiftData

// MARK: - 智能推荐视图

struct RecommendationsView: View {
    @Environment(\.modelContext) private var modelContext

    let fermentation: Fermentation

    @State private var recommendations: [Recommendation] = []
    @State private var showingStatusGuidance: Bool = false

    private var service: FermentationService {
        FermentationService(modelContext: modelContext)
    }

    private var highPriorityRecommendations: [Recommendation] {
        recommendations.filter { $0.priority == .high }
    }

    private var mediumPriorityRecommendations: [Recommendation] {
        recommendations.filter { $0.priority == .medium }
    }

    private var lowPriorityRecommendations: [Recommendation] {
        recommendations.filter { $0.priority == .low }
    }

    var body: some View {
        List {
            // 状态判断指导
            statusGuidanceSection

            // 高优先级推荐
            if !highPriorityRecommendations.isEmpty {
                recommendationSection(
                    title: "重要建议",
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    recommendations: highPriorityRecommendations
                )
            }

            // 中优先级推荐
            if !mediumPriorityRecommendations.isEmpty {
                recommendationSection(
                    title: "注意事项",
                    icon: "lightbulb.fill",
                    color: .orange,
                    recommendations: mediumPriorityRecommendations
                )
            }

            // 低优先级推荐
            if !lowPriorityRecommendations.isEmpty {
                recommendationSection(
                    title: "优化建议",
                    icon: "star.fill",
                    color: .blue,
                    recommendations: lowPriorityRecommendations
                )
            }

            // 空状态
            if recommendations.isEmpty {
                emptyStateSection
            }
        }
        .navigationTitle("智能推荐")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingStatusGuidance) {
            StatusGuidanceView(fermentation: fermentation)
        }
        .onAppear {
            loadRecommendations()
        }
        .refreshable {
            loadRecommendations()
        }
    }

    // MARK: - 视图组件

    private var statusGuidanceSection: some View {
        Section {
            Button(action: { showingStatusGuidance = true }) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.purple)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("状态判断指导")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("根据观察描述智能判断发酵状态")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func recommendationSection(
        title: String,
        icon: String,
        color: Color,
        recommendations: [Recommendation]
    ) -> some View {
        Section {
            ForEach(recommendations) { recommendation in
                RecommendationRow(recommendation: recommendation)
            }
        } header: {
            Label(title, systemImage: icon)
                .foregroundStyle(color)
        }
    }

    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)

                Text("一切正常")
                    .font(.headline)

                Text("目前没有需要特别注意的事项")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    // MARK: - 辅助方法

    private func loadRecommendations() {
        recommendations = service.getRecommendations(for: fermentation)
    }
}

// MARK: - 推荐行视图

struct RecommendationRow: View {
    let recommendation: Recommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题
            HStack {
                Image(systemName: recommendation.type.icon)
                    .foregroundStyle(priorityColor)

                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if let badge = recommendation.badge {
                    Text(badge)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.15))
                        .foregroundStyle(priorityColor)
                        .clipShape(Capsule())
                }
            }

            // 原因
            Text(recommendation.reason)
                .font(.caption)
                .foregroundStyle(.secondary)

            // 行动建议
            if let action = recommendation.suggestedAction {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                    Text(action)
                        .font(.caption)
                }
                .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }

    private var priorityColor: Color {
        switch recommendation.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

// MARK: - 状态判断指导视图

struct StatusGuidanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let fermentation: Fermentation

    @State private var observations: String = ""
    @State private var suggestion: StatusSuggestion?

    private var service: FermentationService {
        FermentationService(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            Form {
                // 输入观察
                observationsSection

                // 分析按钮
                analyzeSection

                // 建议结果
                if let suggestion = suggestion {
                    suggestionSection(suggestion)
                }

                // 使用提示
                tipsSection
            }
            .navigationTitle("状态判断指导")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - 视图组件

    private var observationsSection: some View {
        Section {
            TextField("描述你的观察", text: $observations, axis: .vertical)
                .lineLimit(5...10)
        } header: {
            Text("观察描述")
        } footer: {
            Text("例如：表面有很多气泡，闻起来有酸味，质地比较稀")
        }
    }

    private var analyzeSection: some View {
        Section {
            Button(action: analyzStatus) {
                HStack {
                    Spacer()
                    Image(systemName: "brain.head.profile")
                    Text("智能分析")
                        .fontWeight(.medium)
                    Spacer()
                }
            }
            .disabled(observations.isEmpty)
        }
    }

    private func suggestionSection(_ suggestion: StatusSuggestion) -> some View {
        Section {
            // 建议状态
            HStack {
                Text("建议状态")
                Spacer()
                Text(suggestion.suggestedStatus.displayName)
                    .fontWeight(.medium)
                    .foregroundStyle(suggestion.suggestedStatus.color)
            }

            // 置信度
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("置信度")
                    Spacer()
                    Text(String(format: "%.0f%%", suggestion.confidence * 100))
                        .fontWeight(.medium)
                }

                ProgressView(value: suggestion.confidence)
                    .tint(confidenceColor(suggestion.confidence))
            }

            // 理由
            ForEach(suggestion.reasons, id: \.self) { reason in
                Label(reason, systemImage: "checkmark.circle")
                    .font(.caption)
            }

            // 补充信息
            if let additionalInfo = suggestion.additionalInfo {
                Text(additionalInfo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("分析结果")
        }
    }

    private var tipsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                tipRow(
                    icon: "eye",
                    title: "描述外观",
                    detail: "颜色、气泡、质地等"
                )

                tipRow(
                    icon: "nose",
                    title: "描述气味",
                    detail: "酸味、酒精味、霉味等"
                )

                tipRow(
                    icon: "hand.raised",
                    title: "描述手感",
                    detail: "粘稠度、弹性等"
                )
            }
        } header: {
            Text("观察要点")
        }
    }

    private func tipRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 辅助方法

    private func analyzStatus() {
        suggestion = service.suggestStatus(for: fermentation, observations: observations)
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .orange }
        return .red
    }
}

// MARK: - 预览

#Preview("推荐列表") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fermentation.self, configurations: config)

    let fermentation = Fermentation(name: "测试酸面团", status: "active")
    container.mainContext.insert(fermentation)

    return NavigationStack {
        RecommendationsView(fermentation: fermentation)
            .modelContainer(container)
    }
}

#Preview("状态指导") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fermentation.self, configurations: config)

    let fermentation = Fermentation(name: "测试酸面团", status: "active")
    container.mainContext.insert(fermentation)

    return StatusGuidanceView(fermentation: fermentation)
        .modelContainer(container)
}
