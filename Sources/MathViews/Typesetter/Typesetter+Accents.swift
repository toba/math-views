import CoreGraphics
import CoreText
import Foundation

extension Typesetter {
  // MARK: - Underline/Overline

  /// Builds an underline display by typesetting the inner content and drawing a horizontal
  /// rule below it, spaced according to OpenType MATH underbar metrics.
  func makeUnderline(_ under: Underline?) -> Display? {
    let innerListDisplay = Typesetter.makeLineDisplay(
      for: under!.innerList, font: font, style: style, cramped: cramped,
    )
    let underDisplay = LineDisplay(
      inner: innerListDisplay, position: currentPosition, range: under!.indexRange,
    )
    // Move the line down by the vertical gap.
    underDisplay.lineShiftUp =
      -(innerListDisplay!.descent + styleFont.mathTable!.underbarVerticalGap)
    underDisplay.lineThickness = styleFont.mathTable!.underbarRuleThickness
    underDisplay.ascent = innerListDisplay!.ascent
    underDisplay.descent =
      innerListDisplay!.descent + styleFont.mathTable!.underbarVerticalGap
      + styleFont.mathTable!.underbarRuleThickness
      + styleFont.mathTable!
      .underbarExtraDescender
    underDisplay.width = innerListDisplay!.width
    return underDisplay
  }

  /// Builds an overline display by typesetting the inner content (cramped) and drawing a
  /// horizontal rule above it, spaced according to OpenType MATH overbar metrics.
  func makeOverline(_ over: Overline?) -> Display? {
    let innerListDisplay = Typesetter.makeLineDisplay(
      for: over!.innerList, font: font, style: style, cramped: true,
    )
    let overDisplay = LineDisplay(
      inner: innerListDisplay, position: currentPosition, range: over!.indexRange,
    )
    overDisplay.lineShiftUp = innerListDisplay!.ascent + styleFont.mathTable!.overbarVerticalGap
    overDisplay.lineThickness = styleFont.mathTable!.overbarRuleThickness
    overDisplay.ascent =
      innerListDisplay!.ascent + styleFont.mathTable!.overbarVerticalGap
      + styleFont.mathTable!.overbarRuleThickness
      + styleFont.mathTable!
      .overbarExtraAscender
    overDisplay.descent = innerListDisplay!.descent
    overDisplay.width = innerListDisplay!.width
    return overDisplay
  }

  // MARK: - Overbrace/Underbrace

  /// Builds an overbrace display: content on the bottom, a stretchy ⏞ brace above,
  /// and an optional superscript annotation above the brace.
  func makeOverBrace(_ atom: OverBrace) -> Display? {
    let innerDisplay = Typesetter.makeLineDisplay(
      for: atom.innerList, font: font, style: style, cramped: true,
    )
    guard let innerDisplay else { return nil }

    let braceGlyph = makeBraceGlyph(
      unicode: "\u{23DE}", width: innerDisplay.width, range: atom.indexRange,
    )

    // Annotation above the brace (from superscript)
    var annotation: MathListDisplay?
    if let superScript = atom.superScript {
      annotation = Typesetter.makeLineDisplay(
        for: superScript, font: font, style: scriptStyle(), cramped: false,
      )
      // Clear super so makeScripts doesn't double-process
      atom.superScript = nil
    }

    guard let mathTable = styleFont.mathTable else { return nil }
    let gap = mathTable.overbarVerticalGap

    // Use LargeOpLimitsDisplay: nucleus = inner content + brace, upper limit = annotation
    // Build a container for content + brace
    let braceDisplay = braceGlyph
    braceDisplay.position = CGPoint(x: 0, y: innerDisplay.ascent + gap)

    let container = MathListDisplay(
      displays: [innerDisplay, braceDisplay], range: atom.indexRange,
    )
    container.ascent = innerDisplay.ascent + gap + braceGlyph.ascent + braceGlyph.descent
    container.descent = innerDisplay.descent
    container.width = innerDisplay.width

    let limitsDisplay = LargeOpLimitsDisplay(
      nucleus: container,
      upperLimit: annotation,
      lowerLimit: nil,
      limitShift: 0,
      extraPadding: 0,
    )
    limitsDisplay.upperLimitGap = gap
    limitsDisplay.position = currentPosition

    // Handle remaining subscript normally
    if atom.subScript != nil {
      // We need to process subscript via makeScripts after returning
    }

    return limitsDisplay
  }

  /// Builds an underbrace display: content on top, a stretchy ⏟ brace below,
  /// and an optional subscript annotation below the brace.
  func makeUnderBrace(_ atom: UnderBrace) -> Display? {
    let innerDisplay = Typesetter.makeLineDisplay(
      for: atom.innerList, font: font, style: style, cramped: cramped,
    )
    guard let innerDisplay else { return nil }

    let braceGlyph = makeBraceGlyph(
      unicode: "\u{23DF}", width: innerDisplay.width, range: atom.indexRange,
    )

    // Annotation below the brace (from subscript)
    var annotation: MathListDisplay?
    if let subScript = atom.subScript {
      annotation = Typesetter.makeLineDisplay(
        for: subScript, font: font, style: scriptStyle(), cramped: true,
      )
      // Clear sub so makeScripts doesn't double-process
      atom.subScript = nil
    }

    guard let mathTable = styleFont.mathTable else { return nil }
    let gap = mathTable.underbarVerticalGap

    // Build container: content on top, brace below
    let braceDisplay = braceGlyph
    braceDisplay.position = CGPoint(
      x: 0, y: -(innerDisplay.descent + gap + braceGlyph.ascent),
    )

    let container = MathListDisplay(
      displays: [innerDisplay, braceDisplay], range: atom.indexRange,
    )
    container.ascent = innerDisplay.ascent
    container.descent = innerDisplay.descent + gap + braceGlyph.ascent + braceGlyph.descent
    container.width = innerDisplay.width

    let limitsDisplay = LargeOpLimitsDisplay(
      nucleus: container,
      upperLimit: nil,
      lowerLimit: annotation,
      limitShift: 0,
      extraPadding: 0,
    )
    limitsDisplay.lowerLimitGap = gap
    limitsDisplay.position = currentPosition

    return limitsDisplay
  }

  /// Creates a horizontally-scaled brace glyph (⏞ or ⏟) sized to the given width.
  private func makeBraceGlyph(unicode: String, width targetWidth: CGFloat, range: Range<Int>)
    -> GlyphDisplay
  {
    let end = unicode.index(before: unicode.endIndex)
    var glyph = findGlyphForCharacterAtIndex(end, inString: unicode)

    // Try to find a horizontal variant that fits
    var glyphAscent: CGFloat = 0
    var glyphDescent: CGFloat = 0
    var glyphWidth: CGFloat = 0
    var glyphMinY: CGFloat = 0

    glyph = findVariantGlyph(
      glyph, withMaxWidth: targetWidth, maxWidth: &glyphAscent,
      glyphDescent: &glyphDescent, glyphWidth: &glyphWidth, glyphMinY: &glyphMinY,
    )

    let display = GlyphDisplay(glyph: glyph, range: range, font: styleFont)
    display.ascent = glyphAscent
    display.descent = glyphDescent

    // Scale horizontally if the largest variant is still smaller than content
    if glyphWidth < targetWidth, glyphWidth > 0 {
      let scaleX = targetWidth / glyphWidth
      display.scaleX = scaleX
      display.width = targetWidth
    } else {
      display.width = glyphWidth
    }

    return display
  }

  // MARK: - Accents

  /// Returns `true` if the accent applies to a single character without scripts,
  /// which enables skew calculation via top accent attachment points.
  func isSingleCharAccentee(_ accent: Accent?) -> Bool {
    guard let accent else { return false }
    if accent.innerList!.atoms.count != 1 {
      // Not a single char list.
      return false
    }
    let innerAtom = accent.innerList!.atoms[0]
    if innerAtom.nucleus.count != 1 {
      // A complex atom, not a simple char.
      return false
    }
    if innerAtom.subScript != nil || innerAtom.superScript != nil {
      return false
    }
    return true
  }

  /// Calculates the horizontal offset (skew) for an accent glyph using the OpenType MATH
  /// top accent attachment points of both the accent and the accentee.
  func skew(for accent: Accent?, accenteeWidth width: CGFloat, accentGlyph: CGGlyph) -> CGFloat {
    guard let accent else { return 0 }
    if accent.nucleus.isEmpty {
      // No accent
      return 0
    }
    let accentAdjustment = styleFont.mathTable!.topAccentAdjustment(for: accentGlyph)
    var accenteeAdjustment = CGFloat(0)
    if !isSingleCharAccentee(accent) {
      // use the center of the accentee
      accenteeAdjustment = width / 2
    } else {
      let innerAtom = accent.innerList!.atoms[0]
      let accenteeGlyph = findGlyphForCharacterAtIndex(
        innerAtom.nucleus.index(innerAtom.nucleus.endIndex, offsetBy: -1),
        inString: innerAtom.nucleus,
      )
      accenteeAdjustment = styleFont.mathTable!.topAccentAdjustment(for: accenteeGlyph)
    }
    // The adjustments need to aligned, so skew is just the difference.
    return accenteeAdjustment - accentAdjustment
  }

  /// Finds the largest horizontal glyph variant whose width does not exceed `maxWidth`.
  /// Populates the ascent, descent, width, and minY out-parameters for the chosen variant.
  func findVariantGlyph(
    _ glyph: CGGlyph,
    withMaxWidth maxWidth: CGFloat,
    maxWidth glyphAscent: inout CGFloat,
    glyphDescent: inout CGFloat,
    glyphWidth: inout CGFloat,
    glyphMinY: inout CGFloat,
  ) -> CGGlyph {
    let variants = styleFont.mathTable!.horizontalVariants(for: glyph)
    let numVariants = variants.count
    assert(
      numVariants > 0,
      "A glyph is always it's own variant, so number of variants should be > 0",
    )
    var glyphs = variants

    var currentGlyph = glyphs[0]  // if no other glyph is found, we'll return the first one.
    var bboxes = [CGRect](repeating: CGRect.zero, count: numVariants)  // [numVariants)
    var advances = [CGSize](repeating: CGSize.zero, count: numVariants)
    // Get the bounds for these glyphs
    CTFontGetBoundingRectsForGlyphs(
      styleFont.coreTextFont,
      .horizontal,
      &glyphs,
      &bboxes,
      numVariants,
    )
    CTFontGetAdvancesForGlyphs(styleFont.coreTextFont, .horizontal, &glyphs, &advances, numVariants)
    for i in 0..<numVariants {
      let bounds = bboxes[i]
      var ascent = CGFloat(0)
      var descent = CGFloat(0)
      let width = bounds.maxX
      bboxDetails(bounds, ascent: &ascent, descent: &descent)

      if width > maxWidth {
        if i == 0 {
          // glyph dimensions are not yet set
          glyphWidth = advances[i].width
          glyphAscent = ascent
          glyphDescent = descent
          glyphMinY = bounds.minY
        }
        return currentGlyph
      } else {
        currentGlyph = glyphs[i]
        glyphWidth = advances[i].width
        glyphAscent = ascent
        glyphDescent = descent
        glyphMinY = bounds.minY
      }
    }
    // We exhausted all the variants and none was larger than the width, so we return the largest
    return currentGlyph
  }

  /// Gets the proper glyph name for arrow accents that have stretchy variants in the font.
  /// Returns different glyphs based on the LaTeX command used:
  /// - \vec: use combining character glyph (uni20D7) for small fixed-size arrow
  /// - \overrightarrow: use non-combining arrow (arrowright) which can be stretched
  func arrowAccentGlyphName(for accent: Accent) -> String? {
    // Check if this is a stretchy arrow accent (set by the factory based on LaTeX command)
    let useStretchy = accent.isStretchy

    // Map Unicode combining characters to appropriate glyph names
    switch accent.nucleus {
    case "\u{20D6}":  // Combining left arrow above
      return useStretchy ? "arrowleft" : "uni20D6"
    case "\u{20D7}":  // Combining right arrow above (\vec or \overrightarrow)
      return useStretchy ? "arrowright" : "uni20D7"
    case "\u{20E1}":  // Combining left right arrow above
      return useStretchy ? "arrowboth" : "uni20E1"
    default:
      return nil
    }
  }

  /// Gets the proper glyph name for wide accents that should stretch to cover content.
  /// Returns different glyphs based on the LaTeX command used:
  /// - \hat: use combining character for fixed-size accent
  /// - \widehat: use non-combining circumflex which can be stretched
  func wideAccentGlyphName(for accent: Accent) -> String? {
    // Only apply to wide accents (set by factory based on LaTeX command)
    guard accent.isWide else { return nil }

    // Map Unicode combining characters to non-combining glyph names with stretchy variants
    switch accent.nucleus {
    case "\u{0302}":  // COMBINING CIRCUMFLEX ACCENT (\hat or \widehat)
      return "circumflex"
    case "\u{0303}":  // COMBINING TILDE (\tilde or \widetilde)
      return "tilde"
    case "\u{030C}":  // COMBINING CARON (\check or \widecheck)
      return "caron"
    default:
      return nil
    }
  }

  /// Counts the approximate character length of the content under a wide accent.
  /// This is used to select the appropriate glyph variant.
  func wideAccentContentLength(for accent: Accent) -> Int {
    guard let innerList = accent.innerList else { return 0 }

    var charCount = 0
    for atom in innerList.atoms {
      switch atom.type {
      case .variable, .number:
        // Count actual characters
        charCount += atom.nucleus.count
      case .ordinary, .binaryOperator, .relation:
        // Count as single character
        charCount += 1
      case .fraction:
        // Fractions count as 2 units
        charCount += 2
      case .radical:
        // Radicals count as 2 units
        charCount += 2
      case .largeOperator:
        // Large operators count as 2 units
        charCount += 2
      default:
        // Other types count as 1 unit
        charCount += 1
      }
    }
    return charCount
  }

  /// Determines which glyph variant to use for a wide accent based on content length.
  /// Returns a multiplier for the requested width (1.0, 1.5, 2.0, or 2.5)
  /// Selects variants based on character count to ensure proper coverage.
  func wideAccentVariantMultiplier(for accent: Accent) -> CGFloat {
    let charCount = wideAccentContentLength(for: accent)

    // Map character count to variant width request multiplier
    // This helps select larger glyph variants from the font's MATH table
    // 1-2 chars: request 1.0x (smallest variant)
    // 3-4 chars: request 1.5x (medium variant)
    // 5-6 chars: request 2.0x (large variant)
    // 7+ chars: request 2.5x (largest variant)
    if charCount <= 2 {
      return 1.0
    } else if charCount <= 4 {
      return 1.5
    } else if charCount <= 6 {
      return 2.0
    } else {
      return 2.5
    }
  }

  /// Builds an accent display by selecting the appropriate glyph (regular, arrow, or wide),
  /// positioning it above the accentee, and optionally scaling it horizontally to cover
  /// the content width. Handles three accent categories with different spacing rules.
  func makeAccent(_ accent: Accent?) -> Display? {
    guard let accent else { return nil }

    let accentee = Typesetter.makeLineDisplay(
      for: accent.innerList, font: font, style: style, cramped: true,
    )
    if accent.nucleus.isEmpty {
      // no accent!
      return accentee
    }

    // If accentee is nil (empty content), create an empty display
    guard let accentee else {
      // Return an empty display for empty content
      let emptyDisplay = MathListDisplay(displays: [], range: accent.indexRange)
      emptyDisplay.position = currentPosition
      return emptyDisplay
    }

    var accentGlyph: CGGlyph
    let isArrowAccent = arrowAccentGlyphName(for: accent) != nil
    let isWideAccent = wideAccentGlyphName(for: accent) != nil

    // Check for special accent types that need non-combining glyphs
    if let wideGlyphName = wideAccentGlyphName(for: accent) {
      // For wide accents, use non-combining glyphs (e.g., "circumflex", "tilde")
      // These have horizontal variants that can stretch
      accentGlyph = styleFont.glyph(named: wideGlyphName)
    } else if let arrowGlyphName = arrowAccentGlyphName(for: accent) {
      // For arrow accents, use non-combining arrow glyphs (e.g., "arrowright")
      // These have larger horizontal variants than the combining versions
      accentGlyph = styleFont.glyph(named: arrowGlyphName)
    } else {
      // For regular accents, use Unicode character lookup
      let end = accent.nucleus.index(before: accent.nucleus.endIndex)
      accentGlyph = findGlyphForCharacterAtIndex(end, inString: accent.nucleus)
    }

    let accenteeWidth = accentee.width
    var glyphAscent = CGFloat(0)
    var glyphDescent = CGFloat(0)
    var glyphWidth = CGFloat(0)
    var glyphMinY = CGFloat(0)

    // Adjust requested width based on accent type:
    // - Wide accents (\widehat): request width based on content length (variant selection)
    // - Arrow accents (\overrightarrow): request extra width for stretching
    // - Regular accents: request exact content width
    let requestedWidth: CGFloat
    if isWideAccent {
      // For wide accents, request width based on content length to select appropriate variant
      let multiplier = wideAccentVariantMultiplier(for: accent)
      requestedWidth = accenteeWidth * multiplier
    } else if isArrowAccent {
      if accent.isStretchy {
        requestedWidth = accenteeWidth * 1.1  // Request extra width for stretching
      } else {
        requestedWidth = 1.0  // Get smallest non-zero variant (typically .h1)
      }
    } else {
      requestedWidth = accenteeWidth
    }

    accentGlyph = findVariantGlyph(
      accentGlyph, withMaxWidth: requestedWidth, maxWidth: &glyphAscent,
      glyphDescent: &glyphDescent, glyphWidth: &glyphWidth, glyphMinY: &glyphMinY,
    )

    // For non-stretchy arrow accents (\vec): if we got a zero-width glyph (base combining char),
    // manually select the first variant which is the proper accent size
    if isArrowAccent, !accent.isStretchy, glyphWidth == 0 {
      guard let mathTable = styleFont.mathTable else { return nil }
      let variants = mathTable.horizontalVariants(for: accentGlyph)
      if variants.count > 1 {
        // Use the first variant (.h1) which has proper width
        accentGlyph = variants[1]
        var glyph = accentGlyph
        var advances = CGSize.zero
        CTFontGetAdvancesForGlyphs(styleFont.coreTextFont, .horizontal, &glyph, &advances, 1)
        glyphWidth = advances.width
        // Recalculate ascent and descent for the variant glyph
        var boundingRects = CGRect.zero
        CTFontGetBoundingRectsForGlyphs(
          styleFont.coreTextFont,
          .horizontal,
          &glyph,
          &boundingRects,
          1,
        )
        glyphMinY = boundingRects.minY
        glyphAscent = boundingRects.maxY
        glyphDescent = -boundingRects.minY
      }
    }

    // Special accents (arrows and wide accents) need more vertical space and different positioning
    let delta: CGFloat
    let height: CGFloat
    let skew: CGFloat

    if isWideAccent {
      // Wide accents (\widehat, \widetilde): use same vertical spacing as stretchy arrows
      delta = 0  // No compression for wide accents
      guard let mathTable = styleFont.mathTable else { return nil }
      let wideAccentSpacing = mathTable.upperLimitGapMin  // Same as stretchy arrows
      // Compensate for internal glyph whitespace (minY > 0)
      let minYCompensation = max(0, glyphMinY)
      height = accentee.ascent + wideAccentSpacing - minYCompensation

      // For wide accents: if the largest glyph variant is still smaller than content width,
      // scale it horizontally to fully cover the content
      if glyphWidth < accenteeWidth {
        // Add padding to make accent extend slightly beyond content
        // Use ~0.1em padding (less than arrows which use ~0.167em)
        let widePadding = styleFont.fontSize / 10  // Approximately 0.1em
        let targetWidth = accenteeWidth + widePadding

        let scaleX = targetWidth / glyphWidth
        let accentGlyphDisplay = GlyphDisplay(
          glyph: accentGlyph, range: accent.indexRange, font: styleFont,
        )
        accentGlyphDisplay.scaleX = scaleX  // Apply horizontal scaling
        accentGlyphDisplay.ascent = glyphAscent
        accentGlyphDisplay.descent = glyphDescent
        accentGlyphDisplay.width = targetWidth  // Set width to include padding
        accentGlyphDisplay.position = CGPoint(x: 0, y: height)  // Align to left edge

        var finalAccentee = accentee
        if isSingleCharAccentee(accent),
          accent.subScript != nil || accent.superScript != nil
        {
          // Attach the super/subscripts to the accentee instead of the accent.
          guard let innerList = accent.innerList,
            !innerList.atoms.isEmpty
          else { return nil }
          let innerAtom = innerList.atoms[0]
          innerAtom.superScript = accent.superScript
          innerAtom.subScript = accent.subScript
          accent.superScript = nil
          accent.subScript = nil
          if let remadeAccentee = Typesetter.makeLineDisplay(
            for: accent.innerList, font: font, style: style, cramped: cramped,
          ) {
            finalAccentee = remadeAccentee
          }
        }

        let display = AccentDisplay(
          accent: accentGlyphDisplay, accentee: finalAccentee,
          range: accent.indexRange,
        )
        display.width = finalAccentee.width
        display.descent = finalAccentee.descent
        let ascent = height + glyphAscent
        display.ascent = max(finalAccentee.ascent, ascent)
        display.position = currentPosition
        return display
      } else {
        // Wide accent glyph is wide enough: center it over the content
        skew = (accenteeWidth - glyphWidth) / 2
      }
    } else if isArrowAccent {
      // Arrow accents spacing depends on whether they're stretchy or not
      guard let mathTable = styleFont.mathTable else { return nil }
      if accent.isStretchy {
        // Stretchy arrows (\overrightarrow): use full ascent + additional spacing
        delta = 0  // No compression for stretchy arrows
        let arrowSpacing = mathTable.upperLimitGapMin  // Use standard gap
        // Compensate for internal glyph whitespace (minY > 0)
        let minYCompensation = max(0, glyphMinY)
        height = accentee.ascent + arrowSpacing - minYCompensation
      } else {
        // Non-stretchy arrows (\vec): use tight spacing like regular accents
        // This gives a more compact appearance suitable for single-character vectors
        delta = min(accentee.ascent, mathTable.accentBaseHeight)
        // Use same formula as regular accents (no minYCompensation adjustment)
        // This places the arrow properly above the character
        height = accentee.ascent - delta
      }

      // For stretchy arrow accents (\overrightarrow): if the largest glyph variant is still smaller than content width,
      // scale it horizontally to fully cover the content
      // Add small padding to make arrow tip extend slightly beyond content
      // For non-stretchy accents (\vec): always center without scaling
      if accent.isStretchy, glyphWidth < accenteeWidth {
        // Add padding to make arrow extend beyond content on the tip side
        // Use approximately 0.15-0.2em extra width
        let arrowPadding =
          styleFont
          .fontSize / 6  // Approximately 0.167em at typical font sizes
        let targetWidth = accenteeWidth + arrowPadding

        let scaleX = targetWidth / glyphWidth
        let accentGlyphDisplay = GlyphDisplay(
          glyph: accentGlyph, range: accent.indexRange, font: styleFont,
        )
        accentGlyphDisplay.scaleX = scaleX  // Apply horizontal scaling
        accentGlyphDisplay.ascent = glyphAscent
        accentGlyphDisplay.descent = glyphDescent
        accentGlyphDisplay.width = targetWidth  // Set width to include padding
        accentGlyphDisplay.position = CGPoint(x: 0, y: height)  // Align to left edge

        var finalAccentee = accentee
        if isSingleCharAccentee(accent),
          accent.subScript != nil || accent.superScript != nil
        {
          // Attach the super/subscripts to the accentee instead of the accent.
          guard let innerList = accent.innerList,
            !innerList.atoms.isEmpty
          else { return nil }
          let innerAtom = innerList.atoms[0]
          innerAtom.superScript = accent.superScript
          innerAtom.subScript = accent.subScript
          accent.superScript = nil
          accent.subScript = nil
          if let remadeAccentee = Typesetter.makeLineDisplay(
            for: accent.innerList, font: font, style: style, cramped: cramped,
          ) {
            finalAccentee = remadeAccentee
          }
        }

        let display = AccentDisplay(
          accent: accentGlyphDisplay, accentee: finalAccentee,
          range: accent.indexRange,
        )
        display.width = finalAccentee.width
        display.descent = finalAccentee.descent
        let ascent = height + glyphAscent
        display.ascent = max(finalAccentee.ascent, ascent)
        display.position = currentPosition
        return display
      } else {
        // Arrow glyph is wide enough or is non-stretchy (\vec): center it over the content
        skew = (accenteeWidth - glyphWidth) / 2
      }
    } else {
      // For regular accents: use traditional tight positioning
      guard let mathTable = styleFont.mathTable else { return nil }
      delta = min(accentee.ascent, mathTable.accentBaseHeight)
      skew = self.skew(for: accent, accenteeWidth: accenteeWidth, accentGlyph: accentGlyph)
      height = accentee.ascent - delta  // This is always positive since delta <= height.
    }

    let accentPosition = CGPoint(x: skew, y: height)
    let accentGlyphDisplay = GlyphDisplay(
      glyph: accentGlyph, range: accent.indexRange, font: styleFont,
    )
    accentGlyphDisplay.ascent = glyphAscent
    accentGlyphDisplay.descent = glyphDescent
    accentGlyphDisplay.width = glyphWidth
    accentGlyphDisplay.position = accentPosition

    var finalAccentee = accentee
    if isSingleCharAccentee(accent), accent.subScript != nil || accent.superScript != nil {
      // Attach the super/subscripts to the accentee instead of the accent.
      guard let innerList = accent.innerList,
        !innerList.atoms.isEmpty
      else { return nil }
      let innerAtom = innerList.atoms[0]
      innerAtom.superScript = accent.superScript
      innerAtom.subScript = accent.subScript
      accent.superScript = nil
      accent.subScript = nil
      // Remake the accentee (now with sub/superscripts)
      // Note: Latex adjusts the heights in case the height of the char is different in non-cramped mode. However this shouldn't be the case since cramping
      // only affects fractions and superscripts. We skip adjusting the heights.
      if let remadeAccentee = Typesetter.makeLineDisplay(
        for: accent.innerList, font: font, style: style, cramped: cramped,
      ) {
        finalAccentee = remadeAccentee
      }
    }

    let display = AccentDisplay(
      accent: accentGlyphDisplay, accentee: finalAccentee, range: accent.indexRange,
    )
    display.width = finalAccentee.width
    display.descent = finalAccentee.descent

    // Calculate total ascent based on positioning
    // For arrows: height already includes spacing, so ascent = height + glyphAscent
    // For regular accents: ascent = accentee.ascent - delta + glyphAscent (existing formula)
    let ascent = height + glyphAscent
    display.ascent = max(finalAccentee.ascent, ascent)
    display.position = currentPosition

    return display
  }

  /// Determines if an accent can use Unicode composition for inline rendering.
  /// Unicode combining characters only work correctly for single base characters.
  /// Multi-character expressions and arrow accents need font-based rendering.
  func canUseUnicodeComposition(_ accent: Accent) -> Bool {
    // Check if innerList has exactly one simple character
    guard let innerList = accent.innerList,
      innerList.atoms.count == 1,
      let firstAtom = innerList.atoms.first
    else {
      return false
    }

    // Only allow simple variable/number atoms
    guard firstAtom.type == .variable || firstAtom.type == .number else {
      return false
    }

    // Check that the atom doesn't have subscripts/superscripts
    guard firstAtom.subScript == nil, firstAtom.superScript == nil else {
      return false
    }

    // Exclude arrow accents - they need stretching from font glyphs
    // These Unicode combining characters only apply to single preceding characters
    let arrowAccents: Set<String> = [
      "\u{20D6}",  // overleftarrow
      "\u{20D7}",  // overrightarrow / vec
      "\u{20E1}",  // overleftrightarrow
    ]

    if arrowAccents.contains(accent.nucleus) {
      return false
    }

    return true
  }
}
