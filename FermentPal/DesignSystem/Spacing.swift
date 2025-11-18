//
//  Spacing.swift
//  FermentPal
//
//  统一间距系统 - iOS原生体验
//  基于4pt网格系统
//

import SwiftUI

// MARK: - 间距系统

extension CGFloat {
    // MARK: - 基础间距（4pt网格）

    /// 极小间距 - 2pt
    static let spacingXXS: CGFloat = 2

    /// 最小间距 - 4pt
    static let spacingXS: CGFloat = 4

    /// 小间距 - 8pt
    static let spacingSM: CGFloat = 8

    /// 中等间距 - 12pt
    static let spacingMD: CGFloat = 12

    /// 大间距 - 16pt
    static let spacingLG: CGFloat = 16

    /// 特大间距 - 20pt
    static let spacingXL: CGFloat = 20

    /// 超大间距 - 24pt
    static let spacingXXL: CGFloat = 24

    /// 巨大间距 - 32pt
    static let spacing3XL: CGFloat = 32

    /// 超级间距 - 40pt
    static let spacing4XL: CGFloat = 40

    // MARK: - 语义化间距

    /// 卡片内边距
    static let cardPadding: CGFloat = 16

    /// 卡片间距
    static let cardSpacing: CGFloat = 12

    /// 列表项内边距
    static let listItemPadding: CGFloat = 16

    /// 列表项间距
    static let listItemSpacing: CGFloat = 8

    /// Section间距
    static let sectionSpacing: CGFloat = 24

    /// 页面边距
    static let pageMargin: CGFloat = 16

    /// 按钮内边距（垂直）
    static let buttonPaddingVertical: CGFloat = 14

    /// 按钮内边距（水平）
    static let buttonPaddingHorizontal: CGFloat = 20

    /// 小按钮内边距（垂直）
    static let buttonSmallPaddingVertical: CGFloat = 10

    /// 小按钮内边距（水平）
    static let buttonSmallPaddingHorizontal: CGFloat = 16

    // MARK: - 圆角

    /// 小圆角 - 4pt
    static let cornerRadiusXS: CGFloat = 4

    /// 中圆角 - 8pt
    static let cornerRadiusSM: CGFloat = 8

    /// 标准圆角 - 12pt
    static let cornerRadiusMD: CGFloat = 12

    /// 大圆角 - 16pt
    static let cornerRadiusLG: CGFloat = 16

    /// 超大圆角 - 20pt
    static let cornerRadiusXL: CGFloat = 20

    /// 圆形
    static let cornerRadiusCircle: CGFloat = 999

    // MARK: - 语义化圆角

    /// 卡片圆角
    static let cardCornerRadius: CGFloat = 12

    /// 按钮圆角
    static let buttonCornerRadius: CGFloat = 12

    /// 徽章圆角
    static let badgeCornerRadius: CGFloat = 999

    /// 输入框圆角
    static let inputCornerRadius: CGFloat = 10

    // MARK: - 阴影

    /// 卡片阴影半径
    static let cardShadowRadius: CGFloat = 4

    /// 按钮阴影半径
    static let buttonShadowRadius: CGFloat = 2

    /// 浮动按钮阴影半径
    static let fabShadowRadius: CGFloat = 8

    // MARK: - 图标尺寸

    /// 小图标 - 16pt
    static let iconSizeSmall: CGFloat = 16

    /// 中图标 - 20pt
    static let iconSizeMedium: CGFloat = 20

    /// 大图标 - 24pt
    static let iconSizeLarge: CGFloat = 24

    /// 特大图标 - 32pt
    static let iconSizeXLarge: CGFloat = 32

    /// 超大图标 - 48pt
    static let iconSizeXXLarge: CGFloat = 48

    // MARK: - 徽章尺寸

    /// 徽章内边距（水平）
    static let badgePaddingHorizontal: CGFloat = 8

    /// 徽章内边距（垂直）
    static let badgePaddingVertical: CGFloat = 4

    /// 小徽章内边距（水平）
    static let badgeSmallPaddingHorizontal: CGFloat = 6

    /// 小徽章内边距（垂直）
    static let badgeSmallPaddingVertical: CGFloat = 2
}

// MARK: - EdgeInsets 扩展

extension EdgeInsets {
    /// 卡片内边距
    static let card = EdgeInsets(
        top: .cardPadding,
        leading: .cardPadding,
        bottom: .cardPadding,
        trailing: .cardPadding
    )

    /// 列表项内边距
    static let listItem = EdgeInsets(
        top: .listItemPadding,
        leading: .listItemPadding,
        bottom: .listItemPadding,
        trailing: .listItemPadding
    )

    /// 页面内边距
    static let page = EdgeInsets(
        top: .pageMargin,
        leading: .pageMargin,
        bottom: .pageMargin,
        trailing: .pageMargin
    )

    /// 对称内边距
    static func symmetric(horizontal: CGFloat = 0, vertical: CGFloat = 0) -> EdgeInsets {
        EdgeInsets(
            top: vertical,
            leading: horizontal,
            bottom: vertical,
            trailing: horizontal
        )
    }

    /// 所有边相同的内边距
    static func all(_ value: CGFloat) -> EdgeInsets {
        EdgeInsets(top: value, leading: value, bottom: value, trailing: value)
    }
}

// MARK: - 预览

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            // 间距示例
            spacingSection(title: "间距系统", spacings: [
                ("极小 (2pt)", CGFloat.spacingXXS),
                ("最小 (4pt)", CGFloat.spacingXS),
                ("小 (8pt)", CGFloat.spacingSM),
                ("中 (12pt)", CGFloat.spacingMD),
                ("大 (16pt)", CGFloat.spacingLG),
                ("特大 (20pt)", CGFloat.spacingXL),
                ("超大 (24pt)", CGFloat.spacingXXL)
            ])

            Divider()

            // 圆角示例
            cornerRadiusSection(title: "圆角系统", corners: [
                ("小 (4pt)", CGFloat.cornerRadiusXS),
                ("中 (8pt)", CGFloat.cornerRadiusSM),
                ("标准 (12pt)", CGFloat.cornerRadiusMD),
                ("大 (16pt)", CGFloat.cornerRadiusLG),
                ("超大 (20pt)", CGFloat.cornerRadiusXL)
            ])

            Divider()

            // 图标尺寸示例
            iconSizeSection(title: "图标尺寸", sizes: [
                ("小 (16pt)", CGFloat.iconSizeSmall),
                ("中 (20pt)", CGFloat.iconSizeMedium),
                ("大 (24pt)", CGFloat.iconSizeLarge),
                ("特大 (32pt)", CGFloat.iconSizeXLarge),
                ("超大 (48pt)", CGFloat.iconSizeXXLarge)
            ])
        }
        .padding()
    }
}

private func spacingSection(title: String, spacings: [(String, CGFloat)]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text(title)
            .font(.headline)

        ForEach(spacings, id: \.0) { name, spacing in
            HStack {
                Text(name)
                    .font(.caption)
                    .frame(width: 100, alignment: .leading)

                Rectangle()
                    .fill(Color.blue)
                    .frame(width: spacing, height: 20)

                Text("\(Int(spacing))pt")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private func cornerRadiusSection(title: String, corners: [(String, CGFloat)]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text(title)
            .font(.headline)

        HStack(spacing: 12) {
            ForEach(corners, id: \.0) { name, radius in
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)

                    Text(name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private func iconSizeSection(title: String, sizes: [(String, CGFloat)]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text(title)
            .font(.headline)

        HStack(spacing: 16) {
            ForEach(sizes, id: \.0) { name, size in
                VStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: size))
                        .foregroundStyle(.orange)

                    Text(name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
