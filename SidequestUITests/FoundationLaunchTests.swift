import Foundation
import XCTest

final class FoundationLaunchTests: XCTestCase {
  @MainActor
  func testLaunchShowsAccessibleHeading() throws {
    let testBundle = Bundle(for: Self.self)
    let fixtureURL = try XCTUnwrap(
      testBundle.url(forResource: "FoundationLaunch", withExtension: "json")
    )
    let fixture = try JSONDecoder().decode(
      Fixture.self,
      from: Data(contentsOf: fixtureURL)
    )
    XCTAssertNil(testBundle.url(forResource: "FoundationFixture", withExtension: "json"))

    let app = XCUIApplication()
    app.launchArguments = ["-sidequest-sudoku-test"]
    app.launch()

    let heading = app.staticTexts["foundation.title"]
    XCTAssertTrue(heading.waitForExistence(timeout: 10))
    XCTAssertEqual(heading.label, fixture.heading)
  }

  private struct Fixture: Decodable {
    let heading: String
  }
}
