import CoreText
import Foundation
import CoreGraphics

extension Typesetter {
    // MARK: - Glyphs

    /// Searches the font's vertical glyph variants for one whose combined ascent + descent
    /// meets or exceeds `height`. Returns the largest variant found and populates the
    /// ascent, descent, and width out-parameters.
    func findGlyph(
        _ glyph: CGGlyph,
        withHeight height: CGFloat,
        glyphAscent: inout CGFloat,
        glyphDescent: inout CGFloat,
        glyphWidth: inout CGFloat,
    ) -> CGGlyph {
        let variants = styleFont.mathTable!.verticalVariants(for: glyph)
        let numVariants = variants.count
        var glyphs = variants

        var bboxes = [CGRect](repeating: CGRect.zero, count: numVariants)
        var advances = [CGSize](repeating: CGSize.zero, count: numVariants)

        // Get the bounds for these glyphs
        CTFontGetBoundingRectsForGlyphs(
            styleFont.coreTextFont,
            .horizontal,
            &glyphs,
            &bboxes,
            numVariants,
        )
        CTFontGetAdvancesForGlyphs(
            styleFont.coreTextFont,
            .horizontal,
            &glyphs,
            &advances,
            numVariants,
        )
        var ascent = CGFloat(0)
        var descent = CGFloat(0)
        var width = CGFloat(0)
        for i in 0 ..< numVariants {
            let bounds = bboxes[i]
            width = advances[i].width
            bboxDetails(bounds, ascent: &ascent, descent: &descent)

            if ascent + descent >= height {
                glyphAscent = ascent
                glyphDescent = descent
                glyphWidth = width
                return glyphs[i]
            }
        }
        glyphAscent = ascent
        glyphDescent = descent
        glyphWidth = width
        return glyphs[numVariants - 1]
    }

    /// Assembles an extensible glyph from parts (top, middle, bottom, extenders) when no single
    /// vertical variant is tall enough. Returns `nil` if the font provides no assembly recipe.
    func constructGlyph(_ glyph: CGGlyph, height glyphHeight: CGFloat)
        -> GlyphConstructionDisplay?
    {
        let parts = styleFont.mathTable!.verticalGlyphAssembly(for: glyph)
        if parts.isEmpty {
            return nil
        }
        var glyphs = [CGGlyph]()
        var offsets = [CGFloat]()
        var height: CGFloat = 0
        constructGlyphFromParts(
            parts, glyphHeight: glyphHeight, glyphs: &glyphs, offsets: &offsets, height: &height,
        )
        var first = glyphs[0]
        let width = CTFontGetAdvancesForGlyphs(styleFont.coreTextFont, .horizontal, &first, nil, 1)
        let display = GlyphConstructionDisplay(
            glyphs: glyphs,
            offsets: offsets,
            font: styleFont,
        )
        display.width = width
        display.ascent = height
        display.descent = 0 // it's upto the rendering to adjust the display up or down.
        return display
    }

    /// Iteratively assembles glyph parts by increasing extender repetition until the
    /// combined height reaches `glyphHeight`, then distributes any remaining delta
    /// evenly across connector overlaps.
    func constructGlyphFromParts(
        _ parts: [GlyphPart],
        glyphHeight: CGFloat,
        glyphs: inout [CGGlyph],
        offsets: inout [CGFloat],
        height: inout CGFloat,
    ) {
        // Increase extender count until the glyph reaches the required height
        for numExtenders in 0 ..< 1000 {
            // Estimate capacity: non-extender parts + extender parts * numExtenders
            let estimatedCount = parts.count + parts.filter(\.isExtender).count * (numExtenders - 1)
            var accumulatedGlyphs = [CGGlyph]()
            accumulatedGlyphs.reserveCapacity(max(estimatedCount, parts.count))
            var accumulatedOffsets = [CGFloat]()
            accumulatedOffsets.reserveCapacity(max(estimatedCount, parts.count))

            var previousPart: GlyphPart?
            let minDistance = styleFont.mathTable!.minConnectorOverlap
            var minOffset = CGFloat(0)
            var maxDelta = CGFloat
                .greatestFiniteMagnitude // the maximum amount we can increase the offsets by

            for part in parts {
                var repeats = 1
                if part.isExtender {
                    repeats = numExtenders
                }
                // add the extender num extender times
                for _ in 0 ..< repeats {
                    accumulatedGlyphs.append(part.glyph)
                    if previousPart != nil {
                        let maxOverlap = min(
                            previousPart!.endConnectorLength,
                            part.startConnectorLength,
                        )
                        // the minimum amount we can add to the offset
                        let minOffsetDelta = previousPart!.fullAdvance - maxOverlap
                        // The maximum amount we can add to the offset.
                        let maxOffsetDelta = previousPart!.fullAdvance - minDistance
                        // we can increase the offsets by at most max - min.
                        maxDelta = min(maxDelta, maxOffsetDelta - minOffsetDelta)
                        minOffset = minOffset + minOffsetDelta
                    }
                    accumulatedOffsets.append(minOffset)
                    previousPart = part
                }
            }

            assert(
                accumulatedGlyphs.count == accumulatedOffsets.count,
                "Offsets should match the glyphs",
            )
            if previousPart == nil {
                continue // maybe only extenders
            }
            let minHeight = minOffset + previousPart!.fullAdvance
            let maxHeight = minHeight + maxDelta * CGFloat(accumulatedGlyphs.count - 1)
            if minHeight >= glyphHeight {
                // we are done
                glyphs = accumulatedGlyphs
                offsets = accumulatedOffsets
                height = minHeight
                return
            } else if glyphHeight <= maxHeight {
                // spread the delta equally between all the connectors
                let delta = glyphHeight - minHeight
                let deltaIncrease = delta / CGFloat(accumulatedGlyphs.count - 1)
                var lastOffset = CGFloat(0)
                for i in 0 ..< accumulatedOffsets.count {
                    let offset = accumulatedOffsets[i] + CGFloat(i) * deltaIncrease
                    accumulatedOffsets[i] = offset
                    lastOffset = offset
                }
                // we are done
                glyphs = accumulatedGlyphs
                offsets = accumulatedOffsets
                height = lastOffset + previousPart!.fullAdvance
                return
            }
        }
    }

    /// Maps a character at `index` in `str` to its `CGGlyph`, trying the fallback font
    /// if the primary font lacks a glyph. Returns 0 (`.notdef`) if neither font has it.
    func findGlyphForCharacterAtIndex(_ index: String.Index, inString str: String) -> CGGlyph {
        // Get the character at index taking into account UTF-32 characters
        var chars = Array(str[index].utf16)

        // Get the glyph from the font
        var glyph = [CGGlyph](repeating: CGGlyph.zero, count: chars.count)
        let found = CTFontGetGlyphsForCharacters(
            styleFont.coreTextFont,
            &chars,
            &glyph,
            chars.count,
        )
        if !found {
            // Try fallback font if available
            if let fallbackFont = styleFont.fallbackFont {
                let fallbackFound = CTFontGetGlyphsForCharacters(
                    fallbackFont,
                    &chars,
                    &glyph,
                    chars.count,
                )
                if fallbackFound {
                    return glyph[0]
                }
            }
            // the font did not contain a glyph for our character, so we just return 0 (notdef)
            return 0
        }
        return glyph[0]
    }

    // MARK: - Large Operators

    /// Builds a display for a large operator (∑, ∫, ∏, lim, etc.). Selects an enlarged
    /// glyph variant in display mode, centers it vertically on the math axis, and delegates
    /// to ``addLimitsToDisplay(_:forOperator:delta:)`` for limit/script positioning.
    func makeLargeOp(_ largeOperator: LargeOperator!) -> Display? {
        // Show limits above/below in display mode
        // For inline mode, we still center limits below for operators like \lim, but with tighter spacing
        let limits = largeOperator.hasLimits && (style == .display || style == .text)
        var delta = CGFloat(0)
        if largeOperator.nucleus.count == 1 {
            var glyph = findGlyphForCharacterAtIndex(
                largeOperator.nucleus.startIndex, inString: largeOperator.nucleus,
            )
            if glyph != 0 {
                // Enlarge large operators to make them visually distinctive
                if style == .display {
                    // Display style: use large variant for mathematical display mode (~2.2em)
                    glyph = styleFont.mathTable!.largerGlyph(glyph, displayStyle: true)
                } else if style == .text {
                    // Text/inline style: use moderately larger variant to ensure operator is taller than surrounding text
                    glyph = styleFont.mathTable!.largerGlyph(glyph, displayStyle: false)
                }
                // Script and scriptOfScript styles keep base size (compact rendering)
            }
            // This is be the italic correction of the character.
            delta = styleFont.mathTable!.italicCorrection(for: glyph)

            // vertically center
            let bbox = CTFontGetBoundingRectsForGlyphs(
                styleFont.coreTextFont,
                .horizontal,
                &glyph,
                nil,
                1,
            )
            let width = CTFontGetAdvancesForGlyphs(
                styleFont.coreTextFont,
                .horizontal,
                &glyph,
                nil,
                1,
            )
            var ascent = CGFloat(0)
            var descent = CGFloat(0)
            bboxDetails(bbox, ascent: &ascent, descent: &descent)
            let shiftDown = 0.5 * (ascent - descent) - styleFont.mathTable!.axisHeight
            let glyphDisplay = GlyphDisplay(
                glyph: glyph, range: largeOperator.indexRange, font: styleFont,
            )
            glyphDisplay.ascent = ascent
            glyphDisplay.descent = descent
            glyphDisplay.width = width
            if largeOperator.subScript != nil, !limits {
                // Remove italic correction from the width of the glyph if
                // there is a subscript and limits is not set.
                glyphDisplay.width -= delta
            }
            glyphDisplay.shiftDown = shiftDown
            glyphDisplay.position = currentPosition
            return addLimitsToDisplay(glyphDisplay, forOperator: largeOperator, delta: delta)
        } else {
            // Create a regular node
            let line = NSMutableAttributedString(string: largeOperator.nucleus)
            // add the font
            line.addAttribute(
                kCTFontAttributeName as NSAttributedString.Key, value: styleFont.coreTextFont,
                range: NSRange(location: 0, length: line.length),
            )
            let displayAtom = CTLineDisplay(
                attributedString: line, position: currentPosition, range: largeOperator.indexRange,
                font: styleFont,
                atoms: [largeOperator],
            )
            return addLimitsToDisplay(displayAtom, forOperator: largeOperator, delta: 0)
        }
    }

    /// Positions limits above/below the operator nucleus (display mode) or as side scripts
    /// (text mode). `delta` is the italic correction used to shift the superscript rightward.
    func addLimitsToDisplay(_ display: Display?, forOperator op: LargeOperator, delta: CGFloat)
        -> Display?
    {
        // If there is no subscript or superscript, just return the current display
        if op.subScript == nil, op.superScript == nil {
            currentPosition.x += display!.width
            return display
        }
        // Show limits above/below in both display and text (inline) modes
        if op.hasLimits, style == .display || style == .text {
            // make limits (above/below positioning)
            var superScript: MathListDisplay?
            var subScript: MathListDisplay?

            // Scale font for script style before creating scripts
            // This matches how DisplayPreRenderer.renderScript() handles script sizing
            let scriptStyle = scriptStyle()
            let scriptFontSize = Typesetter.styleSize(scriptStyle, font: font)
            let scriptFont = font.withSize(scriptFontSize)

            if op.superScript != nil {
                superScript = Typesetter.makeLineDisplay(
                    for: op.superScript, font: scriptFont, style: scriptStyle,
                    cramped: superScriptCramped(),
                )
            }
            if op.subScript != nil {
                subScript = Typesetter.makeLineDisplay(
                    for: op.subScript, font: scriptFont, style: scriptStyle,
                    cramped: subscriptCramped(),
                )
            }
            assert(
                (superScript != nil) || (subScript != nil),
                "At least one of superscript or subscript should have been present.",
            )
            let opsDisplay = LargeOpLimitsDisplay(
                nucleus: display, upperLimit: superScript, lowerLimit: subScript,
                limitShift: delta / 2,
                extraPadding: 0,
            )

            // Use standard OpenType MATH metrics for limit spacing
            if superScript != nil {
                let upperLimitGap = max(
                    styleFont.mathTable!.upperLimitGapMin,
                    styleFont.mathTable!.upperLimitBaselineRiseMin - superScript!.descent,
                )
                opsDisplay.upperLimitGap = upperLimitGap
            }
            if subScript != nil {
                let lowerLimitGap = max(
                    styleFont.mathTable!.lowerLimitGapMin,
                    styleFont.mathTable!.lowerLimitBaselineDropMin - subScript!.ascent,
                )
                opsDisplay.lowerLimitGap = lowerLimitGap
            }
            opsDisplay.position = currentPosition
            opsDisplay.range = op.indexRange
            currentPosition.x += opsDisplay.width
            return opsDisplay
        } else {
            currentPosition.x += display!.width
            makeScripts(
                op, display: display, index: safeUIntFromLocation(op.indexRange.lowerBound),
                delta: delta,
            )
            return display
        }
    }

    // MARK: - Large delimiters

    /// TeX's delimiter factor (901/1000 ≈ 90%) — the delimiter must cover at least this
    /// fraction of the enclosed formula's height.
    static let kDelimiterFactor = CGFloat(901)
    /// TeX's delimiter shortfall (5pt) — the delimiter may be at most this much shorter
    /// than the enclosed formula.
    static let kDelimiterShortfallPoints = CGFloat(5)

    /// Builds a delimited expression (`\left...\right`), sizing the delimiter glyphs to
    /// match the inner content height or an explicit multiplier (from `\big`, `\Big`, etc.).
    func makeLeftRight(_ inner: Inner?, maxWidth: CGFloat = 0) -> Display? {
        assert(
            inner!.leftBoundary != nil || inner!.rightBoundary != nil,
            "Inner should have a boundary to call this function",
        )

        let glyphHeight: CGFloat

        // Check if we have an explicit delimiter height (from \big, \Big, etc.)
        if let delimiterMultiplier = inner!.delimiterHeight {
            // delimiterHeight is a multiplier (e.g., 1.2, 1.8, 2.4, 3.0)
            // Multiply by font size to get actual height
            glyphHeight = styleFont.fontSize * delimiterMultiplier
        } else {
            // Calculate height based on inner content (for \left...\right)
            let innerListDisplay = Typesetter.makeLineDisplay(
                for: inner!.innerList, font: font, style: style, cramped: cramped, spaced: true,
                maxWidth: maxWidth,
            )
            let axisHeight = styleFont.mathTable!.axisHeight
            // delta is the max distance from the axis
            let delta = max(
                innerListDisplay!.ascent - axisHeight,
                innerListDisplay!.descent + axisHeight,
            )
            let axisDistance =
                (delta / 500)
                    * Typesetter
                    .kDelimiterFactor // This represents atleast 90% of the formula
            let paddingDistance =
                2 * delta
                    - Typesetter
                    .kDelimiterShortfallPoints // This represents a shortfall of 5pt
            // The size of the delimiter glyph should cover at least 90% of the formula or
            // be at most 5pt short.
            glyphHeight = max(axisDistance, paddingDistance)
        }

        var innerElements = [Display]()
        var position = CGPoint.zero

        // Add horizontal padding between delimiters and content
        // Use 2 mu (about 1/9 em) for breathing room, matching TeX standards
        let delimiterPadding = styleFont.mathTable!.muUnit * 2

        if inner!.leftBoundary != nil, !inner!.leftBoundary!.nucleus.isEmpty {
            let leftGlyph = findGlyphForBoundary(
                inner!.leftBoundary!.nucleus, withHeight: glyphHeight,
            )
            leftGlyph!.position = position
            position.x += leftGlyph!.width
            innerElements.append(leftGlyph!)
            // Add padding after left delimiter
            position.x += delimiterPadding
        }

        // Only include inner content if not using explicit delimiter height
        // (explicit height commands like \big produce standalone delimiters)
        if inner!.delimiterHeight == nil {
            let innerListDisplay = Typesetter.makeLineDisplay(
                for: inner!.innerList, font: font, style: style, cramped: cramped, spaced: true,
                maxWidth: maxWidth,
            )
            innerListDisplay!.position = position
            position.x += innerListDisplay!.width
            innerElements.append(innerListDisplay!)
        }

        if inner!.rightBoundary != nil, !inner!.rightBoundary!.nucleus.isEmpty {
            // Add padding before right delimiter
            position.x += delimiterPadding
            let rightGlyph = findGlyphForBoundary(
                inner!.rightBoundary!.nucleus, withHeight: glyphHeight,
            )
            rightGlyph!.position = position
            position.x += rightGlyph!.width
            innerElements.append(rightGlyph!)
        }
        return MathListDisplay(displays: innerElements, range: inner!.indexRange)
    }

    /// Finds or constructs a delimiter glyph at the required height, then centers it
    /// vertically on the math axis. Falls back to extensible glyph construction if no
    /// single pre-built variant is tall enough.
    func findGlyphForBoundary(_ delimiter: String, withHeight glyphHeight: CGFloat) -> Display? {
        var glyphAscent = CGFloat(0)
        var glyphDescent = CGFloat(0)
        var glyphWidth = CGFloat(0)
        let leftGlyph = findGlyphForCharacterAtIndex(delimiter.startIndex, inString: delimiter)
        let glyph = findGlyph(
            leftGlyph, withHeight: glyphHeight, glyphAscent: &glyphAscent,
            glyphDescent: &glyphDescent,
            glyphWidth: &glyphWidth,
        )

        var glyphDisplay: ShiftableDisplay?
        if glyphAscent + glyphDescent < glyphHeight {
            // we didn't find a pre-built glyph that is large enough
            glyphDisplay = constructGlyph(leftGlyph, height: glyphHeight)
        }

        if glyphDisplay == nil {
            // Create a glyph display
            glyphDisplay = GlyphDisplay(glyph: glyph, range: 0 ..< 0, font: styleFont)
            glyphDisplay!.ascent = glyphAscent
            glyphDisplay!.descent = glyphDescent
            glyphDisplay!.width = glyphWidth
        }
        // Center the glyph on the axis
        let shiftDown =
            0.5 * (glyphDisplay!.ascent - glyphDisplay!.descent) - styleFont.mathTable!.axisHeight
        glyphDisplay!.shiftDown = shiftDown
        return glyphDisplay
    }
}
