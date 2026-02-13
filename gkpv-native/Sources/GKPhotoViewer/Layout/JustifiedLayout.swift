import SwiftUI

// MARK: - Aspect ratio layout value

private struct JustifiedAspectRatioKey: LayoutValueKey {
    static let defaultValue: CGFloat = 1.0
}

extension View {
    func justifiedAspectRatio(_ ratio: CGFloat) -> some View {
        layoutValue(key: JustifiedAspectRatioKey.self, value: ratio)
    }
}

// MARK: - Justified Layout

struct JustifiedLayout: Layout {
    let targetRowHeight: CGFloat
    let spacing: CGFloat

    struct RowInfo {
        var indices: [Int]
        var height: CGFloat
        var y: CGFloat
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? 800
        let rows = computeRows(subviews: subviews, containerWidth: containerWidth)
        let totalHeight = rows.last.map { $0.y + $0.height } ?? 0
        return CGSize(width: containerWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let containerWidth = bounds.width
        let rows = computeRows(subviews: subviews, containerWidth: containerWidth)

        for row in rows {
            var x: CGFloat = bounds.minX
            for idx in row.indices {
                let aspect = subviews[idx][JustifiedAspectRatioKey.self]
                let w = round(aspect * row.height)
                let size = ProposedViewSize(width: w, height: row.height)
                subviews[idx].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: size)
                x += w + spacing
            }
        }
    }

    private func computeRows(subviews: Subviews, containerWidth: CGFloat) -> [RowInfo] {
        var rows: [RowInfo] = []
        var currentRow: [Int] = []
        var rowAspectSum: CGFloat = 0
        var y: CGFloat = 0

        for i in subviews.indices {
            let aspect = subviews[i][JustifiedAspectRatioKey.self]
            currentRow.append(i)
            rowAspectSum += aspect

            let usableW = containerWidth - spacing * CGFloat(currentRow.count - 1)
            let rowH = usableW / rowAspectSum

            if rowH <= targetRowHeight && !currentRow.isEmpty {
                let h = round(rowH)
                rows.append(RowInfo(indices: currentRow, height: h, y: y))
                y += h + spacing
                currentRow = []
                rowAspectSum = 0
            }
        }

        // Last (incomplete) row
        if !currentRow.isEmpty {
            let usableW = containerWidth - spacing * CGFloat(currentRow.count - 1)
            let h = round(min(targetRowHeight, usableW / rowAspectSum))
            rows.append(RowInfo(indices: currentRow, height: h, y: y))
        }

        return rows
    }
}
