public import Foundation

/// Alignment for a column of MathTable
public enum ColumnAlignment {
    case left
    case center
    case right
}

/// A table or matrix environment such as `matrix`, `pmatrix`, `eqalign`, `cases`, or `split`.
///
/// Not a native TeX atom — in TeX, tables are handled by `\halign` outside the math engine.
/// MathViews brings them into the typesetting pipeline for convenience.
///
/// Cells are stored as a two-dimensional array of ``MathList`` objects. Empty lists represent
/// missing values. Column alignment defaults to center if not explicitly set.
///
/// The ``environment`` property records which LaTeX environment created this table,
/// controlling its visual style (e.g. `matrix` environments add `\textstyle` to each cell;
/// `pmatrix` wraps the table in parentheses via an ``Inner`` atom).
public final class MathTable: MathAtom {
    /// Per-column alignment (left, right, center). Defaults to center for unset columns.
    public var alignments = [ColumnAlignment]()
    /// The cells as a two-dimensional array indexed `[row][column]`.
    public var cells = [[MathList]]()
    /// The LaTeX environment name (e.g. `"matrix"`, `"eqalign"`, `"cases"`).
    public var environment = ""
    /// Horizontal spacing between columns in mu units (1 mu = 1/18 em).
    /// `matrix` environments use 18 mu (= 1 em); alignment environments use 0.
    public var interColumnSpacing: CGFloat = 0
    /// Extra vertical spacing between rows in jots (1 jot = 0.3 × font size).
    /// Zero means only the natural row height is used; `eqalign` environments use 1 jot.
    public var interRowAdditionalSpacing: CGFloat = 0

    override public var finalized: MathAtom {
        guard let table = super.finalized as? MathTable else { return super.finalized }
        for rowIndex in table.cells.indices {
            for colIndex in table.cells[rowIndex].indices {
                table.cells[rowIndex][colIndex] = table.cells[rowIndex][colIndex].finalized
            }
        }
        return table
    }

    init(environment: String?) {
        super.init()
        type = .table
        self.environment = environment ?? ""
    }

    init(_ table: MathTable) {
        super.init(table)
        type = .table
        alignments = table.alignments
        interRowAdditionalSpacing = table.interRowAdditionalSpacing
        interColumnSpacing = table.interColumnSpacing
        environment = table.environment
        var cellCopy = [[MathList]]()
        for row in table.cells {
            var newRow = [MathList]()
            for col in row {
                newRow.append(MathList(col)!)
            }
            cellCopy.append(newRow)
        }
        cells = cellCopy
    }

    override init() {
        super.init()
        type = .table
    }

    /// Set the value of a given cell. The table is automatically resized to contain this cell.
    public func setCell(_ list: MathList, row: Int, column: Int) {
        if cells.count <= row {
            for _ in cells.count ... row { cells.append([]) }
        }
        let rows = cells[row].count
        if rows <= column {
            for _ in rows ... column { cells[row].append(MathList()) }
        }
        cells[row][column] = list
    }

    /// Set the alignment of a particular column. The table is automatically resized to
    /// contain this column and any new columns added have their alignment set to center.
    public func setAlignment(_ alignment: ColumnAlignment, forColumn col: Int) {
        if alignments.count <= col {
            for _ in alignments.count ... col {
                alignments.append(ColumnAlignment.center)
            }
        }

        alignments[col] = alignment
    }

    /// Gets the alignment for a given column. If the alignment is not specified it defaults
    /// to center.
    public func alignment(forColumn col: Int) -> ColumnAlignment {
        if alignments.count <= col {
            return ColumnAlignment.center
        } else {
            return alignments[col]
        }
    }

    public var numColumns: Int {
        var numberOfCols = 0
        for row in cells {
            numberOfCols = max(numberOfCols, row.count)
        }
        return numberOfCols
    }

    public var numRows: Int { cells.count }
}
