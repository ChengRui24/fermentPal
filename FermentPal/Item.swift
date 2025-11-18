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
        self.name = name
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
    
    // 更新名称
    func updateName(to newName: String) {
        self.name = newName
        self.updatedAt = Date()
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
        self.content = content
        self.status = status
        self.images = images
        self.isFeeding = isFeeding
        self.feedingContent = feedingContent
        self.createdAt = createdAt
        self.parentFermentation = parentFermentation
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
        self.content = content
        self.repeatType = repeatType
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
