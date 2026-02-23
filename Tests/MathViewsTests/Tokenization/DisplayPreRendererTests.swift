import Testing
@testable import MathViews
import CoreGraphics

struct DisplayPreRendererTests {
    let font: FontInstance
    let renderer: DisplayPreRenderer

    init() {
        font = MathFont.latinModernFont.fontInstance(size: 20)
        renderer = DisplayPreRenderer(font: font, style: .display, cramped: false)
    }

    // MARK: - Script Rendering Tests

    @Test func renderSuperscript() throws {
        // Create a simple superscript: 2
        let mathList = MathList()
        let atom = MathAtom(type: .number, value: "2")
        mathList.add(atom)

        let display = renderer.renderScript(mathList, isSuper: true)

        #expect(display != nil, "Superscript display should not be nil")
        #expect(try #require(display?.width) > 0, "Superscript should have positive width")
        #expect(try #require(display?.ascent) > 0, "Superscript should have positive ascent")
    }

    @Test func renderSubscript() throws {
        // Create a simple subscript: i
        let mathList = MathList()
        let atom = MathAtom(type: .variable, value: "i")
        mathList.add(atom)

        let display = renderer.renderScript(mathList, isSuper: false)

        #expect(display != nil, "Subscript display should not be nil")
        #expect(try #require(display?.width) > 0, "Subscript should have positive width")
    }

    @Test func scriptStyleInDisplayMode() {
        // In display mode, scripts should use script style
        let displayRenderer = DisplayPreRenderer(font: font, style: .display, cramped: false)

        let mathList = MathList()
        mathList.add(MathAtom(type: .variable, value: "x"))

        let display = displayRenderer.renderScript(mathList, isSuper: true)

        #expect(display != nil)
        // Script style should be smaller than display style
        // We can't directly check the style, but we can verify it renders
    }

    @Test func scriptStyleInScriptMode() {
        // In script mode, scripts should use scriptOfScript style
        let scriptRenderer = DisplayPreRenderer(font: font, style: .script, cramped: false)

        let mathList = MathList()
        mathList.add(MathAtom(type: .variable, value: "x"))

        let display = scriptRenderer.renderScript(mathList, isSuper: true)

        #expect(display != nil)
    }

    // MARK: - Math List Rendering Tests

    @Test func renderSimpleMathList() throws {
        let mathList = MathList()
        mathList.add(MathAtom(type: .variable, value: "x"))
        mathList.add(MathAtom(type: .binaryOperator, value: "+"))
        mathList.add(MathAtom(type: .variable, value: "y"))

        let display = renderer.renderMathList(mathList)

        #expect(display != nil, "Display should not be nil")
        #expect(try #require(display?.width) > 0, "Display should have positive width")
    }

    @Test func renderNilMathList() {
        let display = renderer.renderMathList(nil)
        #expect(display == nil, "Nil math list should produce nil display")
    }

    @Test func renderEmptyMathList() {
        let mathList = MathList()
        let display = renderer.renderMathList(mathList)

        // Empty math list may return nil or empty display depending on implementation
        // Just verify it doesn't crash
        if let display {
            #expect(display.width == 0, "Empty math list should have zero width")
        }
    }

    @Test func renderWithCustomStyle() throws {
        let mathList = MathList()
        mathList.add(MathAtom(type: .variable, value: "x"))

        // Render with text style instead of display style
        let display = renderer.renderMathList(mathList, style: .text)

        #expect(display != nil)
        #expect(try #require(display?.width) > 0)
    }

    @Test func renderWithCustomCramped() throws {
        let mathList = MathList()
        mathList.add(MathAtom(type: .variable, value: "x"))

        // Render with cramped mode
        let display = renderer.renderMathList(mathList, cramped: true)

        #expect(display != nil)
        #expect(try #require(display?.width) > 0)
    }

    // MARK: - Complex Content Tests

    @Test func renderComplexScript() throws {
        // Create a complex superscript: a+b
        let mathList = MathList()
        mathList.add(MathAtom(type: .variable, value: "a"))
        mathList.add(MathAtom(type: .binaryOperator, value: "+"))
        mathList.add(MathAtom(type: .variable, value: "b"))

        let display = renderer.renderScript(mathList, isSuper: true)

        #expect(display != nil)
        #expect(try #require(display?.width) > 0)
    }

    @Test func renderMultipleAtoms() throws {
        let mathList = MathList()
        mathList.add(MathAtom(type: .number, value: "1"))
        mathList.add(MathAtom(type: .binaryOperator, value: "+"))
        mathList.add(MathAtom(type: .number, value: "2"))
        mathList.add(MathAtom(type: .relation, value: "="))
        mathList.add(MathAtom(type: .number, value: "3"))

        let display = renderer.renderMathList(mathList)

        #expect(display != nil)
        #expect(try #require(display?.width) > 0)
    }

    // MARK: - Font and Style Tests

    @Test func rendererWithDifferentFonts() throws {
        let smallFont = MathFont.latinModernFont.fontInstance(size: 10)
        let smallRenderer = DisplayPreRenderer(font: smallFont, style: .display, cramped: false)

        let mathList = MathList()
        mathList.add(MathAtom(type: .variable, value: "x"))

        let normalDisplay = renderer.renderMathList(mathList)
        let smallDisplay = smallRenderer.renderMathList(mathList)

        #expect(normalDisplay != nil)
        #expect(smallDisplay != nil)

        // Smaller font should produce narrower display
        #expect(try #require(smallDisplay?.width) < normalDisplay!.width)
    }

    @Test func crampedMode() {
        let normalRenderer = DisplayPreRenderer(font: font, style: .display, cramped: false)
        let crampedRenderer = DisplayPreRenderer(font: font, style: .display, cramped: true)

        let mathList = MathList()
        mathList.add(MathAtom(type: .variable, value: "x"))

        let normalDisplay = normalRenderer.renderMathList(mathList)
        let crampedDisplay = crampedRenderer.renderMathList(mathList)

        #expect(normalDisplay != nil)
        #expect(crampedDisplay != nil)
        // Both should render successfully
    }
}
