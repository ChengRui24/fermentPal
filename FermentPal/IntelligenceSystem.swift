//
//  IntelligenceSystem.swift
//  FermentPal
//
//  智能系统 - P1/P2优化
//  包含：状态判断指导、智能建议引擎、数据分析
//

import Foundation
import SwiftData

// MARK: - 状态判断指导系统

class StatusGuidance {

    /// 获取状态建议
    static func suggestStatus(
        fermentation: Fermentation,
        observations: String
    ) -> StatusSuggestion {

        let durationDays = fermentation.durationDays
        let type = extractFermentationType(from: fermentation.name)
        let lastStatus = fermentation.lastRecord?.safeStatus ?? .normal

        var suggestedStatus: RecordStatus = .normal
        var reasons: [String] = []
        var tips: [String] = []
        var confidence: Double = 0.5

        // 基于持续时间的判断
        if durationDays > 14 && lastStatus == .normal {
            suggestedStatus = .watch
            reasons.append("超过14天未更新，建议检查状态")
            confidence = 0.7
        }

        // 基于类型的判断
        if type == "酸面团" || type == "鲁邦" {
            analyzeSourdoughStatus(
                durationDays: durationDays,
                observations: observations,
                suggestedStatus: &suggestedStatus,
                reasons: &reasons,
                tips: &tips,
                confidence: &confidence
            )
        } else if type == "康普茶" {
            analyzeKombuchaStatus(
                durationDays: durationDays,
                observations: observations,
                suggestedStatus: &suggestedStatus,
                reasons: &reasons,
                tips: &tips,
                confidence: &confidence
            )
        }

        // 基于关键词的判断
        analyzeObservationKeywords(
            observations: observations,
            suggestedStatus: &suggestedStatus,
            reasons: &reasons,
            confidence: &confidence
        )

        return StatusSuggestion(
            suggestedStatus: suggestedStatus,
            reasons: reasons,
            tips: tips,
            confidence: confidence
        )
    }

    private static func extractFermentationType(from name: String) -> String {
        let lowercaseName = name.lowercased()
        if lowercaseName.contains("鲁邦") || lowercaseName.contains("酸面") {
            return "酸面团"
        } else if lowercaseName.contains("康普") || lowercaseName.contains("kombucha") {
            return "康普茶"
        } else if lowercaseName.contains("泡菜") || lowercaseName.contains("酸菜") {
            return "泡菜"
        }
        return "未知"
    }

    private static func analyzeSourdoughStatus(
        durationDays: Int,
        observations: String,
        suggestedStatus: inout RecordStatus,
        reasons: inout [String],
        tips: inout [String],
        confidence: inout Double
    ) {
        // 酸面团特殊逻辑
        if durationDays > 7 {
            suggestedStatus = .watch
            reasons.append("超过7天未喂养，活力可能下降")
            tips.append("建议连续喂养2-3次恢复活力")
            confidence = 0.8
        }

        if durationDays == 1 {
            tips.append("喂养后8-12小时观察体积变化")
            tips.append("理想状态：体积翻倍，气泡均匀")
        }
    }

    private static func analyzeKombuchaStatus(
        durationDays: Int,
        observations: String,
        suggestedStatus: inout RecordStatus,
        reasons: inout [String],
        tips: inout [String],
        confidence: inout Double
    ) {
        // 康普茶特殊逻辑
        if durationDays >= 7 && durationDays <= 10 {
            tips.append("一发通常需要7-10天")
            tips.append("可以品尝一下酸甜度")
        } else if durationDays > 14 {
            suggestedStatus = .watch
            reasons.append("发酵时间较长，可能过酸")
            tips.append("建议检查酸度，考虑分装二发")
            confidence = 0.7
        }
    }

    private static func analyzeObservationKeywords(
        observations: String,
        suggestedStatus: inout RecordStatus,
        reasons: inout [String],
        confidence: inout Double
    ) {
        let lowerObs = observations.lowercased()

        // 异常关键词
        let abnormalKeywords = ["霉", "臭", "腐", "变色", "发黑", "异味"]
        for keyword in abnormalKeywords {
            if lowerObs.contains(keyword) {
                suggestedStatus = .abnormal
                reasons.append("检测到异常关键词：\(keyword)")
                confidence = 0.9
                return
            }
        }

        // 需要关注的关键词
        let watchKeywords = ["慢", "没", "不", "弱", "少"]
        for keyword in watchKeywords {
            if lowerObs.contains(keyword) {
                if suggestedStatus == .normal {
                    suggestedStatus = .watch
                    reasons.append("检测到需要关注的迹象")
                    confidence = 0.6
                }
            }
        }

        // 正常关键词
        let normalKeywords = ["翻倍", "气泡", "均匀", "酸香", "活跃"]
        var normalCount = 0
        for keyword in normalKeywords {
            if lowerObs.contains(keyword) {
                normalCount += 1
            }
        }
        if normalCount >= 2 {
            suggestedStatus = .normal
            reasons.append("状态正常：检测到多个健康指标")
            confidence = 0.8
        }
    }
}

struct StatusSuggestion {
    let suggestedStatus: RecordStatus
    let reasons: [String]
    let tips: [String]
    let confidence: Double  // 0-1, 建议的可信度

    var isHighConfidence: Bool {
        confidence >= 0.7
    }

    var shouldShowSuggestion: Bool {
        !reasons.isEmpty && confidence >= 0.5
    }
}

// MARK: - 智能建议引擎

class RecommendationEngine {

    /// 生成智能建议
    static func generateRecommendations(for fermentation: Fermentation) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // 时间相关建议
        recommendations.append(contentsOf: analyzeTimingRecommendations(fermentation))

        // 活动相关建议
        recommendations.append(contentsOf: analyzeActivityRecommendations(fermentation))

        // 状态相关建议
        recommendations.append(contentsOf: analyzeStatusRecommendations(fermentation))

        // 成功模式识别
        if let pattern = detectSuccessPattern(fermentation) {
            recommendations.append(pattern)
        }

        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }

    private static func analyzeTimingRecommendations(_ fermentation: Fermentation) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // 长时间未喂养警告
        if fermentation.durationDays > 7 && fermentation.isActive {
            recommendations.append(Recommendation(
                type: .warning,
                priority: .high,
                title: "长时间未喂养",
                description: "已经\(fermentation.durationDays)天未喂养，活力可能下降",
                action: "添加喂养记录",
                actionType: .addFeeding
            ))
        }

        // 提醒设置建议
        if fermentation.reminders.isEmpty && fermentation.isActive {
            recommendations.append(Recommendation(
                type: .tip,
                priority: .medium,
                title: "设置提醒",
                description: "设置定期提醒可以避免忘记喂养",
                action: "设置提醒",
                actionType: .setReminder
            ))
        }

        return recommendations
    }

    private static func analyzeActivityRecommendations(_ fermentation: Fermentation) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        let daysSinceLastActivity = Calendar.current.dateComponents(
            [.day],
            from: fermentation.lastActivityTime,
            to: Date()
        ).day ?? 0

        // 活跃度低
        if daysSinceLastActivity > 3 && fermentation.isActive {
            recommendations.append(Recommendation(
                type: .tip,
                priority: .medium,
                title: "添加观察记录",
                description: "定期记录有助于追踪发酵状态变化",
                action: "添加记录",
                actionType: .addRecord
            ))
        }

        return recommendations
    }

    private static func analyzeStatusRecommendations(_ fermentation: Fermentation) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // 检查异常状态的记录
        let abnormalRecords = fermentation.records.filter { $0.safeStatus == .abnormal }
        if !abnormalRecords.isEmpty && fermentation.isActive {
            recommendations.append(Recommendation(
                type: .warning,
                priority: .high,
                title: "存在异常记录",
                description: "有\(abnormalRecords.count)条异常记录，建议评估是否继续",
                action: "查看异常记录",
                actionType: .viewRecords
            ))
        }

        // 检查需要关注的记录
        let watchRecords = fermentation.records.filter { $0.safeStatus == .watch }
        if watchRecords.count >= 3 && fermentation.isActive {
            recommendations.append(Recommendation(
                type: .tip,
                priority: .medium,
                title: "持续需要关注",
                description: "连续多次记录显示需要关注，考虑调整条件",
                action: "查看建议",
                actionType: .viewTips
            ))
        }

        return recommendations
    }

    private static func detectSuccessPattern(_ fermentation: Fermentation) -> Recommendation? {
        // 分析成功模式（简化版本）
        let normalRecords = fermentation.records.filter { $0.safeStatus == .normal }

        if normalRecords.count >= 5 {
            // 计算平均时间间隔
            let sortedRecords = normalRecords.sorted { $0.createdAt < $1.createdAt }
            var intervals: [TimeInterval] = []

            for i in 0..<sortedRecords.count-1 {
                let interval = sortedRecords[i+1].createdAt.timeIntervalSince(sortedRecords[i].createdAt)
                intervals.append(interval)
            }

            if !intervals.isEmpty {
                let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
                let hours = Int(averageInterval / 3600)

                if hours > 0 && hours < 72 {
                    return Recommendation(
                        type: .success,
                        priority: .medium,
                        title: "发现成功模式",
                        description: "平均每\(hours)小时记录一次效果较好",
                        action: "应用到提醒",
                        actionType: .setReminder
                    )
                }
            }
        }

        return nil
    }
}

// MARK: - 建议数据结构

struct Recommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let priority: RecommendationPriority
    let title: String
    let description: String
    let action: String
    let actionType: RecommendationAction
    let createdAt: Date = Date()

    var icon: String {
        type.icon
    }

    var color: String {
        type.color
    }
}

enum RecommendationType {
    case warning    // 警告
    case tip        // 提示
    case success    // 成功模式
    case insight    // 洞察

    var icon: String {
        switch self {
        case .warning: return "exclamationmark.triangle"
        case .tip: return "lightbulb"
        case .success: return "star"
        case .insight: return "chart.line.uptrend.xyaxis"
        }
    }

    var color: String {
        switch self {
        case .warning: return "orange"
        case .tip: return "blue"
        case .success: return "green"
        case .insight: return "purple"
        }
    }
}

enum RecommendationPriority: Int {
    case high = 3
    case medium = 2
    case low = 1
}

enum RecommendationAction {
    case addFeeding
    case addRecord
    case setReminder
    case viewRecords
    case viewTips
    case adjustStatus
}

// MARK: - 数据分析系统

class AnalyticsEngine {

    /// 生成统计数据
    static func generateStatistics(fermentations: [Fermentation]) -> FermentationStatistics {
        let total = fermentations.count
        let active = fermentations.filter { $0.status == "active" }.count
        let completed = fermentations.filter { $0.status == "completed" }.count
        let discarded = fermentations.filter { $0.status == "discarded" }.count
        let roots = fermentations.filter { $0.isRoot }.count

        return FermentationStatistics(
            total: total,
            active: active,
            completed: completed,
            discarded: discarded,
            roots: roots
        )
    }

    /// 计算成功率
    static func calculateSuccessRate(fermentations: [Fermentation]) -> Double {
        let finished = fermentations.filter { $0.status != "active" }
        guard !finished.isEmpty else { return 0 }

        let successful = finished.filter { $0.status == "completed" }
        return Double(successful.count) / Double(finished.count) * 100
    }

    /// 计算平均发酵时长
    static func calculateAverageDuration(fermentations: [Fermentation], type: String? = nil) -> TimeInterval {
        var targetFermentations = fermentations

        if let type = type {
            targetFermentations = fermentations.filter { $0.name.lowercased().contains(type.lowercased()) }
        }

        guard !targetFermentations.isEmpty else { return 0 }

        let totalDuration = targetFermentations.reduce(0.0) { sum, fermentation in
            let duration = Date().timeIntervalSince(fermentation.createdAt)
            return sum + duration
        }

        return totalDuration / Double(targetFermentations.count)
    }

    /// 生成洞察
    static func generateInsights(fermentations: [Fermentation]) -> [Insight] {
        var insights: [Insight] = []

        // 成功率洞察
        let successRate = calculateSuccessRate(fermentations: fermentations)
        if successRate >= 80 {
            insights.append(Insight(
                type: .success,
                title: "成功率很高",
                description: String(format: "%.0f%%的批次成功完成", successRate),
                actionable: false
            ))
        } else if successRate < 50 {
            insights.append(Insight(
                type: .warning,
                title: "成功率偏低",
                description: String(format: "只有%.0f%%的批次成功，建议查看失败原因", successRate),
                actionable: true
            ))
        }

        // 活跃度洞察
        let activeCount = fermentations.filter { $0.isActive }.count
        if activeCount > 10 {
            insights.append(Insight(
                type: .tip,
                title: "项目较多",
                description: "有\(activeCount)个活跃项目，注意管理时间",
                actionable: true
            ))
        } else if activeCount == 0 && !fermentations.isEmpty {
            insights.append(Insight(
                type: .tip,
                title: "可以开始新项目",
                description: "当前没有活跃项目，可以开始新的发酵",
                actionable: true
            ))
        }

        // 类型分布洞察
        let types = Dictionary(grouping: fermentations) { fermentation -> String in
            if fermentation.name.lowercased().contains("鲁邦") { return "酸面团" }
            if fermentation.name.lowercased().contains("康普") { return "康普茶" }
            if fermentation.name.lowercased().contains("泡菜") { return "泡菜" }
            return "其他"
        }

        if let mostCommonType = types.max(by: { $0.value.count < $1.value.count }) {
            insights.append(Insight(
                type: .insight,
                title: "最常做的是\(mostCommonType.key)",
                description: "共有\(mostCommonType.value.count)个\(mostCommonType.key)项目",
                actionable: false
            ))
        }

        return insights
    }

    /// 生成趋势数据
    static func generateTrends(fermentations: [Fermentation]) -> TrendData {
        let sortedByDate = fermentations.sorted { $0.createdAt < $1.createdAt }

        // 按月份分组
        let byMonth = Dictionary(grouping: sortedByDate) { fermentation -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            return formatter.string(from: fermentation.createdAt)
        }

        let monthlyData = byMonth.map { (month, fermentations) -> (String, Int) in
            (month, fermentations.count)
        }.sorted { $0.0 < $1.0 }

        return TrendData(
            monthlyCreationCount: monthlyData,
            totalCount: fermentations.count,
            trend: calculateTrend(monthlyData)
        )
    }

    private static func calculateTrend(_ data: [(String, Int)]) -> TrendDirection {
        guard data.count >= 2 else { return .stable }

        let last = data.suffix(3)
        let counts = last.map { $0.1 }

        if Double(counts.last!) > Double(counts.first!) * 1.5 {
            return .increasing
        } else if Double(counts.last!) < Double(counts.first!) * 0.7 {
            return .decreasing
        } else {
            return .stable
        }
    }
}

// MARK: - 分析数据结构

struct Insight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let actionable: Bool
}

enum InsightType {
    case success
    case warning
    case tip
    case insight
}

struct TrendData {
    let monthlyCreationCount: [(String, Int)]
    let totalCount: Int
    let trend: TrendDirection
}

enum TrendDirection {
    case increasing
    case stable
    case decreasing

    var displayName: String {
        switch self {
        case .increasing: return "上升"
        case .stable: return "稳定"
        case .decreasing: return "下降"
        }
    }

    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .decreasing: return "arrow.down.right"
        }
    }
}
