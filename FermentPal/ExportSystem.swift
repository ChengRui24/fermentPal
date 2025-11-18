//
//  ExportSystem.swift
//  FermentPal
//
//  数据导出与备份系统 - P2优化
//  支持JSON、Markdown、PDF等多种格式的导出
//

import Foundation
import SwiftData

// MARK: - 导出服务

class ExportService {

    // MARK: - JSON导出

    /// 导出单个发酵罐为JSON
    static func exportToJSON(_ fermentation: Fermentation) throws -> Data {
        let exportData = FermentationExportData(from: fermentation)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(exportData)
    }

    /// 导出所有发酵罐为JSON
    static func exportAllToJSON(_ fermentations: [Fermentation]) throws -> Data {
        let exportData = fermentations.map { FermentationExportData(from: $0) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(exportData)
    }

    /// 从JSON导入
    static func importFromJSON(_ data: Data) throws -> [FermentationExportData] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // 尝试作为数组解析
        if let fermentations = try? decoder.decode([FermentationExportData].self, from: data) {
            return fermentations
        }

        // 尝试作为单个对象解析
        if let fermentation = try? decoder.decode(FermentationExportData.self, from: data) {
            return [fermentation]
        }

        throw ExportError.invalidFormat
    }

    // MARK: - Markdown导出

    /// 导出为Markdown格式
    static func exportToMarkdown(_ fermentation: Fermentation) -> String {
        var markdown = ""

        // 标题
        markdown += "# \(fermentation.name)\n\n"

        // 基本信息
        markdown += "## 基本信息\n\n"
        markdown += "- **状态**：\(fermentation.safeStatus.displayName)\n"
        markdown += "- **创建时间**：\(formatDate(fermentation.createdAt))\n"
        markdown += "- **发酵天数**：\(fermentation.durationDays)天\n"

        if let parent = fermentation.parent {
            markdown += "- **来源**：\(parent.name)\n"
        }

        if let label = fermentation.label {
            markdown += "- **标签**：\(label)\n"
        }

        markdown += "\n"

        // 子项
        if !fermentation.children.isEmpty {
            markdown += "## 子项 (\(fermentation.children.count))\n\n"
            for child in fermentation.children.sorted(by: { $0.createdAt > $1.createdAt }) {
                markdown += "- [\(child.safeStatus.displayName)] \(child.name)"
                if let label = child.label {
                    markdown += " (\(label))"
                }
                markdown += "\n"
            }
            markdown += "\n"
        }

        // 记录时间线
        if !fermentation.records.isEmpty {
            markdown += "## 记录时间线 (\(fermentation.records.count)条)\n\n"

            let sortedRecords = fermentation.records.sorted { $0.createdAt > $1.createdAt }
            for record in sortedRecords {
                markdown += "### \(formatDate(record.createdAt))\n\n"
                markdown += "**状态**：\(record.safeStatus.displayName)\n\n"
                markdown += "\(record.content)\n\n"

                if record.isFeeding, let feeding = record.feedingContent {
                    markdown += "**投料**：\(feeding)\n\n"
                }

                if record.hasImages {
                    markdown += "*附带\(record.imageCount)张图片*\n\n"
                }

                markdown += "---\n\n"
            }
        }

        // 提醒
        if !fermentation.reminders.isEmpty {
            markdown += "## 提醒设置\n\n"
            for reminder in fermentation.reminders.sorted(by: { $0.remindTime < $1.remindTime }) {
                let status = reminder.isActive ? "✅" : "❌"
                markdown += "- \(status) \(formatDate(reminder.remindTime)) - \(reminder.content) (\(reminder.safeRepeatType.displayName))\n"
            }
            markdown += "\n"
        }

        // 统计
        markdown += "## 统计信息\n\n"
        markdown += "- 总记录数：\(fermentation.records.count)\n"
        markdown += "- 子项数量：\(fermentation.children.count)\n"
        markdown += "- 后代总数：\(fermentation.descendantCount)\n"
        markdown += "- 最后活动：\(formatDate(fermentation.lastActivityTime))\n\n"

        markdown += "---\n"
        markdown += "*由发酵笔记FermentPal生成于\(formatDate(Date()))*\n"

        return markdown
    }

    // MARK: - CSV导出

    /// 导出记录为CSV
    static func exportRecordsToCSV(_ fermentation: Fermentation) -> String {
        var csv = "日期,时间,状态,内容,是否投料,投料内容,图片数量\n"

        let sortedRecords = fermentation.records.sorted { $0.createdAt < $1.createdAt }
        for record in sortedRecords {
            let date = formatDateOnly(record.createdAt)
            let time = formatTimeOnly(record.createdAt)
            let status = record.safeStatus.displayName
            let content = escapeCSV(record.content)
            let isFeeding = record.isFeeding ? "是" : "否"
            let feedingContent = escapeCSV(record.feedingContent ?? "")
            let imageCount = "\(record.imageCount)"

            csv += "\(date),\(time),\(status),\(content),\(isFeeding),\(feedingContent),\(imageCount)\n"
        }

        return csv
    }

    // MARK: - 辅助方法

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func formatDateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }
}

// MARK: - 导出数据模型

struct FermentationExportData: Codable {
    let name: String
    let status: String
    let createdAt: Date
    let updatedAt: Date
    let label: String?
    let records: [RecordExportData]
    let reminders: [ReminderExportData]
    let children: [String]  // 子项名称列表
    let parentName: String?

    init(from fermentation: Fermentation) {
        self.name = fermentation.name
        self.status = fermentation.status
        self.createdAt = fermentation.createdAt
        self.updatedAt = fermentation.updatedAt
        self.label = fermentation.label
        self.records = fermentation.records.map { RecordExportData(from: $0) }
        self.reminders = fermentation.reminders.map { ReminderExportData(from: $0) }
        self.children = fermentation.children.map { $0.name }
        self.parentName = fermentation.parent?.name
    }
}

struct RecordExportData: Codable {
    let content: String
    let status: String
    let isFeeding: Bool
    let feedingContent: String?
    let createdAt: Date
    let imageCount: Int

    init(from record: Record) {
        self.content = record.content
        self.status = record.status
        self.isFeeding = record.isFeeding
        self.feedingContent = record.feedingContent
        self.createdAt = record.createdAt
        self.imageCount = record.images.count
    }
}

struct ReminderExportData: Codable {
    let remindTime: Date
    let content: String
    let repeatType: String
    let isActive: Bool

    init(from reminder: Reminder) {
        self.remindTime = reminder.remindTime
        self.content = reminder.content
        self.repeatType = reminder.repeatType
        self.isActive = reminder.isActive
    }
}

// MARK: - 备份管理器

class BackupManager {

    /// 创建完整备份
    static func createBackup(fermentations: [Fermentation]) throws -> BackupData {
        let exportData = fermentations.map { FermentationExportData(from: $0) }

        return BackupData(
            version: "1.0",
            createdAt: Date(),
            deviceName: "iPhone",  // 实际使用时获取真实设备名
            fermentationCount: fermentations.count,
            data: exportData
        )
    }

    /// 保存备份到文件
    static func saveBackupToFile(_ backup: BackupData, filename: String? = nil) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(backup)

        let fileName = filename ?? "FermentPal_Backup_\(formatFileNameDate(Date())).json"
        let fileURL = try getBackupDirectory().appendingPathComponent(fileName)

        try data.write(to: fileURL)
        return fileURL
    }

    /// 从文件恢复备份
    static func restoreBackupFromFile(_ url: URL) throws -> BackupData {
        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(BackupData.self, from: data)
    }

    /// 获取备份目录
    private static func getBackupDirectory() throws -> URL {
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let backupURL = documentsURL.appendingPathComponent("Backups", isDirectory: true)

        if !fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.createDirectory(at: backupURL, withIntermediateDirectories: true)
        }

        return backupURL
    }

    /// 列出所有备份
    static func listBackups() throws -> [BackupInfo] {
        let backupDirectory = try getBackupDirectory()
        let fileManager = FileManager.default

        let fileURLs = try fileManager.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
            options: .skipsHiddenFiles
        )

        return try fileURLs
            .filter { $0.pathExtension == "json" }
            .map { url in
                let attributes = try fileManager.attributesOfItem(atPath: url.path)
                let size = attributes[.size] as? Int64 ?? 0
                let creationDate = attributes[.creationDate] as? Date ?? Date()

                return BackupInfo(
                    url: url,
                    fileName: url.lastPathComponent,
                    createdAt: creationDate,
                    fileSize: size
                )
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// 删除备份
    static func deleteBackup(_ backup: BackupInfo) throws {
        try FileManager.default.removeItem(at: backup.url)
    }

    private static func formatFileNameDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: date)
    }
}

// MARK: - 备份数据结构

struct BackupData: Codable {
    let version: String
    let createdAt: Date
    let deviceName: String
    let fermentationCount: Int
    let data: [FermentationExportData]
}

struct BackupInfo: Identifiable {
    let id = UUID()
    let url: URL
    let fileName: String
    let createdAt: Date
    let fileSize: Int64

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

// MARK: - 错误类型

enum ExportError: LocalizedError {
    case invalidFormat
    case encodingFailed
    case decodingFailed
    case fileNotFound
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "文件格式无效"
        case .encodingFailed:
            return "编码失败"
        case .decodingFailed:
            return "解码失败"
        case .fileNotFound:
            return "文件未找到"
        case .permissionDenied:
            return "没有文件访问权限"
        }
    }
}

// MARK: - 分享助手

class ShareHelper {

    /// 生成分享文本
    static func generateShareText(_ fermentation: Fermentation) -> String {
        var text = "📝 我的发酵笔记：\(fermentation.name)\n\n"

        text += "📊 状态：\(fermentation.safeStatus.displayName)\n"
        text += "📅 发酵天数：\(fermentation.durationDays)天\n"
        text += "📝 记录：\(fermentation.records.count)条\n"

        if fermentation.safeStatus == .completed {
            text += "\n✅ 成功完成！\n"
        }

        text += "\n#发酵笔记 #FermentPal"

        return text
    }

    /// 生成精美分享图片数据（占位实现）
    static func generateShareImage(_ fermentation: Fermentation) -> Data? {
        // TODO: 实际实现需要使用UIGraphicsImageRenderer生成图片
        // 包含：名称、状态、时长、主要指标
        return nil
    }
}
