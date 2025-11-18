//
//  ContentView.swift
//  FermentPal
//
//  Created by CR on 23/9/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Fermentation.createdAt, order: .reverse) private var allFermentations: [Fermentation]
    @State private var isPresentingAddFermentation: Bool = false
    @State private var showingCompleted = false
    @State private var isPresentingGenealogy = false
    var selectedTab: Binding<Int>?

    // 服务层用于获取推荐
    private var service: FermentationService {
        FermentationService(modelContext: modelContext)
    }

    private var activeFermentations: [Fermentation] {
        allFermentations.filter { $0.status == "active" }
    }

    private var completedFermentations: [Fermentation] {
        allFermentations.filter { $0.status != "active" }
    }

    // 获取推荐数量
    private func recommendationCount(for fermentation: Fermentation) -> Int {
        service.getRecommendations(for: fermentation).count
    }

    // 是否有高优先级推荐
    private func hasHighPriorityRecommendations(for fermentation: Fermentation) -> Bool {
        service.getRecommendations(for: fermentation).contains { $0.priority == .high }
    }

    var body: some View {
        NavigationStack {
            List {
                // 活跃发酵罐
                Section {
                    if activeFermentations.isEmpty {
                        EmptyState(
                            icon: "flame",
                            title: "暂无活跃发酵罐",
                            message: "点击右上角 + 按钮创建你的第一个发酵罐",
                            actionTitle: nil,
                            action: nil
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(activeFermentations) { f in
                            NavigationLink(value: f) {
                                FermentationCard(
                                    fermentation: f,
                                    recommendationCount: recommendationCount(for: f),
                                    hasHighPriority: hasHighPriorityRecommendations(for: f)
                                )
                            }
                            .listRowInsets(EdgeInsets(top: .spacingSM, leading: .pageMargin, bottom: .spacingSM, trailing: .pageMargin))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteActiveFermentations)
                    }
                }

                // 历史批次（可折叠）
                if !completedFermentations.isEmpty {
                    Section {
                        if showingCompleted {
                            ForEach(completedFermentations) { f in
                                NavigationLink(value: f) {
                                    CompactFermentationCard(fermentation: f)
                                }
                                .listRowInsets(EdgeInsets(top: .spacingSM, leading: .pageMargin, bottom: .spacingSM, trailing: .pageMargin))
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        HStack {
                            Text("历史批次 (\(completedFermentations.count))")
                            Spacer()
                            Button(showingCompleted ? "隐藏" : "显示") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingCompleted.toggle()
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(Color.brandPrimary)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .background(Color.listBackground)
            .navigationTitle("发酵笔记")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { 
                        if let selectedTab = selectedTab {
                            selectedTab.wrappedValue = 1
                        } else {
                            isPresentingGenealogy = true
                        }
                    }) {
                        Label("家谱", systemImage: "tree")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isPresentingAddFermentation = true }) { Label("新建", systemImage: "plus") }
                }
            }
            .navigationDestination(for: Fermentation.self) { f in
                FermentationDetailView(fermentation: f)
            }
            .sheet(isPresented: $isPresentingAddFermentation) {
                NavigationStack { AddFermentationView() }
            }
            .sheet(isPresented: $isPresentingGenealogy) {
                GenealogyView()
            }
        }
    }

    private func deleteActiveFermentations(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(activeFermentations[index])
            }
        }
    }
}

private struct StatusBadge: View {
    let status: String
    var body: some View {
        EnhancedBadge(
            text: label,
            color: Color.forStatus(status),
            size: .small
        )
    }
    private var label: String {
        switch status {
        case "active": return "进行中"
        case "completed": return "已完成"
        case "discarded": return "已废弃"
        default: return status
        }
    }
}

struct FermentationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let fermentation: Fermentation
    @State private var isPresentingDistribute = false
    @State private var selectedTab = 1
    @State private var isPresentingEditName = false
    @State private var isPresentingEditStatus = false

    var body: some View {
        VStack(spacing: 0) {
            // 基本信息卡片
            VStack(spacing: 12) {
                HStack {
                    Text("名称")
                        .font(.headline)
                    Spacer()
                    HStack(spacing: 8) {
                        Text(fermentation.name)
                            .foregroundStyle(.primary)
                            .fontWeight(.medium)
                        Button(action: { isPresentingEditName = true }) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                HStack {
                    Text("状态")
                        .font(.headline)
                    Spacer()
                    HStack(spacing: 8) {
                        StatusBadge(status: fermentation.status)
                        Button(action: { isPresentingEditStatus = true }) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                // 如果有父项，显示父项信息
                if let parent = fermentation.parent {
                    HStack {
                        Text("来源罐")
                            .font(.headline)
                        Spacer()
                        NavigationLink(destination: FermentationDetailView(fermentation: parent)) {
                            HStack(spacing: 4) {
                                Text(parent.name)
                                    .foregroundStyle(.blue)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.right.circle")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                HStack {
                    Text("创建时间")
                        .font(.headline)
                    Spacer()
                    Text(fermentation.createdAt, style: .date)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // 自定义Tab指示器
            HStack(spacing: 0) {
                TabButton(title: "记录", icon: "list.bullet", isSelected: selectedTab == 1) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = 1
                    }
                }
                
                TabButton(title: "子项", icon: "square.stack.3d.up", isSelected: selectedTab == 0) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = 0
                    }
                }
            }
            .padding(.horizontal)
            
            // Tab切换视图
            TabView(selection: $selectedTab) {
                // 记录视图
                RecordsView(fermentation: fermentation)
                    .tag(1)
                
                // 子项视图
                ChildrenView(fermentation: fermentation)
                    .tag(0)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // 底部快速操作按钮（仅活跃批次）
            if fermentation.status == "active" {
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 20) {
                        Button(action: { isPresentingDistribute = true }) {
                            VStack(spacing: 4) {
                                Image(systemName: "square.stack.3d.up")
                                    .font(.title2)
                                Text("分装")
                                    .font(.caption)
                            }
                            .foregroundStyle(.blue)
                        }
                        
                        Spacer()
                        
                        NavigationLink(destination: AddRecordView(fermentation: fermentation)) {
                            VStack(spacing: 4) {
                                Image(systemName: "square.and.pencil")
                                    .font(.title2)
                                Text("记录")
                                    .font(.caption)
                            }
                            .foregroundStyle(.green)
                        }
                        
                        Spacer()
                        
                        NavigationLink(destination: RemindersView(fermentation: fermentation)) {
                            VStack(spacing: 4) {
                                Image(systemName: "alarm")
                                    .font(.title2)
                                Text("提醒")
                                    .font(.caption)
                            }
                            .foregroundStyle(.orange)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                }
            }
        }
        .navigationTitle(fermentation.name)
        .sheet(isPresented: $isPresentingDistribute) {
            NavigationStack { DistributeView(fermentation: fermentation) }
        }
        .sheet(isPresented: $isPresentingEditName) {
            NavigationStack { EditFermentationNameView(fermentation: fermentation) }
        }
        .sheet(isPresented: $isPresentingEditStatus) {
            NavigationStack { EditFermentationStatusView(fermentation: fermentation) }
        }
    }
}

struct EditFermentationNameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let fermentation: Fermentation
    
    @State private var newName: String = ""
    
    init(fermentation: Fermentation) {
        self.fermentation = fermentation
        self._newName = State(initialValue: fermentation.name)
    }
    
    var body: some View {
        Form {
            Section("发酵罐名称") {
                TextField("输入新的名称", text: $newName)
                    .textFieldStyle(.roundedBorder)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("修改说明")
                        .font(.headline)
                    Text("• 修改名称后，所有子项记录中的来源信息会自动更新")
                    Text("• 这个操作会影响所有相关的分装记录")
                    Text("• 建议使用描述性的名称，如'苹果鲁邦 第6代'")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("编辑名称")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newName == fermentation.name)
            }
        }
    }
    
    private func save() {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        fermentation.updateName(to: trimmedName)
        dismiss()
    }
}

struct EditFermentationStatusView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let fermentation: Fermentation
    
    @State private var selectedStatus: String = ""
    @State private var note: String = ""
    
    init(fermentation: Fermentation) {
        self.fermentation = fermentation
        self._selectedStatus = State(initialValue: fermentation.status)
    }
    
    var body: some View {
        Form {
            Section("当前状态") {
                HStack {
                    Text("当前状态")
                        .foregroundStyle(.secondary)
                    Spacer()
                    StatusBadge(status: fermentation.status)
                }
            }
            
            Section("选择新状态") {
                VStack(spacing: 12) {
                    StatusOption(
                        title: "进行中",
                        description: "重新激活发酵罐，可以继续添加记录和操作",
                        status: "active",
                        isSelected: selectedStatus == "active"
                    ) {
                        selectedStatus = "active"
                    }
                    
                    StatusOption(
                        title: "已完成",
                        description: "标记发酵完成，进入历史批次",
                        status: "completed",
                        isSelected: selectedStatus == "completed"
                    ) {
                        selectedStatus = "completed"
                    }
                    
                    StatusOption(
                        title: "已废弃",
                        description: "标记为异常丢弃，记录失败原因",
                        status: "discarded",
                        isSelected: selectedStatus == "discarded"
                    ) {
                        selectedStatus = "discarded"
                    }
                }
            }
            
            if selectedStatus != fermentation.status {
                Section("状态变更说明") {
                    TextField("说明状态变更的原因（可选）", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("状态变更说明")
                        .font(.headline)
                    Text("• 可以随时调整发酵罐的状态")
                    Text("• 从历史状态恢复到进行中是完全支持的")
                    Text("• 状态变更会记录在时间线中")
                    Text("• 进行中状态可以继续分装和记录")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("编辑状态")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
                    .disabled(selectedStatus == fermentation.status)
            }
        }
    }
    
    private func save() {
        let oldStatus = fermentation.status
        fermentation.status = selectedStatus
        fermentation.updatedAt = Date()
        
        // 创建状态变更记录
        let statusLabels = [
            "active": "进行中",
            "completed": "已完成", 
            "discarded": "已废弃"
        ]
        
        let oldLabel = statusLabels[oldStatus] ?? oldStatus
        let newLabel = statusLabels[selectedStatus] ?? selectedStatus
        let noteText = note.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let content = noteText.isEmpty ? 
            "状态变更：\(oldLabel) → \(newLabel)" : 
            "状态变更：\(oldLabel) → \(newLabel) (\(noteText))"
        
        let record = Record(
            fermentation: fermentation,
            content: content,
            status: "normal"
        )
        modelContext.insert(record)
        
        dismiss()
    }
}

struct StatusOption: View {
    let title: String
    let description: String
    let status: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(isSelected ? statusColor : Color.clear)
                    .stroke(statusColor, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(isSelected ? Color.white : Color.clear)
                            .frame(width: 8, height: 8)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: status)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? statusColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        switch status {
        case "active": return .green
        case "completed": return .blue
        case "discarded": return .gray
        default: return .orange
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    private var isRecordsTab: Bool {
        title == "记录"
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: isRecordsTab ? 18 : 16, weight: isRecordsTab ? .semibold : .medium))
                Text(title)
                    .font(isRecordsTab ? .subheadline : .caption)
                    .fontWeight(isRecordsTab ? .semibold : .medium)
            }
            .foregroundColor(isSelected ? (isRecordsTab ? .green : .blue) : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(isSelected ? (isRecordsTab ? Color.green.opacity(0.15) : Color.blue.opacity(0.1)) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ChildrenView: View {
    @Environment(\.modelContext) private var modelContext
    let fermentation: Fermentation
    
    // 使用 @Query 主动查询子项，确保数据实时更新
    @Query private var allFermentations: [Fermentation]
    
    private var children: [Fermentation] {
        allFermentations.filter { $0.parent?.persistentModelID == fermentation.persistentModelID }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        List {
                if children.isEmpty {
                    EmptyState(
                        icon: "square.stack.3d.up",
                        title: "暂无子项",
                        message: "点击底部分装按钮创建子项",
                        actionTitle: nil,
                        action: nil
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    Section {
                        ForEach(children) { child in
                            NavigationLink(destination: FermentationDetailView(fermentation: child)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(child.name)
                                            .font(.headline)
                                        Spacer()
                                        StatusBadge(status: child.status)
                                    }
                                    
                                    HStack {
                                        if let label = child.label {
                                            Text(label)
                                                .font(.caption)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.15))
                                                .foregroundStyle(.blue)
                                                .clipShape(Capsule())
                                        }
                                        Spacer()
                                        Text(child.createdAt, style: .date)
                                            .environment(\.locale, Locale(identifier: "zh_CN"))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    // 显示记录数量
                                    let recordCount = child.records.count
                                    if recordCount > 0 {
                                        Text("\(recordCount) 条记录")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Text("子项 (\(children.count))")
                    }
                }
        }
    }
}

struct RecordsView: View {
    @Environment(\.modelContext) private var modelContext
    let fermentation: Fermentation
    
    // 使用 @Query 主动查询记录，确保数据实时更新
    @Query private var allRecords: [Record]
    
    private var items: [Record] {
        allRecords.filter { $0.fermentation?.persistentModelID == fermentation.persistentModelID }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        List {
                if items.isEmpty {
                    EmptyState(
                        icon: "list.bullet.clipboard",
                        title: "暂无记录",
                        message: "点击底部的记录按钮开始记录发酵过程",
                        actionTitle: nil,
                        action: nil
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    Section {
                        ForEach(items) { record in
                            NavigationLink(destination: EditRecordView(record: record)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(record.createdAt, style: .date)
                                            .environment(\.locale, Locale(identifier: "zh_CN"))
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Text(record.createdAt, style: .time)
                                            .environment(\.locale, Locale(identifier: "zh_CN"))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        if let parentFermentation = record.parentFermentation {
                                            Text("来源于 \(parentFermentation.name) 的分装")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.blue)
                                        }
                                        Text(record.content)
                                            .font(.body)
                                    }
                                    .padding(.vertical, 2)
                                    
                                    if record.isFeeding, let feedingContent = record.feedingContent, !feedingContent.isEmpty {
                                        HStack {
                                            Image(systemName: "leaf.fill")
                                                .font(.caption)
                                                .foregroundStyle(.green)
                                            Text("投料：\(feedingContent)")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.green)
                                        }
                                        .padding(.top, 4)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(6)
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 4)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.green)
                            Text("记录时间线")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(items.count) 条记录")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .font(.headline)
                        .foregroundStyle(.primary)
                    }
                }
        }
    }
    
}

struct EditRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let record: Record

    @State private var createdAt: Date
    @State private var content: String
    @State private var feedingContent: String

    // 新增状态
    @State private var showingEnvironmentInput = false
    @State private var showingFeedingInput = false

    init(record: Record) {
        self.record = record
        self._createdAt = State(initialValue: record.createdAt)
        self._content = State(initialValue: record.content)
        self._feedingContent = State(initialValue: record.feedingContent ?? "")
    }

    var body: some View {
        Form {
            Section("时间") {
                DatePicker("记录时间", selection: $createdAt)
                    .environment(\.locale, Locale(identifier: "zh_CN"))
            }
            Section("记录内容") {
                TextField("记录内容（最多300字）", text: $content, axis: .vertical)
                    .lineLimit(3...6)
            }
            Section("投料（可选）") {
                TextField("投料内容（例如：面粉100g、水90ml）", text: $feedingContent, axis: .vertical)
                    .lineLimit(2...6)
            }

            // P1功能入口
            Section {
                Button(action: { showingEnvironmentInput = true }) {
                    Label("记录环境数据", systemImage: "thermometer.medium")
                }

                Button(action: { showingFeedingInput = true }) {
                    Label("结构化投料", systemImage: "leaf.fill")
                }
            } header: {
                Text("高级功能")
            }
        }
        .navigationTitle("编辑记录")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("保存", action: save) }
        }
        .sheet(isPresented: $showingEnvironmentInput) {
            EnvironmentInputView(record: record, fermentationType: inferFermentationType())
        }
        .sheet(isPresented: $showingFeedingInput) {
            FeedingInputView(record: record, fermentationType: inferFermentationType())
        }
    }

    private func save() {
        record.createdAt = createdAt
        record.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        record.isFeeding = !feedingContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        record.feedingContent = feedingContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : feedingContent.trimmingCharacters(in: .whitespacesAndNewlines)
        dismiss()
    }

    private func inferFermentationType() -> String {
        guard let fermentation = record.fermentation else { return "其他" }
        let name = fermentation.name.lowercased()
        if name.contains("鲁邦") || name.contains("酸面团") || name.contains("面包") {
            return "酸面团"
        } else if name.contains("康普茶") || name.contains("kombucha") {
            return "康普茶"
        } else if name.contains("泡菜") || name.contains("酸菜") {
            return "泡菜"
        } else if name.contains("酸奶") || name.contains("yogurt") {
            return "酸奶"
        }
        return "其他"
    }
}

struct AddRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let fermentation: Fermentation

    @State private var createdAt: Date = Date()
    @State private var content: String = ""
    @State private var feedingContent: String = ""

    // 新增状态：显示环境和投料录入
    @State private var showingEnvironmentInput = false
    @State private var showingFeedingInput = false
    @State private var savedRecord: Record?

    var body: some View {
        Form {
            Section("时间") {
                DatePicker("记录时间", selection: $createdAt)
                    .environment(\.locale, Locale(identifier: "zh_CN"))
            }
            Section("记录内容") {
                TextField("记录内容（最多300字）", text: $content, axis: .vertical)
                    .lineLimit(3...6)
            }
            Section("投料（可选）") {
                TextField("投料内容（例如：面粉100g、水90ml）", text: $feedingContent, axis: .vertical)
                    .lineLimit(2...6)
            }

            // P1功能入口
            Section {
                Button(action: { showRecordFirst(then: { showingEnvironmentInput = true }) }) {
                    Label("记录环境数据", systemImage: "thermometer.medium")
                }

                Button(action: { showRecordFirst(then: { showingFeedingInput = true }) }) {
                    Label("结构化投料", systemImage: "leaf.fill")
                }
            } header: {
                Text("高级功能")
            } footer: {
                Text("先保存记录后可以添加环境数据和结构化投料")
                    .font(.caption2)
            }
        }
        .navigationTitle("添加记录")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("保存", action: save) }
        }
        .sheet(isPresented: $showingEnvironmentInput) {
            if let record = savedRecord {
                EnvironmentInputView(record: record, fermentationType: inferFermentationType())
            }
        }
        .sheet(isPresented: $showingFeedingInput) {
            if let record = savedRecord {
                FeedingInputView(record: record, fermentationType: inferFermentationType())
            }
        }
    }

    private func save() {
        let record = Record(fermentation: fermentation,
                            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                            status: "normal",
                            images: [],
                            isFeeding: !feedingContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                            feedingContent: feedingContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : feedingContent.trimmingCharacters(in: .whitespacesAndNewlines),
                            createdAt: createdAt)
        modelContext.insert(record)
        savedRecord = record
        dismiss()
    }

    private func showRecordFirst(then action: @escaping () -> Void) {
        // 如果还没保存，先保存
        if savedRecord == nil {
            save()
        }
        // 延迟执行以确保dismiss完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            action()
        }
    }

    private func inferFermentationType() -> String {
        let name = fermentation.name.lowercased()
        if name.contains("鲁邦") || name.contains("酸面团") || name.contains("面包") {
            return "酸面团"
        } else if name.contains("康普茶") || name.contains("kombucha") {
            return "康普茶"
        } else if name.contains("泡菜") || name.contains("酸菜") {
            return "泡菜"
        } else if name.contains("酸奶") || name.contains("yogurt") {
            return "酸奶"
        }
        return "其他"
    }
}

struct AddFermentationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var note: String = ""
    @State private var feedingContent: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, note, feeding
    }

    var body: some View {
        Form {
            Section {
                TextField("发酵罐名称", text: $name)
                    .focused($focusedField, equals: .name)
            } header: {
                Text("名称（必填）")
            } footer: {
                Text("例如：苹果鲁邦 第6代、红茶康普茶 第3代")
                    .font(.caption)
            }
            
            Section {
                TextField("记录初始状态或特殊说明", text: $note, axis: .vertical)
                    .lineLimit(2...5)
                    .focused($focusedField, equals: .note)
            } header: {
                Text("备注（可选）")
            } footer: {
                Text("例如：使用有机葡萄、温度25℃、首次尝试等")
                    .font(.caption)
            }
            
            Section {
                TextField("记录初始投料内容", text: $feedingContent, axis: .vertical)
                    .lineLimit(2...5)
                    .focused($focusedField, equals: .feeding)
            } header: {
                Text("投料（可选）")
            } footer: {
                Text("例如：面粉100g + 水90ml、红茶1L + 白糖70g")
                    .font(.caption)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("发酵罐将自动设置为「进行中」状态")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(.blue)
                        Text("备注和投料会作为初始记录保存")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(.orange)
                        Text("创建后可继续添加记录和操作")
                            .font(.subheadline)
                    }
                }
                .foregroundStyle(.secondary)
            } header: {
                Text("提示")
            }
        }
        .navigationTitle("新建发酵罐")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { 
                Button("取消") { dismiss() } 
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("创建") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
            }
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("完成") {
                        focusedField = nil
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            // 自动聚焦到名称输入框
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .name
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFeeding = feedingContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 创建发酵罐（默认状态为active）
        let fermentation = Fermentation(name: trimmedName, status: "active")
        modelContext.insert(fermentation)
        
        // 如果有备注，创建备注记录
        if !trimmedNote.isEmpty {
            let noteRecord = Record(
                fermentation: fermentation,
                content: trimmedNote,
                status: "normal"
            )
            modelContext.insert(noteRecord)
            fermentation.records.append(noteRecord)
        }
        
        // 如果有投料，创建投料记录
        if !trimmedFeeding.isEmpty {
            let feedingRecord = Record(
                fermentation: fermentation,
                content: "初始投料",
                status: "normal",
                isFeeding: true,
                feedingContent: trimmedFeeding
            )
            modelContext.insert(feedingRecord)
            fermentation.records.append(feedingRecord)
        }
        
        // 保存上下文
        try? modelContext.save()
        
        dismiss()
    }
}

struct RemindersView: View {
    @Environment(\.modelContext) private var modelContext
    let fermentation: Fermentation
    @State private var isPresentingAdd: Bool = false

    var body: some View {
        List {
            ForEach(fermentation.reminders.sorted { $0.remindTime < $1.remindTime }) { r in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading) {
                        Text(r.content)
                        Text(r.remindTime, style: .date)
                            .environment(\.locale, Locale(identifier: "zh_CN"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(get: { r.isActive }, set: { r.isActive = $0 }))
                        .labelsHidden()
                }
            }
            .onDelete { indexSet in
                let items = fermentation.reminders.sorted { $0.remindTime < $1.remindTime }
                for idx in indexSet { modelContext.delete(items[idx]) }
            }
        }
        .navigationTitle("提醒")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isPresentingAdd = true } label: { Label("新增", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            NavigationStack { AddReminderView(fermentation: fermentation) }
        }
    }
}

struct DistributeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let fermentation: Fermentation

    @State private var childNames: [String] = ["", ""]
    @State private var destinations: [String] = ["二发", "二发"]
    @State private var feedingContents: [String] = ["", ""]
    
    // 优化后的选项：更清晰的用途分类
    private let destinationOptions = ["留种", "二发", "使用"]

    var body: some View {
        Form {
            Section("分装信息") {
                ForEach(0..<childNames.count, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("分装名称（如：瓶A 草莓）", text: $childNames[index])
                            
                            if childNames.count > 1 {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        childNames.remove(at: index)
                                        destinations.remove(at: index)
                                        feedingContents.remove(at: index)
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        Picker("去向", selection: $destinations[index]) {
                            ForEach(destinationOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        TextField("投料内容（可选，如：面粉100g、水90ml）", text: $feedingContents[index], axis: .vertical)
                            .lineLimit(2...6)
                    }
                    .padding(.vertical, 4)
                }
                
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            childNames.append("")
                            destinations.append("二发")
                            feedingContents.append("")
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("添加分装")
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .disabled(childNames.count >= 5)
                    .opacity(childNames.count >= 5 ? 0.5 : 1.0)
                    
                    Spacer()
                    
                    Text("最多可添加 \(childNames.count)/5 个分装")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(.green)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("留种")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("继续发酵，作为下一代种子")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "bubbles.and.sparkles")
                            .foregroundStyle(.blue)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("二发")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("二次发酵，添加风味（如康普茶、面包）")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.orange)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("使用")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("立即使用，不再发酵（自动标记为已完成）")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("分装类型说明")
            }
            
            Section("预览") {
                ForEach(0..<childNames.count, id: \.self) { index in
                    if !childNames[index].isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(childNames[index])
                                    .font(.headline)
                                Spacer()
                                // 显示预期状态
                                if destinations[index] == "使用" {
                                    StatusBadge(status: "completed")
                                } else {
                                    StatusBadge(status: "active")
                                }
                            }
                            Text("类型：\(destinations[index])")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !feedingContents[index].isEmpty {
                                Text("投料：\(feedingContents[index])")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("分装")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("确认分装", action: save)
                    .disabled(childNames.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            }
        }
    }

    private func save() {
        var createdChildren: [Fermentation] = []
        
        for (index, name) in childNames.enumerated() {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedName.isEmpty {
                let destination = destinations[index]
                
                // 根据去向设置状态
                // "留种"和"二发"：继续发酵，状态为"进行中"
                // "使用"：立即使用，状态为"已完成"
                let status = (destination == "使用") ? "completed" : "active"
                
                let child = Fermentation(
                    name: trimmedName,
                    status: status,
                    label: destination,
                    parent: fermentation
                )
                modelContext.insert(child)
                createdChildren.append(child)
                
                // 创建初始记录
                let content: String
                if destination == "使用" {
                    content = "分装使用（已完成）"
                } else {
                    content = "分装创建"
                }
                
                let feedingContent = feedingContents[index].trimmingCharacters(in: .whitespacesAndNewlines)
                let record = Record(
                    fermentation: child,
                    content: content,
                    status: "normal",
                    isFeeding: !feedingContent.isEmpty,
                    feedingContent: feedingContent.isEmpty ? nil : feedingContent,
                    parentFermentation: fermentation
                )
                modelContext.insert(record)
            }
        }
        
        // 为父批次添加分装记录
        let summary = "分装创建 \(createdChildren.count) 个子批次"
        let record = Record(fermentation: fermentation, content: summary, status: "normal")
        modelContext.insert(record)
        
        dismiss()
    }
}

struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let fermentation: Fermentation

    @State private var remindTime: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var content: String = "检查发酵状态"
    @State private var repeatType: String = "once"

    var body: some View {
        Form {
            Section("时间") {
                DatePicker("提醒时间", selection: $remindTime)
                    .environment(\.locale, Locale(identifier: "zh_CN"))
            }
            Section("内容") {
                TextField("提醒内容", text: $content)
            }
            Section("重复") {
                Picker("重复", selection: $repeatType) {
                    Text("仅一次").tag("once")
                    Text("每天").tag("daily")
                    Text("每2天").tag("every2days")
                    Text("每周").tag("weekly")
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("新增提醒")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("保存", action: save) }
        }
    }

    private func save() {
        let r = Reminder(fermentation: fermentation,
                         remindTime: remindTime,
                         content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                         repeatType: repeatType,
                         isActive: true)
        modelContext.insert(r)
        dismiss()
    }
}

// MARK: - 推荐徽章组件（已优化为使用统一设计系统）

struct RecommendationBadge: View {
    let count: Int
    let hasHighPriority: Bool

    var body: some View {
        EnhancedBadge(
            text: "\(count)",
            icon: hasHighPriority ? "exclamationmark.triangle.fill" : "lightbulb.fill",
            color: hasHighPriority ? .danger : .info,
            size: .small
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fermentation.self, Record.self, Reminder.self, configurations: config)
    let context = container.mainContext

    // 创建主要发酵项目
    let appleSourdough = Fermentation(name: "苹果鲁邦 第6代", status: "active", createdAt: Date().addingTimeInterval(-86400 * 5))
    let grapeSourdough = Fermentation(name: "葡萄鲁邦 第4代", status: "active", createdAt: Date().addingTimeInterval(-86400 * 3))
    let blackTeaKombucha = Fermentation(name: "红茶康普茶 第5代", status: "active", createdAt: Date().addingTimeInterval(-86400 * 8))
    let strawberryKombucha = Fermentation(name: "草莓康普茶 第3代", status: "completed", createdAt: Date().addingTimeInterval(-86400 * 15))
    let kimchi = Fermentation(name: "韩式泡菜", status: "active", createdAt: Date().addingTimeInterval(-86400 * 2))
    let yogurt = Fermentation(name: "希腊酸奶", status: "discarded", createdAt: Date().addingTimeInterval(-86400 * 7))
    
    context.insert(appleSourdough)
    context.insert(grapeSourdough)
    context.insert(blackTeaKombucha)
    context.insert(strawberryKombucha)
    context.insert(kimchi)
    context.insert(yogurt)

    // 创建分装关系 - 康普茶二发瓶
    let kombuchaBottleA = Fermentation(name: "瓶A 青柠薄荷", status: "active", createdAt: Date().addingTimeInterval(-86400 * 2), updatedAt: Date().addingTimeInterval(-86400), label: "二发", parent: blackTeaKombucha)
    let kombuchaBottleB = Fermentation(name: "瓶B 梨片生姜", status: "completed", createdAt: Date().addingTimeInterval(-86400 * 2), updatedAt: Date().addingTimeInterval(-86400), label: "使用", parent: blackTeaKombucha)
    let kombuchaBottleC = Fermentation(name: "瓶C 原味测试", status: "discarded", createdAt: Date().addingTimeInterval(-86400 * 2), updatedAt: Date().addingTimeInterval(-86400), label: "其他", parent: blackTeaKombucha)
    
    context.insert(kombuchaBottleA)
    context.insert(kombuchaBottleB)
    context.insert(kombuchaBottleC)

    // 创建分装关系 - 鲁邦种使用
    let sourdoughBread = Fermentation(name: "全麦酸面包", status: "completed", createdAt: Date().addingTimeInterval(-86400 * 1), updatedAt: Date().addingTimeInterval(-86400), label: "使用", parent: appleSourdough)
    context.insert(sourdoughBread)

    // 苹果鲁邦记录
    let r1 = Record(fermentation: appleSourdough, content: "体积翻倍，气泡细腻均匀，酸香怡人", status: "normal", createdAt: Date().addingTimeInterval(-3600))
    let r2 = Record(fermentation: appleSourdough, content: "投料：留种100g + 高筋粉100g + 水100g", status: "normal", isFeeding: true, feedingContent: "留种100g + 高筋粉100g + 水100g", createdAt: Date().addingTimeInterval(-7200))
    let r3 = Record(fermentation: appleSourdough, content: "状态稳定，可以考虑减小喂养比例", status: "normal", createdAt: Date().addingTimeInterval(-86400 * 1))
    let r4 = Record(fermentation: appleSourdough, content: "投料：留种80g + 高筋粉100g + 水90g", status: "normal", isFeeding: true, feedingContent: "留种80g + 高筋粉100g + 水90g", createdAt: Date().addingTimeInterval(-86400 * 2))
    
    context.insert(r1)
    context.insert(r2)
    context.insert(r3)
    context.insert(r4)
    appleSourdough.records.append(r1)
    appleSourdough.records.append(r2)
    appleSourdough.records.append(r3)
    appleSourdough.records.append(r4)

    // 葡萄鲁邦记录
    let r5 = Record(fermentation: grapeSourdough, content: "体积只涨1.2倍，气味偏酸，伴随酒精感", status: "watch", createdAt: Date().addingTimeInterval(-1800))
    let r6 = Record(fermentation: grapeSourdough, content: "投料：留种50g + 全麦粉100g + 水100g", status: "normal", isFeeding: true, feedingContent: "留种50g + 全麦粉100g + 水100g", createdAt: Date().addingTimeInterval(-3600))
    let r7 = Record(fermentation: grapeSourdough, content: "状态依旧弱，怀疑污染或营养不足", status: "watch", createdAt: Date().addingTimeInterval(-86400 * 1))
    
    context.insert(r5)
    context.insert(r6)
    context.insert(r7)
    grapeSourdough.records.append(r5)
    grapeSourdough.records.append(r6)
    grapeSourdough.records.append(r7)

    // 红茶康普茶记录
    let r8 = Record(fermentation: blackTeaKombucha, content: "pH≈3.0，酸度偏强，甜度几乎消失", status: "normal", createdAt: Date().addingTimeInterval(-7200))
    let r9 = Record(fermentation: blackTeaKombucha, content: "膜厚，表面均匀，味道略带苹果酸感", status: "normal", createdAt: Date().addingTimeInterval(-86400 * 2))
    let r10 = Record(fermentation: blackTeaKombucha, content: "分装创建 3 个子批次", status: "normal", createdAt: Date().addingTimeInterval(-86400 * 3))
    let r10_1 = Record(fermentation: blackTeaKombucha, content: "投料：红茶1L + 白糖70g", status: "normal", isFeeding: true, feedingContent: "红茶1L + 白糖70g", createdAt: Date().addingTimeInterval(-86400 * 5))
    
    context.insert(r8)
    context.insert(r9)
    context.insert(r10)
    context.insert(r10_1)
    blackTeaKombucha.records.append(r8)
    blackTeaKombucha.records.append(r9)
    blackTeaKombucha.records.append(r10)
    blackTeaKombucha.records.append(r10_1)

    // 草莓康普茶记录（已完成）
    let r11 = Record(fermentation: strawberryKombucha, content: "发酵完成：酸甜平衡，气泡丰富", status: "normal", createdAt: Date().addingTimeInterval(-86400 * 5))
    let r12 = Record(fermentation: strawberryKombucha, content: "投料：草莓片50g + 罗勒叶5g", status: "normal", isFeeding: true, feedingContent: "草莓片50g + 罗勒叶5g", createdAt: Date().addingTimeInterval(-86400 * 8))
    
    context.insert(r11)
    context.insert(r12)
    strawberryKombucha.records.append(r11)
    strawberryKombucha.records.append(r12)

    // 泡菜记录
    let r13 = Record(fermentation: kimchi, content: "开始出水，颜色逐渐变红", status: "normal", createdAt: Date().addingTimeInterval(-3600))
    let r14 = Record(fermentation: kimchi, content: "投料：白菜1kg + 盐50g + 辣椒粉30g + 大蒜20g", status: "normal", isFeeding: true, feedingContent: "白菜1kg + 盐50g + 辣椒粉30g + 大蒜20g", createdAt: Date().addingTimeInterval(-86400 * 1))
    
    context.insert(r13)
    context.insert(r14)
    kimchi.records.append(r13)
    kimchi.records.append(r14)

    // 酸奶记录（已废弃）
    let r15 = Record(fermentation: yogurt, content: "异常丢弃：出现异味和异常纹理", status: "abnormal", createdAt: Date().addingTimeInterval(-86400 * 2))
    let r16 = Record(fermentation: yogurt, content: "投料：牛奶1L + 酸奶菌粉1包", status: "normal", isFeeding: true, feedingContent: "牛奶1L + 酸奶菌粉1包", createdAt: Date().addingTimeInterval(-86400 * 5))
    
    context.insert(r15)
    context.insert(r16)
    yogurt.records.append(r15)
    yogurt.records.append(r16)

    // 分装瓶记录
    let r17 = Record(fermentation: kombuchaBottleA, content: "分装创建", status: "normal", createdAt: Date().addingTimeInterval(-86400 * 2), parentFermentation: blackTeaKombucha)
    let r18 = Record(fermentation: kombuchaBottleA, content: "投料：青柠片3片 + 薄荷叶10片", status: "normal", isFeeding: true, feedingContent: "青柠片3片 + 薄荷叶10片", createdAt: Date().addingTimeInterval(-86400 * 2))
    let r19 = Record(fermentation: kombuchaBottleA, content: "气泡温和，酸甜平衡，口感顺滑", status: "normal", createdAt: Date().addingTimeInterval(-86400 * 1))
    
    context.insert(r17)
    context.insert(r18)
    context.insert(r19)
    kombuchaBottleA.records.append(r17)
    kombuchaBottleA.records.append(r18)
    kombuchaBottleA.records.append(r19)

    let r20 = Record(fermentation: kombuchaBottleB, content: "分装创建", status: "normal", createdAt: Date().addingTimeInterval(-86400 * 2), parentFermentation: blackTeaKombucha)
    let r21 = Record(fermentation: kombuchaBottleB, content: "投料：梨片4片 + 生姜丝10g", status: "normal", isFeeding: true, feedingContent: "梨片4片 + 生姜丝10g", createdAt: Date().addingTimeInterval(-86400 * 2))
    let r22 = Record(fermentation: kombuchaBottleB, content: "发酵完成：风味浓郁，成功批次", status: "normal", createdAt: Date().addingTimeInterval(-86400 * 1))
    
    context.insert(r20)
    context.insert(r21)
    context.insert(r22)
    kombuchaBottleB.records.append(r20)
    kombuchaBottleB.records.append(r21)
    kombuchaBottleB.records.append(r22)

    let r23 = Record(fermentation: kombuchaBottleC, content: "分装创建", status: "normal", createdAt: Date().addingTimeInterval(-86400 * 2), parentFermentation: blackTeaKombucha)
    let r24 = Record(fermentation: kombuchaBottleC, content: "几乎无气泡，风味偏淡，酸感为主", status: "abnormal", createdAt: Date().addingTimeInterval(-86400 * 1))
    
    context.insert(r23)
    context.insert(r24)
    kombuchaBottleC.records.append(r23)
    kombuchaBottleC.records.append(r24)

    let r25 = Record(fermentation: sourdoughBread, content: "分装创建", status: "normal", createdAt: Date().addingTimeInterval(-86400 * 1), parentFermentation: appleSourdough)
    let r26 = Record(fermentation: sourdoughBread, content: "发酵完成：外脆内软，酸味适中", status: "normal", createdAt: Date().addingTimeInterval(-86400 * 1))
    let r27 = Record(fermentation: sourdoughBread, content: "状态变更：进行中 → 已完成", status: "normal", createdAt: Date().addingTimeInterval(-86400 * 1))
    
    context.insert(r25)
    context.insert(r26)
    context.insert(r27)
    sourdoughBread.records.append(r25)
    sourdoughBread.records.append(r26)
    sourdoughBread.records.append(r27)

    // 提醒记录
    let m1 = Reminder(fermentation: appleSourdough, remindTime: Calendar.current.date(byAdding: .hour, value: 6, to: Date())!, content: "检查发酵状态", repeatType: "once")
    let m2 = Reminder(fermentation: grapeSourdough, remindTime: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, content: "尝试刷新喂养", repeatType: "once")
    let m3 = Reminder(fermentation: blackTeaKombucha, remindTime: Calendar.current.date(byAdding: .day, value: 2, to: Date())!, content: "准备下一批分装", repeatType: "weekly")
    let m4 = Reminder(fermentation: kimchi, remindTime: Calendar.current.date(byAdding: .day, value: 3, to: Date())!, content: "检查泡菜成熟度", repeatType: "once")
    let m5 = Reminder(fermentation: appleSourdough, remindTime: Calendar.current.date(byAdding: .hour, value: 12, to: Date())!, content: "定期喂养检查", repeatType: "daily")
    
    context.insert(m1)
    context.insert(m2)
    context.insert(m3)
    context.insert(m4)
    context.insert(m5)

    return ContentView(selectedTab: nil)
        .modelContainer(container)
}

