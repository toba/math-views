import CoreGraphics
import Foundation

extension Typesetter {
    // MARK: - Table

    var kBaseLineSkipMultiplier: CGFloat { 1.2 } // default base line stretch is 12 pt for 10pt font.
    var kLineSkipMultiplier: CGFloat { 0.1 } // default is 1pt for 10pt font.
    var kLineSkipLimitMultiplier: CGFloat { 0 }
    var kJotMultiplier: CGFloat { 0.3 } // A jot is 3pt for a 10pt font.

    func makeTable(_ table: MathTable?) -> Display? {
        let numColumns = table!.numColumns
        if numColumns == 0 || table!.numRows == 0 {
            // Empty table
            return MathListDisplay(displays: [Display](), range: table!.indexRange)
        }

        var columnWidths = [CGFloat](repeating: 0, count: numColumns)
        let displays = typesetCells(table, columnWidths: &columnWidths)

        // Position all the columns in each row
        var rowDisplays = [Display]()
        for row in displays {
            if let rowDisplay = makeRowWithColumns(row, forTable: table, columnWidths: columnWidths)
            {
                rowDisplays.append(rowDisplay)
            }
        }

        // Position all the rows
        positionRows(rowDisplays, forTable: table)
        let tableDisplay = MathListDisplay(displays: rowDisplays, range: table!.indexRange)
        tableDisplay.position = currentPosition
        return tableDisplay
    }

    // Typeset every cell in the table. As a side-effect calculate the max column width of each column.
    func typesetCells(_ table: MathTable?, columnWidths: inout [CGFloat]) -> [[Display]] {
        var displays = [[Display]]()
        for row in table!.cells {
            var colDisplays = [Display]()
            for i in 0 ..< row.count {
                // CRITICAL FIX: Pass maxWidth AND cramped to enable proper line breaking within table cells
                // Without maxWidth, table rows (created by \\ in LaTeX) bypass width constraints
                // causing content overflow and truncation
                // Pass cramped state to maintain consistent typesetting context with parent
                if let disp = Typesetter.makeLineDisplay(
                    for: row[i], font: font, style: style, cramped: cramped, maxWidth: maxWidth,
                ) {
                    columnWidths[i] = max(disp.width, columnWidths[i])
                    colDisplays.append(disp)
                } else {
                    // If display creation fails, create empty display to maintain table structure
                    let emptyDisplay = MathListDisplay(displays: [], range: 0 ..< 0)
                    colDisplays.append(emptyDisplay)
                }
            }
            displays.append(colDisplays)
        }
        return displays
    }

    func makeRowWithColumns(_ cols: [Display], forTable table: MathTable?, columnWidths: [CGFloat])
        -> MathListDisplay?
    {
        var columnStart = CGFloat(0)
        var rowRange = 0 ..< 0
        for i in 0 ..< cols.count {
            let col = cols[i]
            let colWidth = columnWidths[i]
            let alignment = table?.alignment(forColumn: i)
            var cellPos = columnStart
            switch alignment {
                case .right:
                    cellPos += colWidth - col.width
                case .center:
                    cellPos += (colWidth - col.width) / 2
                case .left, .none:
                    // No changes if left aligned
                    cellPos += 0 // no op
            }
            if !col.range.isEmpty {
                if rowRange.isEmpty {
                    rowRange = col.range
                } else {
                    let lo = min(rowRange.lowerBound, col.range.lowerBound)
                    let hi = max(rowRange.upperBound, col.range.upperBound)
                    rowRange = lo ..< hi
                }
            }

            col.position = CGPoint(x: cellPos, y: 0)
            columnStart += colWidth + table!.interColumnSpacing * styleFont.mathTable!.muUnit
        }

        if rowRange.isEmpty {
            rowRange = 0 ..< cols.count
        }

        // Create a display for the row
        return MathListDisplay(displays: cols, range: rowRange)
    }

    func positionRows(_ rows: [Display], forTable table: MathTable?) {
        // Position the rows
        // We will first position the rows starting from 0 and then in the second pass center the whole table vertically.
        var currPos = CGFloat(0)
        let openup = table!.interRowAdditionalSpacing * kJotMultiplier * styleFont.fontSize
        let baselineSkip = openup + kBaseLineSkipMultiplier * styleFont.fontSize
        let lineSkip = openup + kLineSkipMultiplier * styleFont.fontSize
        let lineSkipLimit = openup + kLineSkipLimitMultiplier * styleFont.fontSize
        var prevRowDescent = CGFloat(0)
        var ascent = CGFloat(0)
        var first = true
        for row in rows {
            if first {
                row.position = CGPoint.zero
                ascent += row.ascent
                first = false
            } else {
                var skip = baselineSkip
                if skip - (prevRowDescent + row.ascent) < lineSkipLimit {
                    // rows are too close to each other. Space them apart further
                    skip = prevRowDescent + row.ascent + lineSkip
                }
                // We are going down so we decrease the y value.
                currPos -= skip
                row.position = CGPoint(x: 0, y: currPos)
            }
            prevRowDescent = row.descent
        }

        // Vertically center the whole structure around the axis
        // The descent of the structure is the position of the last row
        // plus the descent of the last row.
        let descent = -currPos + prevRowDescent
        let shiftDown = 0.5 * (ascent - descent) - styleFont.mathTable!.axisHeight

        for row in rows {
            row.position = CGPoint(x: row.position.x, y: row.position.y - shiftDown)
        }
    }
}
