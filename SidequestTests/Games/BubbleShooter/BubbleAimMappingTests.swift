import XCTest

@testable import Sidequest

final class BubbleAimMappingTests: XCTestCase {
  func testHorizontalPositionMapsPredictablyAtEveryHeightAndScale() throws {
    for width in [200.0, 300.0] {
      for height in [0.0, 0.2, 0.8, 1.0] {
        for (fraction, expected) in [
          (0.0, -60.0), (0.3, -24.0), (0.5, 0.0), (0.8, 36.0), (1.0, 60.0),
        ] {
          let point = BubblePoint(x: fraction * width, y: height * width / 2)
          XCTAssertEqual(
            try XCTUnwrap(BubbleAimMapping.degrees(point: point, width: width)),
            expected, accuracy: 0.0001)
        }
      }
    }
  }

  func testHorizontalDragIsContinuousAndVerticalMovementPreservesAim() throws {
    let width = 240.0
    var previous = -61.0
    for x in stride(from: 0.0, through: width, by: 1) {
      let launcherHeight = BubblePoint(x: x, y: width * 0.4)
      let angle = try XCTUnwrap(BubbleAimMapping.degrees(point: launcherHeight, width: width))
      XCTAssertGreaterThan(angle, previous)
      XCTAssertEqual(angle - previous, x == 0 ? 1 : 0.5, accuracy: 0.0001)
      let upperPoint = BubblePoint(x: x, y: 0)
      XCTAssertEqual(BubbleAimMapping.degrees(point: upperPoint, width: width), angle)
      previous = angle
    }
  }

  func testInvalidCoordinatesPreserveThePreviousAimByReturningNoUpdate() {
    for point in [
      BubblePoint(x: -1, y: 1), BubblePoint(x: 201, y: 1),
      BubblePoint(x: 100, y: -1), BubblePoint(x: 100, y: 101),
      BubblePoint(x: .nan, y: 1), BubblePoint(x: 100, y: .infinity),
    ] {
      XCTAssertNil(BubbleAimMapping.degrees(point: point, width: 200))
    }
    for width in [0.0, -1, .nan, .infinity] {
      XCTAssertNil(BubbleAimMapping.degrees(point: BubblePoint(x: 0, y: 0), width: width))
    }
  }
}
