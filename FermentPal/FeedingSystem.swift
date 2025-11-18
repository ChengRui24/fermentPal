//
//  FeedingSystem.swift
//  FermentPal
//
//  投料结构化系统 - P1优化
//  将自由文本的投料转换为结构化数据，支持分析和计算
//

import Foundation
import SwiftData

// MARK: - 投料成分模型

@Model
final class FeedingIngredient {
    var feeding: FeedingData?
    var name: String                // 成分名称（如"高筋面粉"）
    var amount: Double              // 数量
    var unit: String                // 单位（g, ml, 个等）
    var order: Int                  // 显示顺序

    init(
        feeding: FeedingData? = nil,
        name: String,
        amount: Double,
        unit: String,
        order: Int = 0
    ) {
        self.feeding = feeding
        self.name = name
        self.amount = amount
        self.unit = unit
        self.order = order
    }

    // MARK: - 计算属性

    /// 格式化显示
    var formattedAmount: String {
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(amount))\(unit)"
        } else {
            return String(format: "%.1f%@", amount, unit)
        }
    }

    /// 完整描述
    var fullDescription: String {
        "\(name) \(formattedAmount)"
    }
}

// MARK: - 投料数据模型

@Model
final class FeedingData {
    var record: Record?
    @Relationship(deleteRule: .cascade) var ingredients: [FeedingIngredient]
    var totalWeight: Double?        // 总重量（自动计算）
    var ratio: String?              // 比例（如"1:1:1"）
    var notes: String?              // 备注
    var createdAt: Date

    init(
        record: Record? = nil,
        ingredients: [FeedingIngredient] = [],
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.record = record
        self.ingredients = ingredients
        self.notes = notes
        self.createdAt = createdAt
        self.totalWeight = nil
        self.ratio = nil
    }

    // MARK: - 计算属性

    /// 成分数量
    var ingredientCount: Int {
        ingredients.count
    }

    /// 是否为空
    var isEmpty: Bool {
        ingredients.isEmpty
    }

    /// 按顺序排序的成分
    var sortedIngredients: [FeedingIngredient] {
        ingredients.sorted { $0.order < $1.order }
    }

    /// 简要描述
    var summary: String {
        if ingredients.isEmpty {
            return "未添加成分"
        }
        return sortedIngredients.map { $0.fullDescription }.joined(separator: " + ")
    }

    // MARK: - 业务方法

    /// 添加成分
    func addIngredient(_ ingredient: FeedingIngredient) {
        ingredient.order = ingredients.count
        ingredients.append(ingredient)
        recalculate()
    }

    /// 移除成分
    func removeIngredient(_ ingredient: FeedingIngredient) {
        ingredients.removeAll { $0.name == ingredient.name }
        reorderIngredients()
        recalculate()
    }

    /// 重新排序
    private func reorderIngredients() {
        for (index, ingredient) in ingredients.enumerated() {
            ingredient.order = index
        }
    }

    /// 重新计算总重量和比例
    func recalculate() {
        // 计算总重量（只计算重量单位）
        let weightIngredients = ingredients.filter { ["g", "克", "kg", "千克"].contains($0.unit) }
        if !weightIngredients.isEmpty {
            let total = weightIngredients.reduce(0.0) { sum, ingredient in
                let weight = ingredient.unit == "kg" || ingredient.unit == "千克"
                    ? ingredient.amount * 1000
                    : ingredient.amount
                return sum + weight
            }
            totalWeight = total
        }

        // 计算比例（简化版本）
        if ingredients.count >= 2 {
            ratio = calculateRatio()
        }
    }

    /// 计算比例
    private func calculateRatio() -> String {
        let amounts = sortedIngredients.map { $0.amount }
        guard let minAmount = amounts.min(), minAmount > 0 else {
            return amounts.map { String(format: "%.0f", $0) }.joined(separator: ":")
        }

        // 归一化为最简比例
        let normalized = amounts.map { Int(($0 / minAmount).rounded()) }
        return normalized.map { String($0) }.joined(separator: ":")
    }
}

// MARK: - 投料单位枚举

enum FeedingUnit: String, CaseIterable {
    // 重量
    case gram = "g"
    case kilogram = "kg"

    // 体积
    case milliliter = "ml"
    case liter = "L"

    // 数量
    case piece = "个"
    case tablespoon = "勺"
    case teaspoon = "小勺"

    var displayName: String {
        rawValue
    }

    var category: UnitCategory {
        switch self {
        case .gram, .kilogram:
            return .weight
        case .milliliter, .liter:
            return .volume
        case .piece, .tablespoon, .teaspoon:
            return .count
        }
    }
}

enum UnitCategory {
    case weight
    case volume
    case count
}

// MARK: - 常用成分预设

struct CommonIngredient {
    let name: String
    let category: IngredientCategory
    let defaultUnit: FeedingUnit
    let commonAmounts: [Double]

    static let sourdoughIngredients: [CommonIngredient] = [
        CommonIngredient(
            name: "高筋面粉",
            category: .flour,
            defaultUnit: .gram,
            commonAmounts: [50, 100, 150, 200]
        ),
        CommonIngredient(
            name: "全麦粉",
            category: .flour,
            defaultUnit: .gram,
            commonAmounts: [50, 100, 150, 200]
        ),
        CommonIngredient(
            name: "黑麦粉",
            category: .flour,
            defaultUnit: .gram,
            commonAmounts: [25, 50, 100]
        ),
        CommonIngredient(
            name: "水",
            category: .liquid,
            defaultUnit: .gram,
            commonAmounts: [50, 90, 100, 150]
        ),
        CommonIngredient(
            name: "留种",
            category: .starter,
            defaultUnit: .gram,
            commonAmounts: [50, 80, 100]
        )
    ]

    static let kombuchaIngredients: [CommonIngredient] = [
        CommonIngredient(
            name: "红茶",
            category: .liquid,
            defaultUnit: .milliliter,
            commonAmounts: [500, 1000, 1500]
        ),
        CommonIngredient(
            name: "绿茶",
            category: .liquid,
            defaultUnit: .milliliter,
            commonAmounts: [500, 1000, 1500]
        ),
        CommonIngredient(
            name: "白糖",
            category: .sugar,
            defaultUnit: .gram,
            commonAmounts: [50, 70, 100]
        ),
        CommonIngredient(
            name: "果汁",
            category: .liquid,
            defaultUnit: .milliliter,
            commonAmounts: [100, 150, 200]
        ),
        CommonIngredient(
            name: "水果",
            category: .fruit,
            defaultUnit: .gram,
            commonAmounts: [50, 100, 150]
        )
    ]

    static func getCommonIngredients(for type: String) -> [CommonIngredient] {
        switch type {
        case "酸面团", "鲁邦":
            return sourdoughIngredients
        case "康普茶":
            return kombuchaIngredients
        default:
            return []
        }
    }
}

enum IngredientCategory {
    case flour      // 面粉类
    case liquid     // 液体类
    case sugar      // 糖类
    case starter    // 菌种类
    case fruit      // 水果类
    case spice      // 香料类
    case other      // 其他
}

// MARK: - 投料分析器

class FeedingAnalyzer {

    /// 分析投料数据
    static func analyze(_ feeding: FeedingData, fermentationType: String) -> FeedingAnalysis {
        var insights: [String] = []
        var warnings: [String] = []
        var recommendations: [String] = []

        // 酸面团特殊分析
        if fermentationType == "酸面团" || fermentationType == "鲁邦" {
            analyzeSourdough(feeding, insights: &insights, warnings: &warnings, recommendations: &recommendations)
        }

        // 康普茶特殊分析
        if fermentationType == "康普茶" {
            analyzeKombucha(feeding, insights: &insights, warnings: &warnings, recommendations: &recommendations)
        }

        return FeedingAnalysis(
            insights: insights,
            warnings: warnings,
            recommendations: recommendations
        )
    }

    private static func analyzeSourdough(
        _ feeding: FeedingData,
        insights: inout [String],
        warnings: inout [String],
        recommendations: inout [String]
    ) {
        let ingredients = feeding.sortedIngredients

        // 查找关键成分
        let flour = ingredients.filter { ["面粉", "粉", "flour"].contains(where: $0.name.lowercased().contains) }
        let water = ingredients.filter { ["水", "water"].contains(where: $0.name.lowercased().contains) }
        let starter = ingredients.filter { ["留种", "种", "starter"].contains(where: $0.name.lowercased().contains) }

        // 计算水粉比
        if let flourAmount = flour.first?.amount, let waterAmount = water.first?.amount, flourAmount > 0 {
            let hydration = (waterAmount / flourAmount) * 100
            insights.append(String(format: "水合度：%.0f%%", hydration))

            if hydration < 60 {
                warnings.append("水合度较低，可能较硬")
            } else if hydration > 100 {
                warnings.append("水合度很高，可能较稀")
            } else if hydration >= 75 && hydration <= 85 {
                insights.append("水合度理想（75-85%）")
            }
        }

        // 检查留种比例
        if let flourAmount = flour.first?.amount, let starterAmount = starter.first?.amount {
            let ratio = (starterAmount / flourAmount) * 100
            insights.append(String(format: "留种比例：%.0f%%", ratio))

            if ratio < 10 {
                warnings.append("留种比例较低，发酵时间可能较长")
            } else if ratio > 50 {
                warnings.append("留种比例过高，可能过酸")
            } else if ratio >= 15 && ratio <= 30 {
                insights.append("留种比例适中（15-30%）")
            }
        }

        // 推荐配方
        if feeding.isEmpty {
            recommendations.append("经典1:1:1配方：留种100g + 面粉100g + 水100g")
            recommendations.append("低比例配方：留种50g + 面粉100g + 水90g")
        }
    }

    private static func analyzeKombucha(
        _ feeding: FeedingData,
        insights: inout [String],
        warnings: inout [String],
        recommendations: inout [String]
    ) {
        let ingredients = feeding.sortedIngredients

        // 查找关键成分
        let tea = ingredients.filter { ["茶", "tea"].contains(where: $0.name.lowercased().contains) }
        let sugar = ingredients.filter { ["糖", "sugar"].contains(where: $0.name.lowercased().contains) }

        // 检查糖茶比
        if let teaAmount = tea.first?.amount, let sugarAmount = sugar.first?.amount, teaAmount > 0 {
            let sugarRatio = (sugarAmount / teaAmount) * 100
            insights.append(String(format: "糖茶比：%.1f%%", sugarRatio))

            if sugarRatio < 5 {
                warnings.append("糖分偏低，发酵可能不充分")
            } else if sugarRatio > 10 {
                warnings.append("糖分过高，可能过甜")
            } else if sugarRatio >= 6 && sugarRatio <= 8 {
                insights.append("糖茶比适中（6-8%）")
            }
        }

        // 推荐配方
        if feeding.isEmpty {
            recommendations.append("经典配方：红茶1L + 白糖70g（7%）")
            recommendations.append("低糖配方：绿茶1L + 白糖50g（5%）")
        }
    }

    /// 从文本解析投料
    static func parseFromText(_ text: String) -> [FeedingIngredient] {
        var ingredients: [FeedingIngredient] = []
        let lines = text.components(separatedBy: CharacterSet(charactersIn: "+\n,，"))

        for (index, line) in lines.enumerated() {
            if let ingredient = parseIngredientLine(line.trimmingCharacters(in: .whitespaces)) {
                ingredient.order = index
                ingredients.append(ingredient)
            }
        }

        return ingredients
    }

    private static func parseIngredientLine(_ line: String) -> FeedingIngredient? {
        // 尝试匹配格式：名称 数量单位
        // 例如：面粉100g, 水 90ml, 糖 50 克
        let pattern = "([\\u4e00-\\u9fa5a-zA-Z]+)\\s*([0-9.]+)\\s*([a-zA-Z克毫升千克个勺]+)"

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }

        guard match.numberOfRanges == 4 else { return nil }

        let nameRange = Range(match.range(at: 1), in: line)!
        let amountRange = Range(match.range(at: 2), in: line)!
        let unitRange = Range(match.range(at: 3), in: line)!

        let name = String(line[nameRange])
        let amount = Double(line[amountRange]) ?? 0
        var unit = String(line[unitRange])

        // 标准化单位
        unit = normalizeUnit(unit)

        return FeedingIngredient(name: name, amount: amount, unit: unit)
    }

    private static func normalizeUnit(_ unit: String) -> String {
        let normalized = unit.lowercased()
        if ["克", "g"].contains(normalized) {
            return "g"
        } else if ["千克", "kg"].contains(normalized) {
            return "kg"
        } else if ["毫升", "ml"].contains(normalized) {
            return "ml"
        } else if ["升", "l"].contains(normalized) {
            return "L"
        }
        return unit
    }
}

// MARK: - 投料分析结果

struct FeedingAnalysis {
    let insights: [String]
    let warnings: [String]
    let recommendations: [String]

    var hasInsights: Bool {
        !insights.isEmpty
    }

    var hasWarnings: Bool {
        !warnings.isEmpty
    }

    var hasRecommendations: Bool {
        !recommendations.isEmpty
    }
}
