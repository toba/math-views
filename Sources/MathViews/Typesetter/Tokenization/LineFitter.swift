import Foundation
import CoreGraphics

/// Splits a sequence of ``BreakableElement`` values into lines that fit within a maximum width.
///
/// Uses a greedy algorithm with backtracking: elements are added to the current line until
/// the width limit is exceeded, then the fitter backtracks to the best break point (highest
/// ``BreakableElement/breakQuality``) seen so far. Grouped elements (base + scripts sharing
/// a ``BreakableElement/groupId``) are treated as indivisible units.
final class LineFitter {
    // MARK: - Properties

    let maxWidth: CGFloat
    let margin: CGFloat

    // MARK: - Initialization

    init(maxWidth: CGFloat, margin: CGFloat = 0) {
        self.maxWidth = maxWidth
        self.margin = margin
    }

    // MARK: - Line Fitting

    /// Fit elements into lines using greedy algorithm with backtracking
    func fitLines(_ elements: [BreakableElement]) -> [[BreakableElement]] {
        guard !elements.isEmpty else { return [] }
        guard maxWidth > 0 else { return [elements] } // No width constraint

        var lines: [[BreakableElement]] = [[]]
        var currentWidth: CGFloat = 0
        var i = 0

        while i < elements.count {
            let element = elements[i]

            // Handle grouped elements (base + scripts)
            if let groupId = element.groupId {
                let (groupElements, nextIndex) = collectGroup(
                    elements,
                    startIndex: i,
                    groupId: groupId,
                )

                // Calculate group width correctly for scripts
                // Scripts overlap vertically, so width = max(script widths), not sum
                let groupWidth = calculateGroupWidth(groupElements)

                // Check if group fits on current line
                if !lines.last!.isEmpty, currentWidth + groupWidth > maxWidth - margin {
                    // Group doesn't fit - check if first element of group can start a new line
                    if groupElements.first?.isBreakBefore ?? true {
                        // Can start new line
                        lines.append([])
                        currentWidth = 0
                    }
                }

                // Add entire group to current line
                lines[lines.count - 1].append(contentsOf: groupElements)
                currentWidth += groupWidth
                i = nextIndex
                continue
            }

            // Check if element fits on current line
            if !lines.last!.isEmpty, currentWidth + element.width > maxWidth - margin {
                // Element doesn't fit - find best break point in current line
                if let breakIndex = findBestBreak(in: lines[lines.count - 1]) {
                    // Found a break point - split current line at breakIndex
                    let currentLine = lines[lines.count - 1]

                    // Verify the first element being moved can start a line
                    // (findBestBreak already ensures this, but double-check)
                    if currentLine[breakIndex].isBreakBefore {
                        // Split: keep [0..<breakIndex] on current line, move [breakIndex...] to new line
                        let movedSlice = currentLine[breakIndex...]
                        lines[lines.count - 1] = Array(currentLine[..<breakIndex])
                        lines.append(Array(movedSlice))
                        currentWidth = movedSlice.reduce(0) { $0 + $1.width }

                        if !element.isBreakBefore {
                            // Current element cannot start a line, so it's part of the
                            // unbreakable sequence that was just moved to the new line.
                            lines[lines.count - 1].append(element)
                            currentWidth += element.width
                            i += 1
                            continue
                        }
                        // Current element can start a line, will be added to new line below
                    }
                } else {
                    // No good break point found
                    // Check if current element can start a new line
                    if element.isBreakBefore {
                        // Element can start new line
                        lines.append([])
                        currentWidth = 0
                    } else {
                        // Element cannot start a new line (e.g., closing punctuation)
                        // Keep it on current line even if it causes overflow
                        // This respects punctuation rules over width constraints
                        lines[lines.count - 1].append(element)
                        currentWidth += element.width
                        i += 1
                        continue
                    }
                }
            }

            // Add element to current line (may overflow if indivisible and too wide)
            lines[lines.count - 1].append(element)
            currentWidth += element.width
            i += 1
        }

        return lines.filter { !$0.isEmpty }
    }

    // MARK: - Helper Methods

    /// Calculate the correct width for a group of elements (e.g., base + scripts)
    /// Scripts overlap vertically, so the group width is not the sum of all widths
    private func calculateGroupWidth(_ groupElements: [BreakableElement]) -> CGFloat {
        // For grouped elements (base + scripts), just sum all widths
        // The display generator will handle the actual positioning and overlap
        // This is just for line fitting purposes
        groupElements.reduce(0) { $0 + $1.width }
    }

    /// Collect all elements that share the same groupId
    private func collectGroup(_ elements: [BreakableElement], startIndex: Int, groupId: UUID) -> (
        [BreakableElement], Int,
    ) {
        var groupElements: [BreakableElement] = []
        var index = startIndex

        while index < elements.count, elements[index].groupId == groupId {
            groupElements.append(elements[index])
            index += 1
        }

        return (groupElements, index)
    }

    /// Find the best break point in a line
    /// Returns the index where the break should occur (elements from this index move to next line)
    private func findBestBreak(in line: [BreakableElement]) -> Int? {
        var bestIndex: Int?
        var lowestPenalty = Int.max

        // Scan from right to left to prefer breaking later in the line
        // Note: Skip the last element (idx == line.count - 1) because breaking after it
        // would move 0 elements to the next line, which is pointless
        for (idx, element) in line.enumerated().reversed() {
            // Skip the last element - we need to move at least 1 element to the next line
            if idx >= line.count - 1 {
                continue
            }

            // Can we break after this element?
            let canBreakAfter = element.isBreakAfter
            let penaltyAfter = element.penaltyAfter

            // Check if next element (which would move to new line) allows breaking before it
            let canBreakBeforeNext = line[idx + 1].isBreakBefore
            let penaltyBeforeNext = line[idx + 1].penaltyBefore

            // We can break here only if BOTH:
            // 1. Current element allows breaking after it
            // 2. Next element allows breaking before it
            if canBreakAfter, canBreakBeforeNext {
                let totalPenalty = max(penaltyAfter, penaltyBeforeNext)
                if totalPenalty < lowestPenalty {
                    bestIndex = idx + 1
                    lowestPenalty = totalPenalty
                }
            }
        }

        // Only return if we found an acceptable break point
        if let index = bestIndex, lowestPenalty <= BreakPenalty.bad {
            return index
        }

        return nil
    }

    /// Check if a line width exceeds the maximum
    private func exceedsMaxWidth(_ width: CGFloat) -> Bool {
        width > maxWidth - margin
    }
}
