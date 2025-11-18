//
//  EnvironmentInputView.swift
//  FermentPal
//
//  环境数据录入界面 - P1功能UI
//  用户友好的环境因素记录和分析界面
//

import SwiftUI
import SwiftData

// MARK: - 环境录入视图

struct EnvironmentInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let record: Record
    let fermentationType: String

    @State private var temperature: String = ""
    @State private var humidity: String = ""
    @State private var selectedLocation: String = EnvironmentLocation.kitchen.rawValue
    @State private var selectedContainer: String = ContainerType.glassJar.rawValue
    @State private var notes: String = ""

    @State private var environmentData: EnvironmentData?
    @State private var analysis: EnvironmentAnalysis?
    @State private var showingIdealParams: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

    private var service: FermentationService {
        FermentationService(modelContext: modelContext)
    }

    private var idealParams: IdealEnvironment {
        service.getIdealEnvironment(for: fermentationType)
    }

    var body: some View {
        NavigationStack {
            Form {
                // 理想参数提示
                idealParametersSection

                // 温度输入
                temperatureSection

                // 湿度输入
                humiditySection

                // 位置选择
                locationSection

                // 容器类型选择
                containerSection

                // 备注
                notesSection

                // 环境分析
                if let analysis = analysis {
                    analysisSection(analysis)
                }
            }
            .navigationTitle("记录环境数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveEnvironmentData()
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingIdealParams) {
                IdealParametersView(idealParams: idealParams, fermentationType: fermentationType)
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onChange(of: temperature) { _, _ in updateAnalysis() }
            .onChange(of: humidity) { _, _ in updateAnalysis() }
            .onChange(of: selectedLocation) { _, _ in updateAnalysis() }
            .onChange(of: selectedContainer) { _, _ in updateAnalysis() }
        }
    }

    // MARK: - 视图组件

    private var idealParametersSection: some View {
        Section {
            Button(action: { showingIdealParams = true }) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("查看理想参数")
                            .font(.subheadline)
                        Text("\(fermentationType)的最佳环境条件")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("参考建议")
        }
    }

    private var temperatureSection: some View {
        Section {
            HStack {
                Text("温度")
                Spacer()
                TextField("例如：25", text: $temperature)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                Text("°C")
                    .foregroundStyle(.secondary)
            }

            // 温度状态指示
            if let temp = Double(temperature) {
                HStack {
                    Image(systemName: temperatureIcon(temp))
                        .foregroundStyle(temperatureColor(temp))
                    Text(temperatureStatusText(temp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("温度")
        } footer: {
            Text("理想范围：\(idealParams.temperatureDescription)")
        }
    }

    private var humiditySection: some View {
        Section {
            HStack {
                Text("湿度")
                Spacer()
                TextField("例如：70", text: $humidity)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                Text("%")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("湿度（可选）")
        } footer: {
            Text("理想范围：\(idealParams.humidityDescription)")
        }
    }

    private var locationSection: some View {
        Section {
            Picker("位置", selection: $selectedLocation) {
                ForEach(EnvironmentLocation.allCases, id: \.rawValue) { location in
                    HStack {
                        Image(systemName: location.icon)
                        Text(location.rawValue)
                    }
                    .tag(location.rawValue)
                }
            }
        } header: {
            Text("存放位置")
        }
    }

    private var containerSection: some View {
        Section {
            Picker("容器类型", selection: $selectedContainer) {
                ForEach(ContainerType.allCases, id: \.rawValue) { container in
                    HStack {
                        Image(systemName: container.icon)
                        Text(container.rawValue)
                    }
                    .tag(container.rawValue)
                }
            }

            // 容器建议
            if let containerType = ContainerType(rawValue: selectedContainer) {
                Text(containerType.recommendation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("容器类型")
        }
    }

    private var notesSection: some View {
        Section {
            TextField("其他环境备注", text: $notes, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            Text("备注（可选）")
        }
    }

    private func analysisSection(_ analysis: EnvironmentAnalysis) -> some View {
        Section {
            // 评分
            HStack {
                Text("环境评分")
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.0f", analysis.score))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(analysisColor(analysis.status))
                Text("/ 100")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 状态
            HStack {
                Image(systemName: analysisIcon(analysis.status))
                    .foregroundStyle(analysisColor(analysis.status))
                Text(analysis.status.displayName)
                    .font(.subheadline)
            }

            // 警告
            if analysis.hasWarnings {
                ForEach(analysis.warnings, id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            // 建议
            if analysis.hasTips {
                ForEach(analysis.tips, id: \.self) { tip in
                    Label(tip, systemImage: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
        } header: {
            Text("环境分析")
        }
    }

    // MARK: - 辅助方法

    private var canSave: Bool {
        !temperature.isEmpty
    }

    private func updateAnalysis() {
        guard let temp = Double(temperature) else {
            analysis = nil
            return
        }

        let env = EnvironmentData(
            temperature: temp,
            humidity: Double(humidity),
            location: selectedLocation,
            containerType: selectedContainer
        )

        analysis = service.analyzeEnvironment(env, fermentationType: fermentationType)
    }

    private func saveEnvironmentData() {
        guard let temp = Double(temperature) else {
            errorMessage = "请输入有效的温度"
            showingError = true
            return
        }

        do {
            _ = try service.addEnvironmentData(
                to: record,
                temperature: temp,
                humidity: Double(humidity),
                location: selectedLocation,
                containerType: selectedContainer,
                notes: notes.isEmpty ? nil : notes
            )

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    // MARK: - 温度状态辅助

    private func temperatureIcon(_ temp: Double) -> String {
        if temp < 15 { return "snowflake" }
        if temp < 20 { return "thermometer.low" }
        if temp <= 28 { return "thermometer.medium" }
        if temp <= 35 { return "thermometer.high" }
        return "flame.fill"
    }

    private func temperatureColor(_ temp: Double) -> Color {
        if temp < 15 { return .blue }
        if temp < 20 { return .cyan }
        if temp <= 28 { return .green }
        if temp <= 35 { return .orange }
        return .red
    }

    private func temperatureStatusText(_ temp: Double) -> String {
        if temp < 15 { return "过低" }
        if temp < 20 { return "偏低" }
        if temp <= 28 { return "理想" }
        if temp <= 35 { return "偏高" }
        return "过高"
    }

    private func analysisIcon(_ status: EnvironmentStatus) -> String {
        switch status {
        case .excellent: return "checkmark.seal.fill"
        case .good: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .danger: return "xmark.octagon.fill"
        }
    }

    private func analysisColor(_ status: EnvironmentStatus) -> Color {
        switch status {
        case .excellent: return .green
        case .good: return .blue
        case .warning: return .orange
        case .danger: return .red
        }
    }
}

// MARK: - 理想参数展示视图

struct IdealParametersView: View {
    @Environment(\.dismiss) private var dismiss

    let idealParams: IdealEnvironment
    let fermentationType: String

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "thermometer.medium")
                            .foregroundStyle(.orange)
                        Text("温度")
                        Spacer()
                        Text(idealParams.temperatureDescription)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Image(systemName: "humidity.fill")
                            .foregroundStyle(.blue)
                        Text("湿度")
                        Spacer()
                        Text(idealParams.humidityDescription)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.green)
                        Text("位置")
                        Spacer()
                        Text(idealParams.location)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Image(systemName: "cube.fill")
                            .foregroundStyle(.purple)
                        Text("容器")
                        Spacer()
                        Text(idealParams.container)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("\(fermentationType) 的理想环境")
                }

                Section {
                    Text(idealParams.notes)
                        .font(.callout)
                } header: {
                    Text("注意事项")
                }
            }
            .navigationTitle("理想参数")
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

// MARK: - 预览

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fermentation.self, Record.self, configurations: config)

    let fermentation = Fermentation(name: "测试酸面团", status: "active")
    let record = Record(fermentation: fermentation, content: "测试记录", status: "normal")

    container.mainContext.insert(fermentation)
    container.mainContext.insert(record)

    return EnvironmentInputView(record: record, fermentationType: "酸面团")
        .modelContainer(container)
}
