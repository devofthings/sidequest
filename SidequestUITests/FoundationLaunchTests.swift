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
    app.launch()

    let heading = app.staticTexts["foundation.title"]
    XCTAssertTrue(heading.waitForExistence(timeout: 10))
    XCTAssertTrue(fixture.headings.contains(heading.label))
    XCTAssertTrue(app.selectedFeedCard.waitForExistence(timeout: 10))
    XCTAssertTrue(app.buttons["feed.navigation"].isHittable)
  }

  private struct Fixture: Decodable {
    let headings: [String]
  }
}
