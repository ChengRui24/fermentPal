//
//  Components.swift
//  FermentPal
//
//  可复用的UI组件
//

import SwiftUI
import SwiftData

// MARK: - 状态徽章组件
// 注意：StatusBadge现在在ContentView.swift中使用EnhancedBadge实现
// 这个旧版本已注释掉以避免重复声明

// MARK: - 记录状态徽章

struct RecordStatusBadge: View {
    let status: RecordStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
            Text(status.displayName)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - 分装标签组件

struct DistributionLabelBadge: View {
    let label: DistributionLabel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: label.icon)
                .font(.caption2)
            Text(label.rawValue)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.15))
        .foregroundStyle(.blue)
        .clipShape(Capsule())
    }
}

// MARK: - 空状态视图

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String?

    init(icon: String, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))

            Text(title)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - 加载视图

struct LoadingView: View {
    let message: String

    init(message: String = "加载中...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 错误视图

struct ErrorView: View {
    let error: Error
    let retryAction: (() -> Void)?

    init(error: Error, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.red)

            Text("出错了")
                .font(.title2)
                .fontWeight(.medium)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let suggestion = (error as? LocalizedError)?.recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if let retry = retryAction {
                Button(action: retry) {
                    Label("重试", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
    }
}

// MARK: - 统计项组件

struct StatItemView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    init(icon: String, value: String, label: String, color: Color = .blue) {
        self.icon = icon
        self.value = value
        self.label = label
        self.color = color
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

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

// MARK: - 时间显示组件

struct TimeAgoView: View {
    let date: Date
    let locale: Locale

    init(date: Date, locale: Locale = Locale(identifier: "zh_CN")) {
        self.date = date
        self.locale = locale
    }

    var body: some View {
        Text(date, style: .relative)
            .environment(\.locale, locale)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

struct DateTimeView: View {
    let date: Date
    let locale: Locale
    let showTime: Bool

    init(date: Date, locale: Locale = Locale(identifier: "zh_CN"), showTime: Bool = false) {
        self.date = date
        self.locale = locale
        self.showTime = showTime
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(date, style: .date)
                .environment(\.locale, locale)

            if showTime {
                Text(date, style: .time)
                    .environment(\.locale, locale)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

// MARK: - 投料显示组件

struct FeedingContentView: View {
    let content: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "leaf.fill")
                .font(.caption)
                .foregroundStyle(.green)

            Text("投料：\(content)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - 分隔线组件

struct SectionDivider: View {
    let title: String?

    init(title: String? = nil) {
        self.title = title
    }

    var body: some View {
        HStack {
            if let title = title {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 信息行组件

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String?

    init(label: String, value: String, icon: String? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
    }

    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
            }

            Text(label)
                .font(.headline)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 快捷按钮组件

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption)
            }
            .foregroundStyle(color)
        }
    }
}

// MARK: - 确认对话框

struct ConfirmationDialog: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String?
    let confirmTitle: String
    let confirmRole: ButtonRole?
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button(confirmTitle, role: confirmRole, action: onConfirm)
                Button("取消", role: .cancel) { }
            } message: {
                if let message = message {
                    Text(message)
                }
            }
    }
}

extension View {
    func confirmationDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        confirmTitle: String = "确认",
        confirmRole: ButtonRole? = nil,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(ConfirmationDialog(
            isPresented: isPresented,
            title: title,
            message: message,
            confirmTitle: confirmTitle,
            confirmRole: confirmRole,
            onConfirm: onConfirm
        ))
    }
}

// MARK: - 卡片容器

struct CardContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview("状态徽章") {
    VStack(spacing: 16) {
        StatusBadge(status: .active)
        StatusBadge(status: .completed)
        StatusBadge(status: .discarded)

        RecordStatusBadge(status: .normal)
        RecordStatusBadge(status: .watch)
        RecordStatusBadge(status: .abnormal)
    }
    .padding()
}

#Preview("空状态") {
    EmptyStateView(
        icon: "list.bullet.clipboard",
        title: "暂无记录",
        subtitle: "点击底部的记录按钮开始记录发酵过程"
    )
}

#Preview("错误视图") {
    ErrorView(
        error: FermentationError.invalidName(""),
        retryAction: { print("Retry") }
    )
}
