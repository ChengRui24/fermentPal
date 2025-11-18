//
//  FermentationService.swift
//  FermentPal
//
//  业务逻辑服务层 - 处理发酵相关的业务操作
//

import Foundation
import SwiftData

/// 发酵罐服务 - 封装业务逻辑
@Observable
class FermentationService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - 发酵罐操作

    /// 创建新的发酵罐
    func createFermentation(
        name: String,
        note: String? = nil,
        feedingContent: String? = nil
    ) throws -> Fermentation {
        // 验证名称
        let validatedName = try FermentationValidator.validateName(name)

        // 创建发酵罐
        let fermentation = Fermentation(name: validatedName, status: "active")
        modelContext.insert(fermentation)

        // 添加备注记录
        if let note = note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let noteRecord = Record(
                fermentation: fermentation,
                content: note,
                status: "normal"
            )
            modelContext.insert(noteRecord)
            fermentation.addRecord(noteRecord)
        }

        // 添加投料记录
        if let feeding = feedingContent,
           let validatedFeeding = FermentationValidator.validateFeedingContent(feeding) {
            let feedingRecord = Record(
                fermentation: fermentation,
                content: "初始投料",
                status: "normal",
                isFeeding: true,
                feedingContent: validatedFeeding
            )
            modelContext.insert(feedingRecord)
            fermentation.addRecord(feedingRecord)
        }

        // 保存
        try saveContext()

        return fermentation
    }

    /// 更新发酵罐状态
    func updateFermentationStatus(
        _ fermentation: Fermentation,
        to newStatus: FermentationStatus,
        note: String? = nil
    ) throws {
        let oldStatus = fermentation.safeStatus

        // 更新状态
        fermentation.updateStatus(to: newStatus)

        // 创建状态变更记录
        let noteText = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let content = noteText.isEmpty ?
            "状态变更：\(oldStatus.displayName) → \(newStatus.displayName)" :
            "状态变更：\(oldStatus.displayName) → \(newStatus.displayName) (\(noteText))"

        let record = Record(
            fermentation: fermentation,
            content: content,
            status: "normal"
        )
        modelContext.insert(record)
        fermentation.addRecord(record)

        try saveContext()
    }

    /// 删除发酵罐
    func deleteFermentation(_ fermentation: Fermentation) throws {
        modelContext.delete(fermentation)
        try saveContext()
    }

    // MARK: - 记录操作

    /// 添加记录
    func addRecord(
        to fermentation: Fermentation,
        content: String,
        status: RecordStatus = .normal,
        isFeeding: Bool = false,
        feedingContent: String? = nil,
        createdAt: Date = Date()
    ) throws -> Record {
        // 验证内容
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw FermentationError.invalidName("记录内容不能为空")
        }

        // 验证投料内容
        let validatedFeeding = FermentationValidator.validateFeedingContent(feedingContent ?? "")

        // 创建记录
        let record = Record(
            fermentation: fermentation,
            content: trimmedContent,
            status: status.rawValue,
            isFeeding: isFeeding,
            feedingContent: validatedFeeding,
            createdAt: createdAt
        )

        modelContext.insert(record)
        fermentation.addRecord(record)

        try saveContext()

        return record
    }

    /// 更新记录
    func updateRecord(
        _ record: Record,
        content: String,
        feedingContent: String?,
        createdAt: Date
    ) throws {
        record.updateContent(content)
        record.updateFeedingContent(feedingContent)
        record.createdAt = createdAt

        try saveContext()
    }

    /// 删除记录
    func deleteRecord(_ record: Record) throws {
        modelContext.delete(record)
        try saveContext()
    }

    // MARK: - 分装操作

    /// 执行分装操作
    func distribute(
        parent: Fermentation,
        children: [(name: String, label: DistributionLabel, feedingContent: String?)]
    ) throws {
        guard !children.isEmpty else {
            throw FermentationError.distributionFailed("至少需要创建一个子项")
        }

        var createdChildren: [Fermentation] = []

        // 创建子项
        for childInfo in children {
            // 验证名称
            let validatedName = try FermentationValidator.validateName(childInfo.name)

            // 根据标签确定状态
            let status = childInfo.label.targetStatus

            // 创建子项
            let child = Fermentation(
                name: validatedName,
                status: status.rawValue,
                label: childInfo.label.rawValue,
                parent: parent
            )
            modelContext.insert(child)
            createdChildren.append(child)

            // 创建初始记录
            let content = childInfo.label == .use ? "分装使用（已完成）" : "分装创建"

            let validatedFeeding = FermentationValidator.validateFeedingContent(childInfo.feedingContent ?? "")

            let record = Record(
                fermentation: child,
                content: content,
                status: "normal",
                isFeeding: validatedFeeding != nil,
                feedingContent: validatedFeeding,
                parentFermentation: parent
            )
            modelContext.insert(record)
            child.addRecord(record)
        }

        // 为父批次添加分装记录
        let summary = "分装创建 \(createdChildren.count) 个子批次"
        let parentRecord = Record(
            fermentation: parent,
            content: summary,
            status: "normal"
        )
        modelContext.insert(parentRecord)
        parent.addRecord(parentRecord)

        try saveContext()
    }

    // MARK: - 提醒操作

    /// 创建提醒
    func createReminder(
        for fermentation: Fermentation,
        remindTime: Date,
        content: String,
        repeatType: ReminderRepeatType = .once
    ) throws -> Reminder {
        // 验证内容
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw FermentationError.invalidName("提醒内容不能为空")
        }

        // 创建提醒
        let reminder = Reminder(
            fermentation: fermentation,
            remindTime: remindTime,
            content: trimmedContent,
            repeatType: repeatType.rawValue
        )

        modelContext.insert(reminder)
        fermentation.addReminder(reminder)

        try saveContext()

        return reminder
    }

    /// 更新提醒
    func updateReminder(
        _ reminder: Reminder,
        remindTime: Date,
        content: String,
        repeatType: ReminderRepeatType
    ) throws {
        reminder.updateRemindTime(to: remindTime)
        reminder.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        reminder.safeRepeatType = repeatType

        try saveContext()
    }

    /// 删除提醒
    func deleteReminder(_ reminder: Reminder) throws {
        modelContext.delete(reminder)
        try saveContext()
    }

    /// 切换提醒激活状态
    func toggleReminderActive(_ reminder: Reminder) throws {
        reminder.toggleActive()
        try saveContext()
    }

    // MARK: - 查询操作

    /// 获取活跃的发酵罐
    func getActiveFermentations(sortedBy keyPath: KeyPath<Fermentation, Date> = \.createdAt) -> [Fermentation] {
        let descriptor = FetchDescriptor<Fermentation>(
            predicate: #Predicate { $0.status == "active" },
            sortBy: [SortDescriptor(keyPath, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching active fermentations: \(error)")
            return []
        }
    }

    /// 获取已完成的发酵罐
    func getCompletedFermentations() -> [Fermentation] {
        let descriptor = FetchDescriptor<Fermentation>(
            predicate: #Predicate { $0.status != "active" },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching completed fermentations: \(error)")
            return []
        }
    }

    /// 搜索发酵罐
    func searchFermentations(query: String) -> [Fermentation] {
        guard !query.isEmpty else {
            return getActiveFermentations()
        }

        let descriptor = FetchDescriptor<Fermentation>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let allFermentations = try modelContext.fetch(descriptor)
            return allFermentations.filter {
                $0.name.localizedCaseInsensitiveContains(query)
            }
        } catch {
            print("Error searching fermentations: \(error)")
            return []
        }
    }

    /// 获取即将到期的提醒
    func getUpcomingReminders() -> [Reminder] {
        let descriptor = FetchDescriptor<Reminder>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.remindTime)]
        )

        do {
            let allReminders = try modelContext.fetch(descriptor)
            return allReminders.filter { $0.isUpcoming }
        } catch {
            print("Error fetching upcoming reminders: \(error)")
            return []
        }
    }

    // MARK: - 统计操作

    /// 获取统计信息
    func getStatistics() -> FermentationStatistics {
        let descriptor = FetchDescriptor<Fermentation>()

        do {
            let allFermentations = try modelContext.fetch(descriptor)

            let active = allFermentations.filter { $0.status == "active" }.count
            let completed = allFermentations.filter { $0.status == "completed" }.count
            let discarded = allFermentations.filter { $0.status == "discarded" }.count
            let roots = allFermentations.filter { $0.isRoot }.count

            return FermentationStatistics(
                total: allFermentations.count,
                active: active,
                completed: completed,
                discarded: discarded,
                roots: roots
            )
        } catch {
            print("Error fetching statistics: \(error)")
            return FermentationStatistics(total: 0, active: 0, completed: 0, discarded: 0, roots: 0)
        }
    }

    // MARK: - 私有辅助方法

    private func saveContext() throws {
        do {
            try modelContext.save()
        } catch {
            throw FermentationError.saveFailed(error)
        }
    }
}

// MARK: - 统计数据结构

struct FermentationStatistics {
    let total: Int
    let active: Int
    let completed: Int
    let discarded: Int
    let roots: Int

    var hasData: Bool {
        total > 0
    }
}

// MARK: - 分装信息结构

struct DistributionInfo {
    let name: String
    let label: DistributionLabel
    let feedingContent: String?

    init(name: String, label: DistributionLabel, feedingContent: String? = nil) {
        self.name = name
        self.label = label
        self.feedingContent = feedingContent
    }
}
