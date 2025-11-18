//
//  MainTabView.swift
//  FermentPal
//
//  主导航TabBar - 集成所有P1/P2功能
//  五个主要Tab：主页、家谱、推荐、分析、参考
//

import SwiftUI
import SwiftData

// MARK: - 主TabBar导航

struct MainTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: 主页（发酵罐列表）
            ContentView(selectedTab: $selectedTab)
                .tabItem {
                    Label("主页", systemImage: "house.fill")
                }
                .tag(0)

            // Tab 2: 家谱视图
            GenealogyView()
                .tabItem {
                    Label("家谱", systemImage: "tree.fill")
                }
                .tag(1)

            // Tab 3: 智能推荐（全局）
            GlobalRecommendationsView()
                .tabItem {
                    Label("推荐", systemImage: "sparkles")
                }
                .tag(2)

            // Tab 4: 数据分析仪表盘
            NavigationStack {
                AnalyticsDashboardView()
            }
            .tabItem {
                Label("分析", systemImage: "chart.bar.fill")
            }
            .tag(3)

            // Tab 5: 参考案例库
            ReferenceCaseView()
                .tabItem {
                    Label("参考", systemImage: "book.fill")
                }
                .tag(4)
        }
        .tint(.brandPrimary) // 统一主题色
    }
}

// MARK: - 全局智能推荐视图

struct GlobalRecommendationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Fermentation.updatedAt, order: .reverse) private var allFermentations: [Fermentation]

    @State private var selectedFermentation: Fermentation?

    private var service: FermentationService {
        FermentationService(modelContext: modelContext)
    }

    private var activeFermentations: [Fermentation] {
        allFermentations.filter { $0.status == "active" }
    }

    // 获取每个发酵罐的推荐数量
    private func recommendationCount(for fermentation: Fermentation) -> Int {
        service.getRecommendations(for: fermentation).count
    }

    // 获取高优先级推荐数量
    private func highPriorityCount(for fermentation: Fermentation) -> Int {
        service.getRecommendations(for: fermentation).filter { $0.priority == .high }.count
    }

    var body: some View {
        NavigationStack {
            List {
                if activeFermentations.isEmpty {
                    emptyStateSection
                } else {
                    // 概览卡片
                    overviewSection

                    // 按发酵罐分组的推荐
                    ForEach(Array(activeFermentations.enumerated()), id: \.element.persistentModelID) { index, fermentation in
                        let count = recommendationCount(for: fermentation)
                        let highPriority = highPriorityCount(for: fermentation)

                        if count > 0 {
                            Section {
                                NavigationLink(destination: RecommendationsView(fermentation: fermentation)) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: .spacingSM) {
                                            Text(fermentation.name)
                                                .font(.cardTitle)
                                                .foregroundStyle(Color.textPrimary)

                                            HStack(spacing: .spacingMD) {
                                                EnhancedBadge(
                                                    text: "\(count)条建议",
                                                    icon: "lightbulb.fill",
                                                    color: .info,
                                                    size: .small
                                                )

                                                if highPriority > 0 {
                                                    EnhancedBadge(
                                                        text: "\(highPriority)重要",
                                                        icon: "exclamationmark.triangle.fill",
                                                        color: .danger,
                                                        size: .small
                                                    )
                                                }
                                            }
                                        }

                                        Spacer()

                                        if highPriority > 0 {
                                            Circle()
                                                .fill(.danger)
                                                .frame(width: 8, height: 8)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 无推荐的发酵罐
                    let fermentationsWithoutRecommendations = activeFermentations.filter {
                        recommendationCount(for: $0) == 0
                    }

                    if !fermentationsWithoutRecommendations.isEmpty {
                        Section {
                            ForEach(Array(fermentationsWithoutRecommendations.enumerated()), id: \.element.persistentModelID) { index, fermentation in
                                NavigationLink(destination: RecommendationsView(fermentation: fermentation)) {
                                    HStack(spacing: .spacingMD) {
                                        Text(fermentation.name)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.textPrimary)
                                        Spacer()
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundStyle(.success)
                                            .font(.caption)
                                        Text("一切正常")
                                            .font(.caption)
                                            .foregroundStyle(Color.textSecondary)
                                    }
                                }
                            }
                        } header: {
                            Text("运行良好")
                        }
                    }
                }
            }
            .navigationTitle("智能推荐")
            .refreshable {
                // 触发刷新
            }
        }
    }

    // MARK: - 视图组件

    private var emptyStateSection: some View {
        Section {
            EmptyState(
                icon: "sparkles",
                title: "暂无发酵罐",
                message: "创建发酵罐后，这里会显示智能推荐",
                actionTitle: nil,
                action: nil
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var overviewSection: some View {
        Section {
            VStack(spacing: .spacingMD) {
                HStack(spacing: .spacingLG) {
                    // 总推荐数
                    let totalRecommendations = activeFermentations.reduce(0) { sum, f in
                        sum + recommendationCount(for: f)
                    }

                    StatMiniCard(
                        value: "\(totalRecommendations)",
                        label: "总建议",
                        icon: "lightbulb.fill",
                        color: .info
                    )

                    // 高优先级数
                    let totalHighPriority = activeFermentations.reduce(0) { sum, f in
                        sum + highPriorityCount(for: f)
                    }

                    StatMiniCard(
                        value: "\(totalHighPriority)",
                        label: "重要",
                        icon: "exclamationmark.triangle.fill",
                        color: .danger
                    )

                    // 活跃发酵罐
                    StatMiniCard(
                        value: "\(activeFermentations.count)",
                        label: "进行中",
                        icon: "flame.fill",
                        color: .warning
                    )
                }
            }
        } header: {
            Text("概览")
        }
    }
}

// MARK: - 迷你统计卡片（优化版）

struct StatMiniCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: .spacingSM) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.iconSizeLarge)

            Text(value)
                .font(.numberMedium)
                .foregroundStyle(Color.textPrimary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacingMD)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius))
    }
}

// MARK: - 预览

#Preview("主TabBar") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fermentation.self, Record.self, configurations: config)

    // 添加测试数据
    for i in 1...5 {
        let f = Fermentation(name: "测试发酵罐\(i)", status: "active")
        container.mainContext.insert(f)
    }

    return MainTabView()
        .modelContainer(container)
}

#Preview("全局推荐") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fermentation.self, Record.self, configurations: config)

    let f1 = Fermentation(name: "苹果酸面团", status: "active", createdAt: Date().addingTimeInterval(-86400 * 10))
    let f2 = Fermentation(name: "康普茶", status: "active", createdAt: Date().addingTimeInterval(-86400 * 5))
    let f3 = Fermentation(name: "泡菜", status: "active", createdAt: Date().addingTimeInterval(-86400 * 2))

    container.mainContext.insert(f1)
    container.mainContext.insert(f2)
    container.mainContext.insert(f3)

    return GlobalRecommendationsView()
        .modelContainer(container)
}

