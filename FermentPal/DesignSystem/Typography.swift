//
//  Typography.swift
//  FermentPal
//
//  统一字体系统 - iOS原生体验
//  优化中文显示，支持动态字体
//

import SwiftUI

// MARK: - 字体系统

extension Font {
    // MARK: - 标题系统

    /// 大标题 - 用于页面主标题
    static let appLargeTitle = Font.system(size: 34, weight: .bold, design: .rounded)

    /// 标题1 - 用于区块标题
    static let appTitle1 = Font.system(size: 28, weight: .bold, design: .rounded)

    /// 标题2 - 用于次级标题
    static let appTitle2 = Font.system(size: 22, weight: .bold, design: .rounded)

    /// 标题3 - 用于小节标题
    static let appTitle3 = Font.system(size: 20, weight: .semibold, design: .rounded)

    // MARK: - 正文系统

    /// 卡片标题 - 用于列表项标题
    static let cardTitle = Font.system(size: 17, weight: .semibold)

    /// 正文 - 用于主要内容
    static let body = Font.system(size: 17, weight: .regular)

    /// 正文强调 - 用于需要强调的正文
    static let bodyEmphasized = Font.system(size: 17, weight: .medium)

    /// 小正文 - 用于次要内容
    static let callout = Font.system(size: 16, weight: .regular)

    /// 小正文强调
    static let calloutEmphasized = Font.system(size: 16, weight: .medium)

    // MARK: - 辅助文本

    /// 次要文本
    static let subheadline = Font.system(size: 15, weight: .regular)

    /// 次要文本强调
    static let subheadlineEmphasized = Font.system(size: 15, weight: .medium)

    /// 脚注
    static let footnote = Font.system(size: 13, weight: .regular)

    /// 说明文字
    static let caption = Font.system(size: 12, weight: .regular)

    /// 说明文字强调
    static let captionEmphasized = Font.system(size: 12, weight: .medium)

    /// 最小文字
    static let caption2 = Font.system(size: 11, weight: .regular)

    // MARK: - 数字显示

    /// 大数字 - 用于统计数据
    static let numberLarge = Font.system(size: 34, weight: .bold, design: .rounded)

    /// 中数字 - 用于卡片数字
    static let numberMedium = Font.system(size: 24, weight: .bold, design: .rounded)

    /// 小数字 - 用于徽章
    static let numberSmall = Font.system(size: 14, weight: .semibold, design: .rounded)

    // MARK: - 特殊用途

    /// 按钮文字
    static let button = Font.system(size: 17, weight: .semibold)

    /// 小按钮文字
    static let buttonSmall = Font.system(size: 15, weight: .medium)

    /// 徽章文字
    static let badge = Font.system(size: 11, weight: .semibold)

    /// 标签文字
    static let label = Font.system(size: 14, weight: .medium)
}

// MARK: - 文本修饰符

struct AppTextStyle: ViewModifier {
    let lineSpacing: CGFloat
    let kerning: CGFloat

    func body(content: Content) -> some View {
        content
            .lineSpacing(lineSpacing)
            .kerning(kerning)
    }
}

extension View {
    /// 应用中文优化的文本样式
    func appTextStyle(lineSpacing: CGFloat = 4, kerning: CGFloat = 0.3) -> some View {
        modifier(AppTextStyle(lineSpacing: lineSpacing, kerning: kerning))
    }

    /// 标题文本样式
    func titleTextStyle() -> some View {
        self
            .lineSpacing(6)
            .kerning(0.5)
    }

    /// 正文文本样式
    func bodyTextStyle() -> some View {
        self
            .lineSpacing(4)
            .kerning(0.3)
    }

    /// 说明文本样式
    func captionTextStyle() -> some View {
        self
            .lineSpacing(2)
            .kerning(0.2)
    }
}

// MARK: - 预览

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            // 标题
            Group {
                Text("大标题 - Large Title")
                    .font(.appLargeTitle)

                Text("标题1 - Title 1")
                    .font(.appTitle1)

                Text("标题2 - Title 2")
                    .font(.appTitle2)

                Text("标题3 - Title 3")
                    .font(.appTitle3)
            }

            Divider()

            // 正文
            Group {
                Text("卡片标题 - Card Title")
                    .font(.cardTitle)

                Text("正文 - Body Text")
                    .font(.body)

                Text("小正文 - Callout")
                    .font(.callout)
            }

            Divider()

            // 辅助文本
            Group {
                Text("次要文本 - Subheadline")
                    .font(.subheadline)

                Text("脚注 - Footnote")
                    .font(.footnote)

                Text("说明文字 - Caption")
                    .font(.caption)
            }

            Divider()

            // 数字
            Group {
                Text("1,234")
                    .font(.numberLarge)

                Text("567")
                    .font(.numberMedium)

                Text("89")
                    .font(.numberSmall)
            }

            Divider()

            // 中文优化示例
            VStack(alignment: .leading, spacing: 12) {
                Text("中文文本优化示例")
                    .font(.headline)

                Text("这是一段中文文本，经过行高和字间距优化后，阅读体验会更好。发酵笔记应用专注于记录发酵过程的每一个细节。")
                    .font(.body)
                    .bodyTextStyle()

                Text("未优化版本")
                    .font(.headline)

                Text("这是一段中文文本，经过行高和字间距优化后，阅读体验会更好。发酵笔记应用专注于记录发酵过程的每一个细节。")
                    .font(.body)
            }
        }
        .padding()
    }
}
