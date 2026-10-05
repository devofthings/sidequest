import XCTest

@testable import Sidequest

final class BubbleAimMappingTests: XCTestCase {
  func testUniformScaleMapsKnownVerticalAndDiagonalRays() throws {
    for width in [200.0, 300.0] {
      let scale = width / 10
      XCTAssertEqual(
        try XCTUnwrap(
          BubbleAimMapping.degrees(point: BubblePoint(x: 5 * scale, y: scale), width: width)),
        0, accuracy: 0.0001)
      XCTAssertEqual(
        try XCTUnwrap(
          BubbleAimMapping.degrees(point: BubblePoint(x: 8 * scale, y: scale), width: width)),
        45, accuracy: 0.0001)
      XCTAssertEqual(
        try XCTUnwrap(
          BubbleAimMapping.degrees(point: BubblePoint(x: 2 * scale, y: scale), width: width)),
        -45, accuracy: 0.0001)
    }
  }

  func testNearHorizontalRaysClampAtSupportedLimits() {
    XCTAssertEqual(BubbleAimMapping.degrees(point: BubblePoint(x: 200, y: 79), width: 200), 60)
    XCTAssertEqual(BubbleAimMapping.degrees(point: BubblePoint(x: 0, y: 79), width: 200), -60)
  }

  func testInvalidCoordinatesCannotProduceDownwardOrUndefinedAim() {
    for point in [
      BubblePoint(x: 100, y: 80), BubblePoint(x: 110, y: 90),
      BubblePoint(x: -1, y: 1), BubblePoint(x: 201, y: 1),
      BubblePoint(x: 100, y: -1), BubblePoint(x: .nan, y: 1),
      BubblePoint(x: 100, y: .infinity),
    ] {
      XCTAssertNil(BubbleAimMapping.degrees(point: point, width: 200))
    }
    for width in [0.0, -1, .nan, .infinity] {
      XCTAssertNil(BubbleAimMapping.degrees(point: BubblePoint(x: 0, y: 0), width: width))
    }
  }
}
