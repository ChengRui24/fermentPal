//
//  ReferenceCaseView.swift
//  FermentPal
//
//  参考案例库界面 - P2功能UI
//  成功/失败案例展示和新手引导
//

import SwiftUI

// MARK: - 参考案例库主视图

struct ReferenceCaseView: View {
    @State private var selectedType: FermentationType = .sourdough
    @State private var selectedCase: ReferenceCase?
    @State private var showingOnboarding: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 类型选择器
                fermentationTypePicker

                // 案例列表
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // 新手引导入口
                        onboardingCard

                        // 成功案例
                        casesSection(
                            title: "成功案例",
                            icon: "checkmark.seal.fill",
                            color: .green,
                            cases: successCases
                        )

                        // 失败案例
                        casesSection(
                            title: "失败案例（警示）",
                            icon: "exclamationmark.triangle.fill",
                            color: .orange,
                            cases: failureCases
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("参考案例库")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedCase) { caseItem in
                CaseDetailView(case: caseItem)
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingGuideView(type: selectedType)
            }
        }
    }

    // MARK: - 视图组件

    private var fermentationTypePicker: some View {
        Picker("发酵类型", selection: $selectedType) {
            ForEach(FermentationType.allCases, id: \.self) { type in
                Text(type.displayName).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }

    private var onboardingCard: some View {
        Button(action: { showingOnboarding = true }) {
            HStack(spacing: .spacingLG) {
                Image(systemName: "book.fill")
                    .font(.iconSizeXLarge)
                    .foregroundStyle(Color.info)

                VStack(alignment: .leading, spacing: .spacingSM) {
                    Text("新手引导")
                        .font(.cardTitle)
                        .foregroundStyle(Color.textPrimary)

                    Text("从零开始学习\(selectedType.displayName)发酵")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.textTertiary)
            }
            .padding(.pageMargin)
            .background(Color.info.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius))
        }
        .buttonStyle(.plain)
    }

    private func casesSection(
        title: String,
        icon: String,
        color: Color,
        cases: [ReferenceCase]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
            }

            // 案例卡片
            if cases.isEmpty {
                Text("暂无案例")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(cases) { caseItem in
                    CaseCard(case: caseItem)
                        .onTapGesture {
                            selectedCase = caseItem
                        }
                }
            }
        }
    }

    // MARK: - 数据过滤

    private var successCases: [ReferenceCase] {
        ReferenceCaseLibrary.getSuccessCases(for: selectedType)
    }

    private var failureCases: [ReferenceCase] {
        ReferenceCaseLibrary.getFailureCases(for: selectedType)
    }
}

// MARK: - 案例卡片视图

struct CaseCard: View {
    let `case`: ReferenceCase

    var body: some View {
        UnifiedCard {
            VStack(alignment: .leading, spacing: .spacingMD) {
                // 标题和状态
                HStack {
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text(`case`.title)
                            .font(.cardTitle)
                            .foregroundStyle(Color.textPrimary)

                        Text(`case`.stage)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    // 状态徽章
                    EnhancedBadge(
                        text: `case`.status == .success ? "成功" : "失败",
                        icon: `case`.status == .success ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                        color: statusColor,
                        size: .small
                    )
                }

                // 关键指标
                if !`case`.indicators.isEmpty {
                    HStack(spacing: .spacingLG) {
                        ForEach(`case`.indicators.prefix(3)) { indicator in
                            VStack(alignment: .leading, spacing: .spacingXS) {
                                Text(indicator.name)
                                    .font(.caption2)
                                    .foregroundStyle(Color.textSecondary)
                                Text(indicator.value)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.textPrimary)
                            }
                        }
                    }
                }

                // 简短描述
                if let summary = `case`.summary {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                        .bodyTextStyle()
                }
            }
        }
        .background(statusColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: .cardCornerRadius))
    }

    private var statusColor: Color {
        `case`.status == .success ? .success : .warning
    }
}

// MARK: - 案例详情视图

struct CaseDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let `case`: ReferenceCase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 头部信息
                    headerSection

                    // 关键指标
                    if !`case`.indicators.isEmpty {
                        indicatorsSection
                    }

                    // 时间线
                    if !`case`.timeline.isEmpty {
                        timelineSection
                    }

                    // 注意事项
                    if !`case`.tips.isEmpty {
                        tipsSection
                    }

                    // 原因分析（失败案例）
                    if `case`.status == .failure, let cause = `case`.failureCause {
                        causeSection(cause)
                    }

                    // 预防措施（失败案例）
                    if `case`.status == .failure, !`case`.prevention.isEmpty {
                        preventionSection
                    }
                }
                .padding()
            }
            .navigationTitle("案例详情")
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

    // MARK: - 视图组件

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(`case`.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(`case`.stage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 状态标志
                VStack {
                    Image(systemName: `case`.status == .success ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(`case`.status == .success ? .green : .orange)

                    Text(`case`.status == .success ? "成功" : "失败")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }

            if let description = `case`.description {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var indicatorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("关键指标")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(`case`.indicators) { indicator in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(indicator.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(indicator.value)
                            .font(.body)
                            .fontWeight(.medium)

                        if let note = indicator.note {
                            Text(note)
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("发展时间线")
                .font(.headline)

            ForEach(`case`.timeline) { entry in
                HStack(alignment: .top, spacing: 12) {
                    // 时间标记
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)

                        if entry.id != `case`.timeline.last?.id {
                            Rectangle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 2, height: 40)
                        }
                    }

                    // 内容
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.time)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)

                        Text(entry.description)
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("注意事项")
                .font(.headline)

            ForEach(`case`.tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)

                    Text(tip)
                        .font(.callout)
                }
            }
        }
    }

    private func causeSection(_ cause: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("失败原因")
                .font(.headline)

            Text(cause)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var preventionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("如何避免")
                .font(.headline)

            ForEach(`case`.prevention, id: \.self) { prevention in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(.green)
                        .font(.caption)

                    Text(prevention)
                        .font(.callout)
                }
            }
        }
    }
}

// MARK: - 新手引导视图

struct OnboardingGuideView: View {
    @Environment(\.dismiss) private var dismiss

    let type: FermentationType

    var body: some View {
        NavigationStack {
            List {
                // 介绍
                Section {
                    Text("欢迎使用\(type.displayName)发酵记录系统！\n\n这里是基础的发酵记录指南，帮助你系统地记录和管理发酵过程。")
                        .font(.body)
                } header: {
                    Text("欢迎")
                }

                // 步骤
                ForEach(OnboardingGuide.steps.indices, id: \.self) { index in
                    Section {
                        StepCard(step: OnboardingGuide.steps[index], number: index + 1)
                    }
                }

                // 快速入门模板
                Section {
                    ForEach(OnboardingGuide.quickStartTemplates.filter { $0.type == type }, id: \.name) { template in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(template.name)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text(template.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("时长：\(template.duration)")
                                .font(.caption2)
                                .foregroundStyle(.blue)

                            ForEach(template.steps.indices, id: \.self) { idx in
                                Text("• \(template.steps[idx])")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("快速入门")
                }
            }
            .navigationTitle("\(type.displayName)新手指南")
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

// MARK: - 步骤卡片

struct StepCard: View {
    let step: OnboardingStep
    let number: Int

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 步骤编号
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            // 内容
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: step.icon)
                        .foregroundStyle(.blue)
                    Text(step.title)
                        .font(.headline)
                }

                if !step.tips.isEmpty {
                    ForEach(step.tips, id: \.self) { tip in
                        Text("• \(tip)")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - 预览

#Preview("案例库") {
    ReferenceCaseView()
}

#Preview("案例详情") {
    let testCase = ReferenceCase(
        type: .sourdough,
        title: "健康的酸面团",
        stage: "12小时",
        status: .success,
        indicators: [
            Indicator(name: "体积", value: "翻倍", note: "理想"),
            Indicator(name: "气泡", value: "丰富", note: nil)
        ],
        timeline: [
            TimelineEntry(time: "0小时", description: "投料完成"),
            TimelineEntry(time: "6小时", description: "开始膨胀"),
            TimelineEntry(time: "12小时", description: "达到峰值")
        ],
        tips: ["保持温度25°C", "使用玻璃容器"],
        summary: "正常发酵的标准示例"
    )

    CaseDetailView(case: testCase)
}

#Preview("新手引导") {
    OnboardingGuideView(type: .sourdough)
}
