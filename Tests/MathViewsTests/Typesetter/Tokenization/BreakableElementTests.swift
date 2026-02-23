import CoreGraphics
import Foundation
import Testing

@testable import MathViews

#if os(macOS)
  import AppKit
#else
  import UIKit
#endif

struct BreakableElementTests {
  // MARK: - Data Structure Tests

  @Test func breakableElementCreation() {
    // Create a sample atom
    let atom = MathAtom(type: .ordinary, value: "x")

    // Create a breakable element
    let element = BreakableElement(
      content: .text("x"),
      width: 10.5,
      height: 12.0,
      ascent: 8.0,
      descent: 4.0,
      isBreakBefore: true,
      isBreakAfter: true,
      penaltyBefore: BreakPenalty.good,
      penaltyAfter: BreakPenalty.good,
      groupId: nil,
      parentId: nil,
      originalAtom: atom,
      indexRange: 0..<1,
      color: nil,
      backgroundColor: nil,
      indivisible: false,
    )

    // Verify properties
    #expect(element.width == 10.5)
    #expect(element.height == 12.0)
    #expect(element.ascent == 8.0)
    #expect(element.descent == 4.0)
    #expect(element.isBreakBefore)
    #expect(element.isBreakAfter)
    #expect(element.penaltyBefore == BreakPenalty.good)
    #expect(element.penaltyAfter == BreakPenalty.good)
    #expect(element.groupId == nil)
    #expect(element.parentId == nil)
    #expect(!element.indivisible)
  }

  @Test func elementContentText() {
    let content = ElementContent.text("hello")

    if case .text(let text) = content {
      #expect(text == "hello")
    } else {
      Issue.record("Expected text content")
    }
  }

  @Test func elementContentOperator() {
    let content = ElementContent.operator("+", type: .binaryOperator)

    if case .operator(let op, let type) = content {
      #expect(op == "+")
      #expect(type == .binaryOperator)
    } else {
      Issue.record("Expected operator content")
    }
  }

  @Test func elementContentSpace() {
    let content = ElementContent.space(5.0)

    if case .space(let width) = content {
      #expect(width == 5.0)
    } else {
      Issue.record("Expected space content")
    }
  }

  @Test func elementContentDisplay() {
    // Create a simple display
    let display = Display()
    display.width = 20.0
    display.ascent = 10.0
    display.descent = 5.0

    let content = ElementContent.display(display)

    if case .display(let disp) = content {
      #expect(disp.width == 20.0)
      #expect(disp.ascent == 10.0)
      #expect(disp.descent == 5.0)
    } else {
      Issue.record("Expected display content")
    }
  }

  @Test func elementContentScript() {
    let display = Display()
    display.width = 8.0

    let content = ElementContent.script(display, isSuper: true)

    if case .script(let disp, let isSuper) = content {
      #expect(disp.width == 8.0)
      #expect(isSuper)
    } else {
      Issue.record("Expected script content")
    }
  }

  @Test func groupedElements() {
    let atom1 = MathAtom(type: .variable, value: "x")
    let atom2 = MathAtom(type: .ordinary, value: "2")

    let groupId = UUID()

    let element1 = BreakableElement(
      content: .text("x"),
      width: 10.0,
      height: 12.0,
      ascent: 8.0,
      descent: 4.0,
      isBreakBefore: true,
      isBreakAfter: false,  // Cannot break after - grouped with script
      penaltyBefore: BreakPenalty.good,
      penaltyAfter: BreakPenalty.never,
      groupId: groupId,
      parentId: nil,
      originalAtom: atom1,
      indexRange: 0..<1,
      color: nil,
      backgroundColor: nil,
      indivisible: false,
    )

    let element2 = BreakableElement(
      content: .text("2"),
      width: 6.0,
      height: 8.0,
      ascent: 6.0,
      descent: 2.0,
      isBreakBefore: false,  // Cannot break before - grouped with base
      isBreakAfter: true,
      penaltyBefore: BreakPenalty.never,
      penaltyAfter: BreakPenalty.good,
      groupId: groupId,
      parentId: nil,
      originalAtom: atom2,
      indexRange: 1..<2,
      color: nil,
      backgroundColor: nil,
      indivisible: false,
    )

    // Verify grouping
    #expect(element1.groupId != nil)
    #expect(element1.groupId == element2.groupId)
    #expect(!element1.isBreakAfter)
    #expect(!element2.isBreakBefore)
  }

  @Test func indivisibleElement() {
    let atom = MathAtom(type: .fraction, value: "")
    let display = Display()

    let element = BreakableElement(
      content: .display(display),
      width: 50.0,
      height: 40.0,
      ascent: 25.0,
      descent: 15.0,
      isBreakBefore: true,
      isBreakAfter: true,
      penaltyBefore: BreakPenalty.moderate,
      penaltyAfter: BreakPenalty.moderate,
      groupId: nil,
      parentId: nil,
      originalAtom: atom,
      indexRange: 0..<1,
      color: nil,
      backgroundColor: nil,
      indivisible: true,  // Fractions are indivisible
    )

    #expect(element.indivisible)
  }

  @Test func penaltyConstants() {
    #expect(BreakPenalty.best == 0)
    #expect(BreakPenalty.good == 10)
    #expect(BreakPenalty.moderate == 15)
    #expect(BreakPenalty.acceptable == 50)
    #expect(BreakPenalty.bad == 100)
    #expect(BreakPenalty.never == 150)
  }

  @Test func elementWithColor() {
    let atom = MathAtom(type: .ordinary, value: "x")
    let redColor = PlatformColor.red

    let element = BreakableElement(
      content: .text("x"),
      width: 10.0,
      height: 12.0,
      ascent: 8.0,
      descent: 4.0,
      isBreakBefore: true,
      isBreakAfter: true,
      penaltyBefore: BreakPenalty.good,
      penaltyAfter: BreakPenalty.good,
      groupId: nil,
      parentId: nil,
      originalAtom: atom,
      indexRange: 0..<1,
      color: redColor,
      backgroundColor: nil,
      indivisible: false,
    )

    #expect(element.color != nil)
    #expect(element.color == redColor)
  }
}
