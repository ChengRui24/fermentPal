//
//  Item.swift
//  FermentPal
//
//  Created by CR on 23/9/25.
//

import Foundation
import SwiftData

@Model
final class Fermentation {
    var name: String
    var coverImagePath: String?
    var status: String // active, completed, discarded
    var createdAt: Date
    var updatedAt: Date
    var label: String?
    @Relationship(inverse: \Fermentation.children) var parent: Fermentation?
    @Relationship var children: [Fermentation]

    @Relationship(deleteRule: .cascade) var records: [Record]
    @Relationship(deleteRule: .cascade) var reminders: [Reminder]

    init(name: String,
         coverImagePath: String? = nil,
         status: String = "active",
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         label: String? = nil,
         parent: Fermentation? = nil) {
        // 验证名称
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.name = trimmedName.isEmpty ? "未命名发酵罐" : trimmedName

        self.coverImagePath = coverImagePath
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.label = label
        self.parent = parent
        self.children = []
        self.records = []
        self.reminders = []
    }

    // MARK: - 类型安全的访问

    /// 类型安全的状态访问
    var safeStatus: FermentationStatus {
        get { FermentationStatus(rawValue: status) ?? .active }
        set {
            status = newValue.rawValue
            updatedAt = Date()
        }
    }

    /// 类型安全的标签访问
    var safeLabel: DistributionLabel? {
        get {
            guard let label = label else { return nil }
            return DistributionLabel(rawValue: label)
        }
        set {
            label = newValue?.rawValue
            updatedAt = Date()
        }
    }

    // MARK: - 计算属性

    /// 发酵天数
    var durationDays: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }

    /// 发酵小时数
    var durationHours: Int {
        Calendar.current.dateComponents([.hour], from: createdAt, to: Date()).hour ?? 0
    }

    /// 是否为根节点（没有父节点）
    var isRoot: Bool {
        parent == nil
    }

    /// 是否为叶子节点（没有子节点）
    var isLeaf: Bool {
        children.isEmpty
    }

    /// 后代总数（递归计算）
    var descendantCount: Int {
        children.count + children.reduce(0) { $0 + $1.descendantCount }
    }

    /// 是否处于活跃状态
    var isActive: Bool {
        status == "active"
    }

    /// 最后一条记录
    var lastRecord: Record? {
        records.sorted { $0.createdAt > $1.createdAt }.first
    }

    /// 最后更新时间（记录或状态变更）
    var lastActivityTime: Date {
        let lastRecordTime = lastRecord?.createdAt ?? createdAt
        return max(lastRecordTime, updatedAt)
    }

    /// 格式化的发酵时长
    var formattedDuration: String {
        if durationDays == 0 {
            return "\(durationHours)小时"
        } else if durationDays == 1 {
            return "1天"
        } else {
            return "\(durationDays)天"
        }
    }

    // MARK: - 验证方法

    /// 验证名称是否有效
    func validateName(_ newName: String) throws {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw FermentationError.invalidName(newName)
        }

        guard trimmed.count <= 50 else {
            throw FermentationError.nameTooLong(trimmed.count)
        }
    }

    // MARK: - 业务方法

    /// 更新名称（带验证）
    func updateName(to newName: String) throws {
        try validateName(newName)
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.name = trimmed
        self.updatedAt = Date()
    }

    /// 更新状态
    func updateStatus(to newStatus: FermentationStatus) {
        self.status = newStatus.rawValue
        self.updatedAt = Date()
    }

    /// 添加记录
    func addRecord(_ record: Record) {
        records.append(record)
        updatedAt = Date()
    }

    /// 添加提醒
    func addReminder(_ reminder: Reminder) {
        reminders.append(reminder)
    }
}

@Model
final class Record {
    var fermentation: Fermentation?
    var content: String
    var status: String // normal, watch, abnormal
    var images: [String] // local file paths
    var isFeeding: Bool
    var feedingContent: String?
    var createdAt: Date
    var parentFermentation: Fermentation? // 引用父罐（用于分装记录）

    init(fermentation: Fermentation? = nil,
         content: String,
         status: String = "normal",
         images: [String] = [],
         isFeeding: Bool = false,
         feedingContent: String? = nil,
         createdAt: Date = Date(),
         parentFermentation: Fermentation? = nil) {
        self.fermentation = fermentation
        // 验证内容
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        self.content = trimmedContent.isEmpty ? "空记录" : trimmedContent
        self.status = status
        self.images = images
        self.isFeeding = isFeeding
        self.feedingContent = feedingContent?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
        self.parentFermentation = parentFermentation
    }

    // MARK: - 类型安全的访问

    /// 类型安全的状态访问
    var safeStatus: RecordStatus {
        get { RecordStatus(rawValue: status) ?? .normal }
        set { status = newValue.rawValue }
    }

    // MARK: - 计算属性

    /// 是否有图片
    var hasImages: Bool {
        !images.isEmpty
    }

    /// 图片数量
    var imageCount: Int {
        images.count
    }

    /// 是否为分装记录
    var isDistributionRecord: Bool {
        parentFermentation != nil
    }

    /// 记录类型描述
    var recordType: String {
        if isDistributionRecord {
            return "分装记录"
        } else if isFeeding {
            return "投料记录"
        } else {
            return "观察记录"
        }
    }

    /// 格式化的时间戳
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    // MARK: - 业务方法

    /// 更新内容
    func updateContent(_ newContent: String) {
        let trimmed = newContent.trimmingCharacters(in: .whitespacesAndNewlines)
        self.content = trimmed.isEmpty ? content : trimmed
    }

    /// 添加图片
    func addImage(_ imagePath: String) {
        guard !imagePath.isEmpty, !images.contains(imagePath) else { return }
        images.append(imagePath)
    }

    /// 移除图片
    func removeImage(_ imagePath: String) {
        images.removeAll { $0 == imagePath }
    }

    /// 更新投料内容
    func updateFeedingContent(_ content: String?) {
        let trimmed = content?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.feedingContent = trimmed?.isEmpty == true ? nil : trimmed
        self.isFeeding = feedingContent != nil
    }
}

@Model
final class Reminder {
    var fermentation: Fermentation?
    var remindTime: Date
    var content: String
    var repeatType: String // once, daily, every2days, weekly
    var isActive: Bool
    var createdAt: Date

    init(fermentation: Fermentation? = nil,
         remindTime: Date,
         content: String,
         repeatType: String = "once",
         isActive: Bool = true,
         createdAt: Date = Date()) {
        self.fermentation = fermentation
        self.remindTime = remindTime
        // 验证内容
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        self.content = trimmedContent.isEmpty ? "发酵提醒" : trimmedContent
        self.repeatType = repeatType
        self.isActive = isActive
        self.createdAt = createdAt
    }

    // MARK: - 类型安全的访问

    /// 类型安全的重复类型访问
    var safeRepeatType: ReminderRepeatType {
        get { ReminderRepeatType(rawValue: repeatType) ?? .once }
        set { repeatType = newValue.rawValue }
    }

    // MARK: - 计算属性

    /// 是否已过期
    var isExpired: Bool {
        remindTime < Date() && safeRepeatType == .once
    }

    /// 是否即将到期（24小时内）
    var isUpcoming: Bool {
        let now = Date()
        let dayLater = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        return remindTime >= now && remindTime <= dayLater
    }

    /// 距离提醒时间的秒数
    var timeUntilReminder: TimeInterval {
        remindTime.timeIntervalSinceNow
    }

    /// 格式化的提醒时间
    var formattedRemindTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: remindTime)
    }

    /// 相对时间描述（如"2小时后"）
    var relativeTimeDescription: String {
        let interval = timeUntilReminder
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if interval < 0 {
            return "已过期"
        } else if days > 0 {
            return "\(days)天后"
        } else if hours > 0 {
            return "\(hours)小时后"
        } else {
            let minutes = Int(interval / 60)
            return "\(max(1, minutes))分钟后"
        }
    }

    // MARK: - 业务方法

    /// 激活提醒
    func activate() {
        isActive = true
    }

    /// 停用提醒
    func deactivate() {
        isActive = false
    }

    /// 切换激活状态
    func toggleActive() {
        isActive.toggle()
    }

    /// 延后提醒
    func postpone(by interval: TimeInterval) {
        remindTime = remindTime.addingTimeInterval(interval)
    }

    /// 更新提醒时间
    func updateRemindTime(to newTime: Date) {
        remindTime = newTime
    }

    /// 计算下一次提醒时间
    func calculateNextRemindTime() -> Date? {
        guard safeRepeatType != .once else { return nil }
        return safeRepeatType.nextRemindTime(from: remindTime)
    }

    /// 重置为下一次提醒
    func moveToNextReminder() {
        if let nextTime = calculateNextRemindTime() {
            remindTime = nextTime
        }
    }
}
