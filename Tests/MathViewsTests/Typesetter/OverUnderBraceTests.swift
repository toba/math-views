import Testing
@testable import MathViews
import CoreGraphics

struct OverUnderBraceTests {
    let font: FontInstance

    init() {
        font = MathFont.termes.fontInstance(size: 20)
    }

    // MARK: - Parsing

    @Test func overbraceParses() throws {
        let list = try MathListBuilder.buildChecked(fromString: "\\overbrace{x+y}")
        #expect(list.atoms.count == 1)
        let atom = try #require(list.atoms.first as? OverBrace)
        #expect(atom.type == .overbrace)
        #expect(atom.innerList != nil)
        #expect(atom.innerList?.atoms.count == 3) // x, +, y
    }

    @Test func underbraceParses() throws {
        let list = try MathListBuilder.buildChecked(fromString: "\\underbrace{a+b}")
        #expect(list.atoms.count == 1)
        let atom = try #require(list.atoms.first as? UnderBrace)
        #expect(atom.type == .underbrace)
        #expect(atom.innerList != nil)
    }

    @Test func overbraceWithAnnotation() throws {
        let list = try MathListBuilder.buildChecked(fromString: "\\overbrace{x+y+z}^{3}")
        #expect(list.atoms.count == 1)
        let atom = try #require(list.atoms.first as? OverBrace)
        #expect(atom.superScript != nil)
    }

    @Test func underbraceWithAnnotation() throws {
        let list = try MathListBuilder.buildChecked(fromString: "\\underbrace{a+b+c}_{3}")
        #expect(list.atoms.count == 1)
        let atom = try #require(list.atoms.first as? UnderBrace)
        #expect(atom.subScript != nil)
    }

    // MARK: - Round-trip

    @Test func overbraceRoundTrip() throws {
        let latex = "\\overbrace{x+y+z}^{3}"
        let list = try MathListBuilder.buildChecked(fromString: latex)
        let result = MathListBuilder.mathListToString(list)
        #expect(result == latex)
    }

    @Test func underbraceRoundTrip() throws {
        let latex = "\\underbrace{a+b+c}_{3}"
        let list = try MathListBuilder.buildChecked(fromString: latex)
        let result = MathListBuilder.mathListToString(list)
        #expect(result == latex)
    }

    // MARK: - Typesetting

    @Test func overbraceTypesets() throws {
        let list = MathListBuilder.build(fromString: "\\overbrace{x+y}")
        let display = try #require(
            Typesetter.makeLineDisplay(for: list, font: font, style: .display),
        )
        #expect(display.width > 0)
        #expect(display.ascent > 0)
    }

    @Test func underbraceTypesets() throws {
        let list = MathListBuilder.build(fromString: "\\underbrace{a+b}")
        let display = try #require(
            Typesetter.makeLineDisplay(for: list, font: font, style: .display),
        )
        #expect(display.width > 0)
        #expect(display.descent > 0)
    }

    @Test func overbraceWithAnnotationTypesets() throws {
        let list = MathListBuilder.build(fromString: "\\overbrace{x+y+z}^{3}")
        let display = try #require(
            Typesetter.makeLineDisplay(for: list, font: font, style: .display),
        )
        // With annotation, ascent should be larger than without
        let listNoAnnotation = MathListBuilder.build(fromString: "\\overbrace{x+y+z}")
        let displayNoAnnotation = try #require(
            Typesetter.makeLineDisplay(for: listNoAnnotation, font: font, style: .display),
        )
        #expect(display.ascent > displayNoAnnotation.ascent)
    }

    @Test func underbraceWithAnnotationTypesets() throws {
        let list = MathListBuilder.build(fromString: "\\underbrace{a+b+c}_{3}")
        let display = try #require(
            Typesetter.makeLineDisplay(for: list, font: font, style: .display),
        )
        let listNoAnnotation = MathListBuilder.build(fromString: "\\underbrace{a+b+c}")
        let displayNoAnnotation = try #require(
            Typesetter.makeLineDisplay(for: listNoAnnotation, font: font, style: .display),
        )
        #expect(display.descent > displayNoAnnotation.descent)
    }

    @Test func nestedBraces() throws {
        // \underbrace{\overbrace{a+b}^{2}+c}_{3}
        let latex = "\\underbrace{\\overbrace{a+b}^{2}+c}_{3}"
        let list = try MathListBuilder.buildChecked(fromString: latex)
        #expect(list.atoms.count == 1)
        let display = try #require(
            Typesetter.makeLineDisplay(for: list, font: font, style: .display),
        )
        #expect(display.width > 0)
    }
}
