//
//  GenealogyView.swift
//  FermentPal
//
//  家谱视图 - 展示发酵罐的传承关系
//

import SwiftUI
import SwiftData

// MARK: - 家谱节点数据模型
struct GenealogyNode: Identifiable {
    let id: UUID
    let fermentation: Fermentation
    var children: [GenealogyNode]
    var level: Int
    
    var isRoot: Bool {
        fermentation.parent == nil
    }
    
    var isLeaf: Bool {
        children.isEmpty
    }
    
    var descendantCount: Int {
        children.count + children.reduce(0) { $0 + $1.descendantCount }
    }
}

// MARK: - 家谱树管理器
class GenealogyTree {
    var roots: [GenealogyNode] = []
    
    /// 从发酵罐列表构建树结构
    func buildTree(from fermentations: [Fermentation]) {
        // 找出所有根节点（没有父节点的）
        let rootFermentations = fermentations.filter { $0.parent == nil }
        
        // 为每个根节点构建子树
        roots = rootFermentations.map { buildNode(for: $0, level: 0, allFermentations: fermentations) }
            .sorted { $0.fermentation.createdAt > $1.fermentation.createdAt }
    }
    
    /// 递归构建节点及其子节点
    private func buildNode(for fermentation: Fermentation, level: Int, allFermentations: [Fermentation]) -> GenealogyNode {
        // 找到所有子节点
        let childFermentations = fermentation.children.sorted { $0.createdAt > $1.createdAt }
        
        // 递归构建子节点
        let childNodes = childFermentations.map { child in
            buildNode(for: child, level: level + 1, allFermentations: allFermentations)
        }
        
        return GenealogyNode(
            id: UUID(),
            fermentation: fermentation,
            children: childNodes,
            level: level
        )
    }
    
    /// 查找从根节点到目标节点的路径
    func findPath(to targetId: PersistentIdentifier, in nodes: [GenealogyNode]) -> [GenealogyNode]? {
        for node in nodes {
            if node.fermentation.persistentModelID == targetId {
                return [node]
            }
            
            if let path = findPath(to: targetId, in: node.children) {
                return [node] + path
            }
        }
        return nil
    }
}

// MARK: - 主视图
struct GenealogyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Fermentation.createdAt, order: .reverse) private var allFermentations: [Fermentation]
    
    @State private var selectedFilter: FilterType = .all
    
    enum FilterType: String, CaseIterable {
        case all = "全部"
        case active = "进行中"
        case completed = "已完成"
    }
    
    // 实时构建树结构，而不是缓存
    private var tree: GenealogyTree {
        let tree = GenealogyTree()
        tree.buildTree(from: allFermentations)
        return tree
    }
    
    private var filteredRoots: [GenealogyNode] {
        switch selectedFilter {
        case .all:
            return tree.roots
        case .active:
            return tree.roots.compactMap { filterNode($0, status: "active") }
        case .completed:
            return tree.roots.compactMap { filterNode($0, status: "completed") }
        }
    }
    
    /// 递归过滤节点，只保留匹配指定状态的节点及其祖先
    private func filterNode(_ node: GenealogyNode, status: String) -> GenealogyNode? {
        // 递归过滤子节点
        let filteredChildren = node.children.compactMap { filterNode($0, status: status) }
        
        // 如果当前节点匹配状态，或者有匹配的子节点，则保留
        if node.fermentation.status == status || !filteredChildren.isEmpty {
            return GenealogyNode(
                id: node.id,
                fermentation: node.fermentation,
                children: filteredChildren,
                level: node.level
            )
        }
        
        return nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 统计卡片
                    if !tree.roots.isEmpty {
                        StatisticsCard(tree: tree)
                            .padding(.horizontal)
                            .padding(.top)
                    }
                    
                    // 家谱树
                    if filteredRoots.isEmpty {
                        EmptyGenealogyView()
                            .padding(.top, 60)
                    } else {
                        VStack(spacing: 24) {
                            ForEach(filteredRoots) { rootNode in
                                VStack(alignment: .leading, spacing: 0) {
                                    NodeTreeView(node: rootNode, isLast: rootNode.id == filteredRoots.last?.id)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("🌳 家谱")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("筛选", selection: $selectedFilter) {
                            ForEach(FilterType.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .id(allFermentations.count) // 强制在数据变化时刷新视图
        }
    }
}

// MARK: - 统计卡片
struct StatisticsCard: View {
    let tree: GenealogyTree
    
    private var stats: (families: Int, nodes: Int, active: Int, completed: Int, discarded: Int) {
        var totalNodes = 0
        var activeCount = 0
        var completedCount = 0
        var discardedCount = 0
        
        func countNodes(_ nodes: [GenealogyNode]) {
            for node in nodes {
                totalNodes += 1
                switch node.fermentation.status {
                case "active": activeCount += 1
                case "completed": completedCount += 1
                case "discarded": discardedCount += 1
                default: break
                }
                countNodes(node.children)
            }
        }
        
        countNodes(tree.roots)
        
        return (tree.roots.count, totalNodes, activeCount, completedCount, discardedCount)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatItem(icon: "tree", value: "\(stats.families)", label: "家族")
                StatItem(icon: "square.stack.3d.up", value: "\(stats.nodes)", label: "节点")
            }
            
            Divider()
            
            HStack(spacing: 16) {
                MiniStatItem(color: .green, value: stats.active, label: "进行中")
                MiniStatItem(color: .blue, value: stats.completed, label: "已完成")
                if stats.discarded > 0 {
                    MiniStatItem(color: .gray, value: stats.discarded, label: "已废弃")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MiniStatItem: View {
    let color: Color
    let value: Int
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(value)")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 节点树视图（递归显示）
struct NodeTreeView: View {
    let node: GenealogyNode
    let isLast: Bool
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 节点本身
            NodeRowView(node: node, isExpanded: $isExpanded)
            
            // 子节点（如果展开）
            if isExpanded && !node.children.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(node.children.enumerated()), id: \.element.id) { index, child in
                        HStack(alignment: .top, spacing: 0) {
                            // 连接线
                            VStack(spacing: 0) {
                                // 上半部分的竖线
                                Rectangle()
                                    .fill(lineColor(for: child.fermentation.status))
                                    .frame(width: 2, height: 20)
                                
                                // 中间节点
                                Circle()
                                    .fill(lineColor(for: child.fermentation.status))
                                    .frame(width: 6, height: 6)
                                
                                // 下半部分的竖线（如果不是最后一个）
                                if index < node.children.count - 1 {
                                    Rectangle()
                                        .fill(lineColor(for: child.fermentation.status))
                                        .frame(width: 2)
                                } else {
                                    Color.clear
                                        .frame(width: 2)
                                }
                            }
                            .frame(width: 30)
                            
                            // 横线 + 子节点
                            VStack(alignment: .leading, spacing: 0) {
                                // 横线连到节点
                                Rectangle()
                                    .fill(lineColor(for: child.fermentation.status))
                                    .frame(height: 2)
                                    .offset(y: 20)
                                    .frame(width: 16)
                                
                                // 递归显示子节点
                                NodeTreeView(node: child, isLast: index == node.children.count - 1)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func lineColor(for status: String) -> Color {
        switch status {
        case "active": return .green.opacity(0.6)
        case "completed": return .blue.opacity(0.4)
        case "discarded": return .gray.opacity(0.3)
        default: return .gray.opacity(0.4)
        }
    }
}

// MARK: - 节点行视图
struct NodeRowView: View {
    let node: GenealogyNode
    @Binding var isExpanded: Bool
    
    private var nodeIcon: String {
        switch node.fermentation.label {
        case "留种": return "leaf.fill"
        case "二发": return "bubbles.and.sparkles"
        case "使用": return "fork.knife"
        case "其他": return "ellipsis.circle"
        default: return "square.stack.3d.up"
        }
    }
    
    private var statusColor: Color {
        switch node.fermentation.status {
        case "active": return .green
        case "completed": return .blue
        case "discarded": return .gray
        default: return .orange
        }
    }
    
    var body: some View {
        NavigationLink(destination: FermentationDetailView(fermentation: node.fermentation)) {
            HStack(spacing: 12) {
                // 图标
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: nodeIcon)
                        .font(.system(size: 18))
                        .foregroundStyle(statusColor)
                }
                
                // 信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(node.fermentation.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if let label = node.fermentation.label {
                            Text(label)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)
                            Text(statusText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(node.fermentation.createdAt, style: .date)
                            .environment(\.locale, Locale(identifier: "zh_CN"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if !node.children.isEmpty {
                        Text("\(node.children.count) 个子项 · \(node.descendantCount) 个后代")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                // 展开/折叠按钮
                if !node.children.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusText: String {
        switch node.fermentation.status {
        case "active": return "进行中"
        case "completed": return "已完成"
        case "discarded": return "已废弃"
        default: return "未知"
        }
    }
}

// MARK: - 空状态视图
struct EmptyGenealogyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tree")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))
            
            Text("暂无家谱")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Text("创建发酵罐并进行分装后\n家谱关系会自动显示在这里")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - 预览
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fermentation.self, Record.self, Reminder.self, configurations: config)
    let context = container.mainContext
    
    // 创建示例数据
    let root1 = Fermentation(name: "苹果鲁邦 第4代", status: "completed", createdAt: Date().addingTimeInterval(-86400 * 10))
    context.insert(root1)
    
    let child1 = Fermentation(name: "苹果鲁邦 第5代", status: "completed", createdAt: Date().addingTimeInterval(-86400 * 7), label: "留种", parent: root1)
    context.insert(child1)
    
    let child2 = Fermentation(name: "全麦酸面包", status: "completed", createdAt: Date().addingTimeInterval(-86400 * 6), label: "使用", parent: root1)
    context.insert(child2)
    
    let grandchild1 = Fermentation(name: "苹果鲁邦 第6代", status: "active", createdAt: Date().addingTimeInterval(-86400 * 3), label: "留种", parent: child1)
    context.insert(grandchild1)
    
    let grandchild2 = Fermentation(name: "披萨面团", status: "completed", createdAt: Date().addingTimeInterval(-86400 * 2), label: "使用", parent: child1)
    context.insert(grandchild2)
    
    let root2 = Fermentation(name: "红茶康普茶 第3代", status: "completed", createdAt: Date().addingTimeInterval(-86400 * 8))
    context.insert(root2)
    
    let child3 = Fermentation(name: "红茶康普茶 第4代", status: "active", createdAt: Date().addingTimeInterval(-86400 * 5), label: "留种", parent: root2)
    context.insert(child3)
    
    let child4 = Fermentation(name: "瓶F 葡萄干姜", status: "discarded", createdAt: Date().addingTimeInterval(-86400 * 4), label: "二发", parent: root2)
    context.insert(child4)
    
    let child5 = Fermentation(name: "瓶G 青柠薄荷", status: "completed", createdAt: Date().addingTimeInterval(-86400 * 4), label: "二发", parent: root2)
    context.insert(child5)
    
    return GenealogyView()
        .modelContainer(container)
}

