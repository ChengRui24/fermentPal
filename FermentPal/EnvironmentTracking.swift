//
//  EnvironmentTracking.swift
//  FermentPal
//
//  环境因素跟踪系统 - P1优化
//  记录温度、湿度等影响发酵的环境因素
//

import Foundation
import SwiftData

// MARK: - 环境数据模型

@Model
final class EnvironmentData {
    var record: Record?
    var temperature: Double?        // 温度 (°C)
    var humidity: Double?            // 湿度 (%)
    var location: String?            // 位置（厨房、冰箱等）
    var containerType: String?       // 容器类型
    var notes: String?               // 其他备注
    var createdAt: Date

    init(
        record: Record? = nil,
        temperature: Double? = nil,
        humidity: Double? = nil,
        location: String? = nil,
        containerType: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.record = record
        self.temperature = temperature
        self.humidity = humidity
        self.location = location
        self.containerType = containerType
        self.notes = notes
        self.createdAt = createdAt
    }

    // MARK: - 计算属性

    /// 温度是否在理想范围内（20-28°C）
    var isTemperatureIdeal: Bool {
        guard let temp = temperature else { return false }
        return temp >= 20 && temp <= 28
    }

    /// 湿度是否在理想范围内（60-80%）
    var isHumidityIdeal: Bool {
        guard let humid = humidity else { return false }
        return humid >= 60 && humid <= 80
    }

    /// 温度状态描述
    var temperatureStatus: String {
        guard let temp = temperature else { return "未记录" }

        if temp < 15 {
            return "过低（<15°C）"
        } else if temp < 20 {
            return "偏低（15-20°C）"
        } else if temp <= 28 {
            return "理想（20-28°C）"
        } else if temp <= 35 {
            return "偏高（28-35°C）"
        } else {
            return "过高（>35°C）"
        }
    }

    /// 格式化的温度显示
    var formattedTemperature: String {
        guard let temp = temperature else { return "-" }
        return String(format: "%.1f°C", temp)
    }

    /// 格式化的湿度显示
    var formattedHumidity: String {
        guard let humid = humidity else { return "-" }
        return String(format: "%.0f%%", humid)
    }
}

// MARK: - 环境位置枚举

enum EnvironmentLocation: String, CaseIterable {
    case kitchen = "厨房"
    case fridge = "冰箱"
    case basement = "地下室"
    case livingRoom = "客厅"
    case balcony = "阳台"
    case other = "其他"

    var icon: String {
        switch self {
        case .kitchen: return "house.fill"
        case .fridge: return "snowflake"
        case .basement: return "arrow.down.to.line"
        case .livingRoom: return "sofa.fill"
        case .balcony: return "leaf.fill"
        case .other: return "location.fill"
        }
    }
}

// MARK: - 容器类型枚举

enum ContainerType: String, CaseIterable {
    case glassJar = "玻璃罐"
    case plasticContainer = "塑料容器"
    case ceramicPot = "陶瓷罐"
    case woodenBarrel = "木桶"
    case metalContainer = "金属容器"
    case other = "其他"

    var icon: String {
        switch self {
        case .glassJar: return "drop.fill"
        case .plasticContainer: return "cube.fill"
        case .ceramicPot: return "circle.fill"
        case .woodenBarrel: return "tree.fill"
        case .metalContainer: return "shippingbox.fill"
        case .other: return "questionmark.circle"
        }
    }

    var recommendation: String {
        switch self {
        case .glassJar:
            return "最佳选择，透明易观察，不会产生异味"
        case .plasticContainer:
            return "建议使用食品级PP材质，避免长期高温"
        case .ceramicPot:
            return "传统选择，保温性好，但不透明"
        case .woodenBarrel:
            return "适合大批量发酵，需要定期维护"
        case .metalContainer:
            return "避免使用铁质容器，不锈钢可以"
        case .other:
            return "确保容器清洁、无异味、食品安全"
        }
    }
}

// MARK: - 环境分析服务

class EnvironmentAnalyzer {

    /// 分析环境数据并提供建议
    static func analyze(_ environment: EnvironmentData, fermentationType: String) -> EnvironmentAnalysis {
        var warnings: [String] = []
        var tips: [String] = []
        var score: Double = 100

        // 温度分析
        if let temp = environment.temperature {
            if temp < 15 {
                warnings.append("温度过低，发酵速度会非常慢")
                tips.append("建议移至温暖处或使用加热垫")
                score -= 30
            } else if temp < 20 {
                tips.append("温度偏低，发酵时间可能延长")
                score -= 10
            } else if temp > 35 {
                warnings.append("温度过高，可能产生有害菌")
                tips.append("立即移至阴凉处")
                score -= 40
            } else if temp > 28 {
                tips.append("温度偏高，注意观察是否有异常")
                score -= 15
            }
        }

        // 湿度分析
        if let humid = environment.humidity {
            if humid < 40 {
                tips.append("湿度较低，容器表面可能干燥")
                score -= 5
            } else if humid > 85 {
                warnings.append("湿度过高，注意防霉")
                score -= 10
            }
        }

        // 位置建议
        if environment.location == "冰箱" && fermentationType != "泡菜" {
            warnings.append("冰箱温度可能过低，不适合大多数发酵")
        }

        // 容器建议
        if environment.containerType == "金属容器" {
            warnings.append("金属容器可能与酸性物质反应")
        }

        let status: EnvironmentStatus
        if score >= 90 {
            status = .excellent
        } else if score >= 70 {
            status = .good
        } else if score >= 50 {
            status = .warning
        } else {
            status = .danger
        }

        return EnvironmentAnalysis(
            status: status,
            score: score,
            warnings: warnings,
            tips: tips
        )
    }

    /// 获取理想环境参数
    static func getIdealParameters(for type: String) -> IdealEnvironment {
        switch type {
        case "酸面团", "鲁邦":
            return IdealEnvironment(
                temperatureRange: 24...28,
                humidityRange: 65...75,
                location: "厨房温暖处",
                container: "玻璃罐",
                notes: "保持稳定温度，避免温差过大"
            )

        case "康普茶":
            return IdealEnvironment(
                temperatureRange: 22...26,
                humidityRange: 60...70,
                location: "阴凉通风处",
                container: "玻璃罐",
                notes: "避免阳光直射，保持通气"
            )

        case "泡菜", "酸菜":
            return IdealEnvironment(
                temperatureRange: 18...25,
                humidityRange: 60...80,
                location: "阴凉处或冰箱",
                container: "陶瓷罐或玻璃罐",
                notes: "温度越低发酵越慢但风味更好"
            )

        case "酸奶":
            return IdealEnvironment(
                temperatureRange: 40...45,
                humidityRange: nil,
                location: "恒温设备",
                container: "玻璃罐或专用容器",
                notes: "需要恒温环境，通常使用酸奶机"
            )

        default:
            return IdealEnvironment(
                temperatureRange: 20...28,
                humidityRange: 60...75,
                location: "室温阴凉处",
                container: "玻璃罐",
                notes: "保持清洁，避免污染"
            )
        }
    }
}

// MARK: - 辅助数据结构

enum EnvironmentStatus {
    case excellent  // 优秀
    case good       // 良好
    case warning    // 需要注意
    case danger     // 危险

    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .warning: return "orange"
        case .danger: return "red"
        }
    }

    var displayName: String {
        switch self {
        case .excellent: return "优秀"
        case .good: return "良好"
        case .warning: return "需要注意"
        case .danger: return "危险"
        }
    }
}

struct EnvironmentAnalysis {
    let status: EnvironmentStatus
    let score: Double
    let warnings: [String]
    let tips: [String]

    var hasWarnings: Bool {
        !warnings.isEmpty
    }

    var hasTips: Bool {
        !tips.isEmpty
    }
}

struct IdealEnvironment {
    let temperatureRange: ClosedRange<Double>
    let humidityRange: ClosedRange<Double>?
    let location: String
    let container: String
    let notes: String

    var temperatureDescription: String {
        "\(Int(temperatureRange.lowerBound))-\(Int(temperatureRange.upperBound))°C"
    }

    var humidityDescription: String {
        guard let range = humidityRange else { return "无特殊要求" }
        return "\(Int(range.lowerBound))-\(Int(range.upperBound))%"
    }
}

// MARK: - 扩展Record以支持环境数据

extension Record {
    /// 添加环境数据
    func addEnvironmentData(_ environment: EnvironmentData) {
        // 在实际使用中，需要在SwiftData中建立关系
        // 这里提供方法接口
    }

    /// 是否有环境数据
    var hasEnvironmentData: Bool {
        // 实际实现需要查询关联的EnvironmentData
        return false
    }
}
