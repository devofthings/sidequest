import Foundation
import XCTest

final class FoundationBundleTests: XCTestCase {
  func testUnitFixtureIsAvailableOnlyInUnitTestBundle() throws {
    let testBundle = Bundle(for: Self.self)
    let fixtureURL = try XCTUnwrap(
      testBundle.url(forResource: "FoundationFixture", withExtension: "json")
    )
    let fixture = try JSONDecoder().decode(
      Fixture.self,
      from: Data(contentsOf: fixtureURL)
    )

    XCTAssertEqual(fixture.owner, "unit-tests")
    XCTAssertNil(Bundle.main.url(forResource: "FoundationFixture", withExtension: "json"))
    XCTAssertNil(testBundle.url(forResource: "FoundationLaunch", withExtension: "json"))
  }

  func testAppBundleHasExpectedIdentity() throws {
    let testIdentifier = try XCTUnwrap(Bundle(for: Self.self).bundleIdentifier)
    XCTAssertTrue(testIdentifier.hasSuffix(".tests"))
    XCTAssertEqual(Bundle.main.bundleIdentifier, String(testIdentifier.dropLast(".tests".count)))
    XCTAssertEqual(
      Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, "Sidequest")
  }

  private struct Fixture: Decodable {
    let owner: String
  }
}
