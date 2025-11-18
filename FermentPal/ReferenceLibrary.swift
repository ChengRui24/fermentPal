//
//  ReferenceLibrary.swift
//  FermentPal
//
//  参考案例库与新手引导系统 - P2优化
//  提供成功/失败案例参考，帮助新手学习
//

import Foundation
import SwiftUI

// MARK: - 参考案例模型

struct ReferenceCase: Identifiable {
    let id = UUID()
    let type: FermentationType
    let stage: String
    let status: CaseStatus
    let title: String
    let description: String
    let images: [String]         // 参考图片（实际使用时替换为真实图片）
    let indicators: [Indicator]
    let timeline: [TimelineEntry]
    let tips: [String]
    let commonMistakes: [String]

    var isSuccess: Bool {
        status == .success
    }

    var isFailure: Bool {
        status == .failure
    }
}

enum FermentationType: String, CaseIterable, Hashable {
    case sourdough = "酸面团/鲁邦"
    case kombucha = "康普茶"
    case kimchi = "泡菜/酸菜"
    case yogurt = "酸奶"

    var displayName: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .sourdough: return "leaf.fill"
        case .kombucha: return "drop.fill"
        case .kimchi: return "carrot.fill"
        case .yogurt: return "cup.and.saucer.fill"
        }
    }
}

enum CaseStatus {
    case success
    case failure

    var displayName: String {
        self == .success ? "成功案例" : "失败案例"
    }

    var color: Color {
        self == .success ? .green : .red
    }
}

struct Indicator {
    let name: String
    let value: String
    let isNormal: Bool
}

struct TimelineEntry {
    let day: Int
    let hour: Int?
    let description: String
    let imageIndex: Int?
}

// MARK: - 预置参考案例

class ReferenceCaseLibrary {

    static let sourdoughCases: [ReferenceCase] = [
        // 成功案例 1
        ReferenceCase(
            type: .sourdough,
            stage: "喂养后12小时",
            status: .success,
            title: "健康的鲁邦种",
            description: "喂养12小时后的理想状态：体积翻倍，气泡均匀密集，表面隆起，有怡人的酸香味",
            images: ["sourdough_success_12h"],
            indicators: [
                Indicator(name: "体积", value: "翻倍(x2)", isNormal: true),
                Indicator(name: "气泡", value: "细密均匀", isNormal: true),
                Indicator(name: "气味", value: "酸香/酒香", isNormal: true),
                Indicator(name: "颜色", value: "乳白色/微黄", isNormal: true)
            ],
            timeline: [
                TimelineEntry(day: 0, hour: 0, description: "喂养：留种100g + 面粉100g + 水90g", imageIndex: 0),
                TimelineEntry(day: 0, hour: 4, description: "开始有小气泡出现", imageIndex: nil),
                TimelineEntry(day: 0, hour: 8, description: "体积明显增大，气泡增多", imageIndex: nil),
                TimelineEntry(day: 0, hour: 12, description: "达到顶峰，体积翻倍", imageIndex: 1)
            ],
            tips: [
                "最佳使用时间：达到顶峰后2小时内",
                "室温25°C时通常需要8-12小时",
                "温度越高，发酵越快",
                "使用前可以做浮水测试：放一小勺到水里，能浮起就说明活力充足"
            ],
            commonMistakes: [
                "❌ 喂养比例不当（太多或太少留种）",
                "❌ 温度过低（低于20°C发酵很慢）",
                "❌ 容器不清洁（可能引入杂菌）"
            ]
        ),

        // 成功案例 2
        ReferenceCase(
            type: .sourdough,
            stage: "长期维护",
            status: .success,
            title: "活力充沛的老种",
            description: "维护良好的老鲁邦，每12小时喂养一次，活力稳定",
            images: ["sourdough_success_maintained"],
            indicators: [
                Indicator(name: "发酵时间", value: "8-10小时达峰", isNormal: true),
                Indicator(name: "味道", value: "平衡的酸香", isNormal: true),
                Indicator(name: "状态", value: "稳定可预测", isNormal: true)
            ],
            timeline: [],
            tips: [
                "建立规律：固定时间喂养",
                "观察规律：记录每次达峰时间",
                "调整比例：根据需求调整喂养量",
                "冰箱保存：1周不用可放冰箱，延长喂养间隔"
            ],
            commonMistakes: []
        ),

        // 失败案例 1
        ReferenceCase(
            type: .sourdough,
            stage: "喂养后24小时",
            status: .failure,
            title: "活力不足的种",
            description: "喂养24小时后仍然没有明显变化，几乎无气泡，无酸香味",
            images: ["sourdough_failure_weak"],
            indicators: [
                Indicator(name: "体积", value: "几乎无变化", isNormal: false),
                Indicator(name: "气泡", value: "很少或没有", isNormal: false),
                Indicator(name: "气味", value: "无明显气味", isNormal: false)
            ],
            timeline: [],
            tips: [
                "可能原因：",
                "1. 菌种活力不足或已死亡",
                "2. 温度过低（低于15°C）",
                "3. 喂养比例不当",
                "",
                "补救方法：",
                "1. 提高环境温度到25-28°C",
                "2. 减小喂养比例（如1:0.5:0.5）",
                "3. 连续喂养3-5天观察",
                "4. 如无改善，考虑重新培养"
            ],
            commonMistakes: [
                "❌ 温度不够",
                "❌ 喂养过多导致菌种稀释",
                "❌ 使用了含氯的自来水"
            ]
        ),

        // 失败案例 2
        ReferenceCase(
            type: .sourdough,
            stage: "异常状态",
            status: .failure,
            title: "长霉的鲁邦",
            description: "表面出现白色或彩色霉斑，有异味",
            images: ["sourdough_failure_mold"],
            indicators: [
                Indicator(name: "霉斑", value: "白色/绿色/黑色", isNormal: false),
                Indicator(name: "气味", value: "臭味/霉味", isNormal: false),
                Indicator(name: "处理", value: "建议丢弃", isNormal: false)
            ],
            timeline: [],
            tips: [
                "⚠️ 长霉的鲁邦不安全，建议丢弃",
                "预防措施：",
                "1. 保持容器清洁",
                "2. 使用干净的工具",
                "3. 避免污染物进入",
                "4. 定期喂养，不要放置过久"
            ],
            commonMistakes: [
                "❌ 容器不干净",
                "❌ 长时间不喂养",
                "❌ 环境潮湿通风不良"
            ]
        )
    ]

    static let kombuchaCases: [ReferenceCase] = [
        ReferenceCase(
            type: .kombucha,
            stage: "一发第7天",
            status: .success,
            title: "成功的一发",
            description: "7天后表面形成健康的菌膜，酸甜适中",
            images: ["kombucha_success_7d"],
            indicators: [
                Indicator(name: "菌膜", value: "完整均匀", isNormal: true),
                Indicator(name: "pH值", value: "2.5-3.5", isNormal: true),
                Indicator(name: "味道", value: "酸甜平衡", isNormal: true),
                Indicator(name: "颜色", value: "清澈微黄", isNormal: true)
            ],
            timeline: [
                TimelineEntry(day: 0, hour: nil, description: "配料：红茶1L + 白糖70g + SCOBY", imageIndex: 0),
                TimelineEntry(day: 2, hour: nil, description: "表面开始形成薄膜", imageIndex: nil),
                TimelineEntry(day: 4, hour: nil, description: "菌膜逐渐变厚", imageIndex: nil),
                TimelineEntry(day: 7, hour: nil, description: "完成，可以分装二发", imageIndex: 1)
            ],
            tips: [
                "理想温度：22-26°C",
                "避免阳光直射",
                "用纱布覆盖，保持通气",
                "pH值2.5-3.5之间最佳",
                "味道测试：酸甜平衡即可分装"
            ],
            commonMistakes: [
                "❌ 温度过低导致发酵缓慢",
                "❌ 密封容器导致无法呼吸",
                "❌ 使用金属容器"
            ]
        )
    ]

    static func getAllCases() -> [ReferenceCase] {
        return sourdoughCases + kombuchaCases
    }

    static func getCases(for type: FermentationType) -> [ReferenceCase] {
        getAllCases().filter { $0.type == type }
    }

    static func getSuccessCases(for type: FermentationType) -> [ReferenceCase] {
        getCases(for: type).filter { $0.status == .success }
    }

    static func getFailureCases(for type: FermentationType) -> [ReferenceCase] {
        getCases(for: type).filter { $0.status == .failure }
    }
}

// MARK: - 新手引导系统

struct OnboardingStep {
    let id: Int
    let icon: String
    let title: String
    let description: String
    let tips: [String]
}

class OnboardingGuide {

    static let steps: [OnboardingStep] = [
        OnboardingStep(
            id: 1,
            icon: "plus.circle.fill",
            title: "创建发酵罐",
            description: "记录你的第一个发酵项目",
            tips: [
                "给它起个好记的名字，比如\"苹果鲁邦第1代\"",
                "可以拍照记录初始状态",
                "添加初始投料信息"
            ]
        ),
        OnboardingStep(
            id: 2,
            icon: "doc.text.fill",
            title: "定期记录",
            description: "观察并记录发酵状态变化",
            tips: [
                "每天至少记录一次",
                "描述颜色、气味、质地的变化",
                "拍照对比很有帮助"
            ]
        ),
        OnboardingStep(
            id: 3,
            icon: "bell.fill",
            title: "设置提醒",
            description: "不要忘记关键的时间点",
            tips: [
                "为喂养设置定时提醒",
                "为检查设置周期提醒",
                "重要：一定要开启通知权限！"
            ]
        ),
        OnboardingStep(
            id: 4,
            icon: "arrow.branch",
            title: "分装管理",
            description: "记录传代和分装关系",
            tips: [
                "分装时记录来源",
                "标记用途（留种/二发/使用）",
                "家谱视图可以看到完整关系"
            ]
        ),
        OnboardingStep(
            id: 5,
            icon: "chart.line.uptrend.xyaxis",
            title: "分析优化",
            description: "从数据中学习和改进",
            tips: [
                "查看成功率和趋势",
                "对比不同配方",
                "参考案例库学习"
            ]
        )
    ]

    static let quickStartTemplates: [QuickStartTemplate] = [
        QuickStartTemplate(
            type: .sourdough,
            name: "酸面团入门",
            description: "从零开始培养鲁邦种",
            duration: "7天",
            difficulty: .beginner,
            steps: [
                "Day 1: 全麦粉50g + 水50g，混合放置",
                "Day 2-3: 每天丢弃一半，补充50g粉+50g水",
                "Day 4-7: 观察气泡，开始有酸香即成功",
                "之后: 每12-24小时喂养维护"
            ]
        ),
        QuickStartTemplate(
            type: .kombucha,
            name: "康普茶入门",
            description: "制作第一批康普茶",
            duration: "10-14天",
            difficulty: .beginner,
            steps: [
                "准备：购买SCOBY（菌膜）和引子液",
                "配料：红茶1L + 白糖70g，放凉",
                "混合：加入SCOBY和200ml引子液",
                "发酵：室温22-26°C，7-10天",
                "品尝：酸甜适中即可分装二发"
            ]
        )
    ]
}

struct QuickStartTemplate {
    let type: FermentationType
    let name: String
    let description: String
    let duration: String
    let difficulty: Difficulty
    let steps: [String]
}

enum Difficulty: String {
    case beginner = "入门"
    case intermediate = "中级"
    case advanced = "高级"

    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - 帮助与提示系统

class HelpTipsProvider {

    /// 获取上下文相关的提示
    static func getContextualTips(for context: HelpContext) -> [String] {
        switch context {
        case .createFermentation:
            return [
                "💡 名称建议包含类型和代数，如\"苹果鲁邦第3代\"",
                "📷 拍照记录初始状态，方便对比",
                "📝 添加备注说明特殊情况",
                "⏰ 创建后立即设置第一个提醒"
            ]

        case .addRecord:
            return [
                "👀 观察：颜色、气味、质地、气泡",
                "📏 测量：体积变化、温度、pH值",
                "📷 拍照：定期拍照方便对比",
                "🍴 投料：详细记录成分和用量"
            ]

        case .distributeJar:
            return [
                "🏷️ 清楚标记每个分装的用途",
                "📝 记录分装时的状态",
                "🔢 建议2-5个分装，不宜过多",
                "⏰ 为每个分装设置独立提醒"
            ]

        case .setReminder:
            return [
                "⏰ 固定时间更容易养成习惯",
                "🔁 重复提醒适合定期喂养",
                "📱 确保开启通知权限",
                "💡 可以设置多个提醒（检查、喂养、品尝）"
            ]

        case .viewGenealogy:
            return [
                "🌳 点击节点查看详情",
                "🔍 使用筛选功能快速定位",
                "📊 查看统计了解整体情况",
                "🎨 颜色代表状态（绿=进行中，蓝=完成）"
            ]
        }
    }

    /// 获取故障排除建议
    static func getTroubleshootingTips(for problem: CommonProblem) -> [String] {
        switch problem {
        case .noActivity:
            return [
                "检查温度：应该在20-28°C",
                "检查菌种：可能活力不足",
                "减少喂养量：提高菌种浓度",
                "更换面粉：尝试全麦粉",
                "耐心等待：温度低时需要更长时间"
            ]

        case .tooSour:
            return [
                "缩短发酵时间",
                "增加喂养频率",
                "降低温度",
                "调整留种比例（减少留种）"
            ]

        case .mold:
            return [
                "⚠️ 有霉斑建议丢弃，重新开始",
                "预防：保持容器清洁",
                "预防：定期喂养，不要放置过久",
                "预防：避免污染物进入"
            ]

        case .slowFermentation:
            return [
                "提高温度到25-28°C",
                "增加留种比例",
                "使用活力强的种",
                "确保面粉新鲜"
            ]
        }
    }
}

enum HelpContext {
    case createFermentation
    case addRecord
    case distributeJar
    case setReminder
    case viewGenealogy
}

enum CommonProblem {
    case noActivity
    case tooSour
    case mold
    case slowFermentation
}
