//
//  FermentationTypes.swift
//  FermentPal
//
//  类型安全的枚举定义 - 替代魔法字符串
//

import Foundation
import SwiftUI

// MARK: - 发酵状态

enum FermentationStatus: String, Codable, CaseIterable {
    case active = "active"
    case completed = "completed"
    case discarded = "discarded"

    var displayName: String {
        switch self {
        case .active: return "进行中"
        case .completed: return "已完成"
        case .discarded: return "已废弃"
        }
    }

    var color: Color {
        switch self {
        case .active: return .green
        case .completed: return .blue
        case .discarded: return .gray
        }
    }

    var icon: String {
        switch self {
        case .active: return "circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .discarded: return "xmark.circle.fill"
        }
    }
}

// MARK: - 记录状态

enum RecordStatus: String, Codable, CaseIterable {
    case normal = "normal"
    case watch = "watch"
    case abnormal = "abnormal"

    var displayName: String {
        switch self {
        case .normal: return "正常"
        case .watch: return "需关注"
        case .abnormal: return "异常"
        }
    }

    var color: Color {
        switch self {
        case .normal: return .green
        case .watch: return .orange
        case .abnormal: return .red
        }
    }
}

// MARK: - 分装标签

enum DistributionLabel: String, Codable, CaseIterable {
    case seed = "留种"
    case secondary = "二发"
    case use = "使用"

    var icon: String {
        switch self {
        case .seed: return "leaf.fill"
        case .secondary: return "bubbles.and.sparkles"
        case .use: return "fork.knife"
        }
    }

    var description: String {
        switch self {
        case .seed: return "继续发酵，作为下一代种子"
        case .secondary: return "二次发酵，添加风味（如康普茶、面包）"
        case .use: return "立即使用，不再发酵（自动标记为已完成）"
        }
    }

    var targetStatus: FermentationStatus {
        switch self {
        case .seed, .secondary: return .active
        case .use: return .completed
        }
    }
}

// MARK: - 提醒重复类型

enum ReminderRepeatType: String, Codable, CaseIterable {
    case once = "once"
    case daily = "daily"
    case every2days = "every2days"
    case weekly = "weekly"

    var displayName: String {
        switch self {
        case .once: return "仅一次"
        case .daily: return "每天"
        case .every2days: return "每2天"
        case .weekly: return "每周"
        }
    }

    /// 计算下一次提醒时间
    func nextRemindTime(from date: Date) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .once:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .every2days:
            return calendar.date(byAdding: .day, value: 2, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        }
    }
}

// MARK: - 错误类型

enum FermentationError: LocalizedError {
    case invalidName(String)
    case nameTooLong(Int)
    case saveFailed(Error)
    case notFound
    case invalidFeedingContent
    case distributionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidName(let name):
            return "发酵罐名称无效：'\(name)'"
        case .nameTooLong(let length):
            return "发酵罐名称过长（\(length)字符），最多50字符"
        case .saveFailed(let error):
            return "保存失败：\(error.localizedDescription)"
        case .notFound:
            return "未找到发酵罐"
        case .invalidFeedingContent:
            return "投料内容格式无效"
        case .distributionFailed(let reason):
            return "分装失败：\(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidName:
            return "请输入有效的发酵罐名称"
        case .nameTooLong:
            return "请缩短名称至50字符以内"
        case .saveFailed:
            return "请稍后重试或检查存储空间"
        case .notFound:
            return "发酵罐可能已被删除"
        case .invalidFeedingContent:
            return "请输入有效的投料内容，如：面粉100g、水90ml"
        case .distributionFailed:
            return "请检查输入信息并重试"
        }
    }
}

// MARK: - 验证工具

struct FermentationValidator {
    static func validateName(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw FermentationError.invalidName(name)
        }

        guard trimmed.count <= 50 else {
            throw FermentationError.nameTooLong(trimmed.count)
        }

        return trimmed
    }

    static func validateFeedingContent(_ content: String) -> String? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - 扩展说明
// 注意：Fermentation, Record, Reminder的扩展已在Item.swift中定义
// 避免重复声明
