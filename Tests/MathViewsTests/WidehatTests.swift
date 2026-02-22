import CoreGraphics
import Testing

@testable import MathViews

struct WidehatTests {

  let font: FontInstance

  init() {
    font = MathFont.termesFont.fontInstance(size: 20)
  }

  // MARK: - Basic Functionality Tests

  @Test func widehatVsHat() {
    // Test that \widehat and \hat produce different results
    let hatLatex = "\\hat{ABC}"
    let widehatLatex = "\\widehat{ABC}"

    let hatMathList = MathListBuilder.build(fromString: hatLatex)
    let widehatMathList = MathListBuilder.build(fromString: widehatLatex)

    let hatDisplay = Typesetter.createLineForMathList(hatMathList, font: font, style: .display)
    let widehatDisplay = Typesetter.createLineForMathList(
      widehatMathList, font: font, style: .display)

    #expect(hatDisplay != nil, "\\hat should render")
    #expect(widehatDisplay != nil, "\\widehat should render")

    // Get the accent displays
    guard let hatAccentDisp = hatDisplay?.subDisplays.first as? AccentDisplay,
      let widehatAccentDisp = widehatDisplay?.subDisplays.first as? AccentDisplay,
      let hatAccent = hatAccentDisp.accent,
      let widehatAccent = widehatAccentDisp.accent
    else {
      Issue.record("Could not extract accent displays")
      return
    }

    // Widehat should have greater width than hat for the same content
    #expect(
      widehatAccent.width > hatAccent.width,
      "\\widehat should be wider than \\hat for multi-character content")
  }

  @Test func widetildeVsTilde() {
    // Test that \widetilde and \tilde produce different results
    let tildeLatex = "\\tilde{ABC}"
    let widetildeLatex = "\\widetilde{ABC}"

    let tildeMathList = MathListBuilder.build(fromString: tildeLatex)
    let widetildeMathList = MathListBuilder.build(fromString: widetildeLatex)

    let tildeDisplay = Typesetter.createLineForMathList(tildeMathList, font: font, style: .display)
    let widetildeDisplay = Typesetter.createLineForMathList(
      widetildeMathList, font: font, style: .display)

    #expect(tildeDisplay != nil, "\\tilde should render")
    #expect(widetildeDisplay != nil, "\\widetilde should render")

    guard let tildeAccentDisp = tildeDisplay?.subDisplays.first as? AccentDisplay,
      let widetildeAccentDisp = widetildeDisplay?.subDisplays.first as? AccentDisplay,
      let tildeAccent = tildeAccentDisp.accent,
      let widetildeAccent = widetildeAccentDisp.accent
    else {
      Issue.record("Could not extract accent displays")
      return
    }

    #expect(
      widetildeAccent.width > tildeAccent.width,
      "\\widetilde should be wider than \\tilde for multi-character content")
  }

  // MARK: - Coverage Tests

  @Test func widehatSingleCharCoverage() {
    // Test that \widehat covers a single character
    let latex = "\\widehat{x}"
    let mathList = MathListBuilder.build(fromString: latex)
    let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)

    guard let accentDisp = display?.subDisplays.first as? AccentDisplay,
      let accentee = accentDisp.accentee,
      let accent = accentDisp.accent
    else {
      Issue.record("Could not extract accent display")
      return
    }

    let coverage = accent.width / accentee.width * 100

    // Should cover at least 100% of content
    #expect(
      coverage >= 100,
      "\\widehat should cover at least 100% of single character")
    // Should not be excessively wide (less than 150%)
    #expect(
      coverage < 150,
      "\\widehat should not be excessively wide for single character")
  }

  struct WidehatCase: Sendable, CustomTestStringConvertible {
    let latex: String
    let description: String
    var testDescription: String { description }

    static let all: [WidehatCase] = [
      WidehatCase(latex: "\\widehat{AB}", description: "two characters"),
      WidehatCase(latex: "\\widehat{ABC}", description: "three characters"),
      WidehatCase(latex: "\\widehat{ABCD}", description: "four characters"),
      WidehatCase(latex: "\\widehat{ABCDEF}", description: "six characters"),
    ]
  }

  @Test(arguments: WidehatCase.all)
  func widehatMultiCharCoverage(_ testCase: WidehatCase) {
    // Test that \widehat covers multiple characters
    let mathList = MathListBuilder.build(fromString: testCase.latex)
    let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)

    guard let accentDisp = display?.subDisplays.first as? AccentDisplay,
      let accentee = accentDisp.accentee,
      let accent = accentDisp.accent
    else {
      Issue.record("Could not extract accent display for \(testCase.description)")
      return
    }

    let coverage = accent.width / accentee.width * 100

    // Should cover at least 100% of content (with padding)
    #expect(
      coverage >= 100,
      "\\widehat should cover at least 100% for \(testCase.description)")
    // Should not be excessively wide (less than 150%)
    #expect(
      coverage < 150,
      "\\widehat should not be excessively wide for \(testCase.description)")
  }

  @Test func widetildeCoverage() {
    // Test that \widetilde covers content properly
    let latex = "\\widetilde{ABC}"
    let mathList = MathListBuilder.build(fromString: latex)
    let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)

    guard let accentDisp = display?.subDisplays.first as? AccentDisplay,
      let accentee = accentDisp.accentee,
      let accent = accentDisp.accent
    else {
      Issue.record("Could not extract accent display")
      return
    }

    let coverage = accent.width / accentee.width * 100

    #expect(
      coverage >= 100,
      "\\widetilde should cover at least 100% of content")
    #expect(
      coverage < 150,
      "\\widetilde should not be excessively wide")
  }

  // MARK: - Flag Tests

  @Test func isWideFlagSet() {
    // Test that isWide flag is set correctly by factory
    let widehat = MathAtomFactory.accent(withName: "widehat")
    let widetilde = MathAtomFactory.accent(withName: "widetilde")
    let hat = MathAtomFactory.accent(withName: "hat")
    let tilde = MathAtomFactory.accent(withName: "tilde")

    #expect(widehat?.isWide ?? false, "\\widehat should have isWide=true")
    #expect(widetilde?.isWide ?? false, "\\widetilde should have isWide=true")
    #expect(!(hat?.isWide ?? true), "\\hat should have isWide=false")
    #expect(!(tilde?.isWide ?? true), "\\tilde should have isWide=false")
  }

  // MARK: - Complex Content Tests

  @Test func widehatWithFraction() {
    // Test widehat over a fraction
    let latex = "\\widehat{\\frac{a}{b}}"
    let mathList = MathListBuilder.build(fromString: latex)
    let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)

    #expect(display != nil, "\\widehat with fraction should render")

    guard let accentDisp = display?.subDisplays.first as? AccentDisplay,
      let accentee = accentDisp.accentee,
      let accent = accentDisp.accent
    else {
      Issue.record("Could not extract accent display")
      return
    }

    let coverage = accent.width / accentee.width * 100

    // Should cover the fraction
    #expect(
      coverage >= 90,
      "\\widehat should adequately cover fraction")
  }

  @Test func widehatWithSubscript() {
    // Test widehat with subscripted content
    let latex = "\\widehat{x_i}"
    let mathList = MathListBuilder.build(fromString: latex)
    let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)

    #expect(display != nil, "\\widehat with subscript should render")
  }

  @Test func widehatWithSuperscript() {
    // Test widehat with superscripted content
    let latex = "\\widehat{x^2}"
    let mathList = MathListBuilder.build(fromString: latex)
    let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)

    #expect(display != nil, "\\widehat with superscript should render")
  }

  // MARK: - Vertical Spacing Tests

  @Test func widehatVerticalSpacing() {
    // Test that widehat has proper vertical spacing
    let latex = "\\widehat{ABC}"
    let mathList = MathListBuilder.build(fromString: latex)
    let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)

    guard let accentDisp = display?.subDisplays.first as? AccentDisplay else {
      Issue.record("Could not extract accent display")
      return
    }

    // The overall display should be taller than just the content
    #expect(
      accentDisp.ascent > accentDisp.accentee?.ascent ?? 0,
      "Accent display should be taller than content alone")
  }

  // MARK: - Backward Compatibility Tests

  @Test func hatStillWorks() {
    // Test that \hat still works as before
    let latex = "\\hat{x}"
    let mathList = MathListBuilder.build(fromString: latex)
    let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)

    #expect(display != nil, "\\hat should still render")
  }

  @Test func tildeStillWorks() {
    // Test that \tilde still works as before
    let latex = "\\tilde{x}"
    let mathList = MathListBuilder.build(fromString: latex)
    let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)

    #expect(display != nil, "\\tilde should still render")
  }

  // MARK: - Edge Cases

  @Test func widehatEmpty() {
    // Test widehat with empty content
    let latex = "\\widehat{}"
    let mathList = MathListBuilder.build(fromString: latex)
    let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)

    // Should handle empty content gracefully
    #expect(display != nil, "\\widehat with empty content should not crash")
  }

  @Test func widehatVeryLongContent() {
    // Test widehat with very long content
    let latex = "\\widehat{abcdefghijk}"
    let mathList = MathListBuilder.build(fromString: latex)
    let display = Typesetter.createLineForMathList(mathList, font: font, style: .display)

    #expect(display != nil, "\\widehat with long content should render")

    guard let accentDisp = display?.subDisplays.first as? AccentDisplay,
      let accentee = accentDisp.accentee,
      let accent = accentDisp.accent
    else {
      Issue.record("Could not extract accent display")
      return
    }

    let coverage = accent.width / accentee.width * 100

    // Should still cover the content
    #expect(
      coverage >= 90,
      "\\widehat should cover even very long content")
  }
}
