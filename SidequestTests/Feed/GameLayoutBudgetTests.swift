import CoreGraphics
import XCTest

@testable import Sidequest

final class GameLayoutBudgetTests: XCTestCase {
  func testMeasuredCardChromeLeavesSpaceForGameChromeAndBoard() {
    let budget = GameLayoutBudget(viewport: CGSize(width: 375, height: 579), chromeHeight: 95)
    XCTAssertEqual(budget.width, 343)
    XCTAssertEqual(budget.height, 432)
    XCTAssertEqual(budget.squareBoardExtent(chromeHeight: 200, columns: 4), 224)
  }

  func testFirstInteractionCardsUseSpaceFreedByAbsentStartChrome() {
    let budget = GameLayoutBudget(
      viewport: CGSize(width: 375, height: 579), chromeHeight: 0, chromeSpacing: 0)
    XCTAssertEqual(budget.width, 343)
    XCTAssertEqual(budget.height, 547)
  }

  func testUnfittableBudgetPreservesTargetsInsteadOfForcingFit() {
    let budget = GameLayoutBudget(viewport: CGSize(width: 140, height: 100), chromeHeight: 300)
    XCTAssertEqual(budget.height, 0)
    XCTAssertEqual(budget.squareBoardExtent(chromeHeight: 200, columns: 4), 176)
  }

  func testRealViewportChangeRecalculatesWithoutGameState() {
    let small = GameLayoutBudget(viewport: CGSize(width: 375, height: 579), chromeHeight: 95)
    let large = GameLayoutBudget(viewport: CGSize(width: 440, height: 800), chromeHeight: 95)
    XCTAssertGreaterThan(
      large.squareBoardExtent(chromeHeight: 200, columns: 4),
      small.squareBoardExtent(chromeHeight: 200, columns: 4))
    XCTAssertEqual(large.squareBoardExtent(chromeHeight: 200, columns: 4), large.width)
  }
}
