//
//  FeedingInputView.swift
//  FermentPal
//
//  投料录入界面 - P1功能UI
//  结构化投料数据录入和分析
//

import SwiftUI
import SwiftData

// MARK: - 投料录入视图

struct FeedingInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let record: Record
    let fermentationType: String

    @State private var ingredients: [IngredientInput] = []
    @State private var notes: String = ""
    @State private var showingCommonIngredients: Bool = false
    @State private var showingTextParser: Bool = false
    @State private var analysis: FeedingAnalysis?
    @State private var feedingData: FeedingData?

    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

    private var service: FermentationService {
        FermentationService(modelContext: modelContext)
    }

    private var commonIngredients: [CommonIngredient] {
        CommonIngredient.getCommonIngredients(for: fermentationType)
    }

    private var totalWeight: Double? {
        let weights = ingredients.compactMap { ing -> Double? in
            guard let amount = Double(ing.amount),
                  ["g", "克", "kg", "千克"].contains(ing.unit) else {
                return nil
            }
            return ing.unit == "kg" || ing.unit == "千克" ? amount * 1000 : amount
        }
        return weights.isEmpty ? nil : weights.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            Form {
                // 快速操作
                quickActionsSection

                // 成分列表
                ingredientsSection

                // 添加成分按钮
                addIngredientSection

                // 汇总信息
                summarySection

                // 分析结果
                if let analysis = analysis {
                    analysisSection(analysis)
                }

                // 备注
                notesSection
            }
            .navigationTitle("结构化投料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveFeedingData()
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingCommonIngredients) {
                CommonIngredientsView(
                    fermentationType: fermentationType,
                    onSelect: { ingredient in
                        addIngredient(from: ingredient)
                    }
                )
            }
            .sheet(isPresented: $showingTextParser) {
                TextParserView(onParse: { text in
                    parseText(text)
                })
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - 视图组件

    private var quickActionsSection: some View {
        Section {
            Button(action: { showingCommonIngredients = true }) {
                Label("从常用成分选择", systemImage: "star.fill")
            }

            Button(action: { showingTextParser = true }) {
                Label("从文本解析", systemImage: "text.bubble")
            }
        } header: {
            Text("快速操作")
        }
    }

    private var ingredientsSection: some View {
        Section {
            if ingredients.isEmpty {
                Text("还未添加成分")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(ingredients.indices, id: \.self) { index in
                    IngredientRow(
                        ingredient: $ingredients[index],
                        onDelete: {
                            ingredients.remove(at: index)
                            updateAnalysis()
                        }
                    )
                }
                .onMove { from, to in
                    ingredients.move(fromOffsets: from, toOffset: to)
                }
            }
        } header: {
            HStack {
                Text("成分列表")
                if !ingredients.isEmpty {
                    Spacer()
                    Text("(\(ingredients.count)项)")
                        .foregroundStyle(.secondary)
                }
            }
        } footer: {
            if !ingredients.isEmpty {
                Text("长按拖动可调整顺序")
                    .font(.caption2)
            }
        }
    }

    private var addIngredientSection: some View {
        Section {
            Button(action: addEmptyIngredient) {
                Label("添加成分", systemImage: "plus.circle.fill")
            }
        }
    }

    private var summarySection: some View {
        Section {
            if !ingredients.isEmpty {
                // 显示配方
                HStack {
                    Text("配方")
                    Spacer()
                    Text(ingredientsSummary)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }

                // 显示比例
                if let ratio = calculateRatio() {
                    HStack {
                        Text("比例")
                        Spacer()
                        Text(ratio)
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)
                    }
                }

                // 显示总重量
                if let weight = totalWeight {
                    HStack {
                        Text("总重量")
                        Spacer()
                        Text(String(format: "%.0fg", weight))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("汇总")
        }
    }

    private func analysisSection(_ analysis: FeedingAnalysis) -> some View {
        Section {
            // 洞察
            if analysis.hasInsights {
                ForEach(analysis.insights, id: \.self) { insight in
                    Label(insight, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            // 警告
            if analysis.hasWarnings {
                ForEach(analysis.warnings, id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            // 推荐
            if analysis.hasRecommendations {
                ForEach(analysis.recommendations, id: \.self) { recommendation in
                    Label(recommendation, systemImage: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
        } header: {
            Text("分析结果")
        }
    }

    private var notesSection: some View {
        Section {
            TextField("投料备注", text: $notes, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            Text("备注（可选）")
        }
    }

    // MARK: - 辅助方法

    private var canSave: Bool {
        !ingredients.isEmpty && ingredients.allSatisfy { ing in
            !ing.name.isEmpty && !ing.amount.isEmpty && !ing.unit.isEmpty
        }
    }

    private var ingredientsSummary: String {
        ingredients.map { "\($0.name) \($0.amount)\($0.unit)" }.joined(separator: " + ")
    }

    private func calculateRatio() -> String? {
        guard ingredients.count >= 2 else { return nil }

        let amounts = ingredients.compactMap { Double($0.amount) }
        guard amounts.count == ingredients.count,
              let minAmount = amounts.min(),
              minAmount > 0 else {
            return nil
        }

        let normalized = amounts.map { Int(($0 / minAmount).rounded()) }
        return normalized.map { String($0) }.joined(separator: ":")
    }

    private func addEmptyIngredient() {
        ingredients.append(IngredientInput(
            name: "",
            amount: "",
            unit: "g"
        ))
    }

    private func addIngredient(from common: CommonIngredient) {
        let amount = common.commonAmounts.first ?? 100
        ingredients.append(IngredientInput(
            name: common.name,
            amount: String(Int(amount)),
            unit: common.defaultUnit.rawValue
        ))
        updateAnalysis()
    }

    private func parseText(_ text: String) {
        let parsed = FeedingAnalyzer.parseFromText(text)
        ingredients = parsed.map { ing in
            IngredientInput(
                name: ing.name,
                amount: String(Int(ing.amount)),
                unit: ing.unit
            )
        }
        updateAnalysis()
    }

    private func updateAnalysis() {
        guard !ingredients.isEmpty else {
            analysis = nil
            return
        }

        // 创建临时FeedingData进行分析
        let feedingIngredients = ingredients.compactMap { input -> FeedingIngredient? in
            guard let amount = Double(input.amount) else { return nil }
            return FeedingIngredient(
                name: input.name,
                amount: amount,
                unit: input.unit
            )
        }

        let tempFeeding = FeedingData(ingredients: feedingIngredients)
        tempFeeding.recalculate()

        analysis = service.analyzeFeeding(tempFeeding, fermentationType: fermentationType)
    }

    private func saveFeedingData() {
        let feedingIngredients = ingredients.compactMap { input -> FeedingIngredient? in
            guard let amount = Double(input.amount) else { return nil }
            return FeedingIngredient(
                name: input.name,
                amount: amount,
                unit: input.unit
            )
        }

        guard !feedingIngredients.isEmpty else {
            errorMessage = "请至少添加一个成分"
            showingError = true
            return
        }

        do {
            _ = try service.createFeedingData(
                for: record,
                ingredients: feedingIngredients,
                notes: notes.isEmpty ? nil : notes
            )

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - 成分输入数据模型

struct IngredientInput: Identifiable {
    let id = UUID()
    var name: String
    var amount: String
    var unit: String
}

// MARK: - 成分行视图

struct IngredientRow: View {
    @Binding var ingredient: IngredientInput
    let onDelete: () -> Void

    @FocusState private var isNameFocused: Bool
    @FocusState private var isAmountFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            // 名称输入
            HStack {
                Text("名称")
                    .frame(width: 50, alignment: .leading)
                TextField("例如：面粉", text: $ingredient.name)
                    .focused($isNameFocused)
            }

            // 数量和单位
            HStack {
                Text("数量")
                    .frame(width: 50, alignment: .leading)

                TextField("100", text: $ingredient.amount)
                    .keyboardType(.decimalPad)
                    .focused($isAmountFocused)
                    .frame(maxWidth: .infinity)

                Picker("单位", selection: $ingredient.unit) {
                    ForEach(FeedingUnit.allCases, id: \.rawValue) { unit in
                        Text(unit.displayName).tag(unit.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 80)
            }

            // 删除按钮
            HStack {
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Label("删除", systemImage: "trash")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 常用成分选择视图

struct CommonIngredientsView: View {
    @Environment(\.dismiss) private var dismiss

    let fermentationType: String
    let onSelect: (CommonIngredient) -> Void

    private var commonIngredients: [CommonIngredient] {
        CommonIngredient.getCommonIngredients(for: fermentationType)
    }

    var body: some View {
        NavigationStack {
            List {
                if commonIngredients.isEmpty {
                    Text("该类型暂无常用成分预设")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(commonIngredients, id: \.name) { ingredient in
                        Button(action: {
                            onSelect(ingredient)
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ingredient.name)
                                    .font(.body)

                                HStack {
                                    Text("默认：\(Int(ingredient.commonAmounts.first ?? 0))\(ingredient.defaultUnit.displayName)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    Text("常用：\(ingredient.commonAmounts.map { String(Int($0)) }.joined(separator: ", "))\(ingredient.defaultUnit.displayName)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("常用成分")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 文本解析视图

struct TextParserView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    let onParse: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("输入投料配方")
                    .font(.headline)

                Text("支持格式：")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("• 面粉100g + 水90ml")
                    Text("• 高筋面粉 150克")
                    Text("• 留种50g，面粉100g，水90g")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                TextField("粘贴或输入配方", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(5...10)

                Spacer()

                Button(action: {
                    onParse(text)
                    dismiss()
                }) {
                    Text("解析")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.isEmpty)
            }
            .padding()
            .navigationTitle("文本解析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 预览

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fermentation.self, Record.self, configurations: config)

    let fermentation = Fermentation(name: "测试酸面团", status: "active")
    let record = Record(fermentation: fermentation, content: "测试记录", status: "normal")

    container.mainContext.insert(fermentation)
    container.mainContext.insert(record)

    return FeedingInputView(record: record, fermentationType: "酸面团")
        .modelContainer(container)
}
