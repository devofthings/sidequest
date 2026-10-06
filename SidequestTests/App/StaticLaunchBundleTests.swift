import UIKit
import XCTest

@MainActor
final class StaticLaunchBundleTests: XCTestCase {
  func testCompiledLaunchScreenUsesTheSelectedLogoAndAdaptiveCanvas() throws {
    XCTAssertEqual(
      Bundle.main.object(forInfoDictionaryKey: "UILaunchStoryboardName") as? String,
      "LaunchScreen")
    XCTAssertNil(Bundle.main.object(forInfoDictionaryKey: "UILaunchScreen"))
    XCTAssertNotNil(Bundle.main.url(forResource: "LaunchScreen", withExtension: "storyboardc"))
    XCTAssertNotNil(UIImage(named: "StartupLogo", in: .main, compatibleWith: nil))
    let storyboard = UIStoryboard(name: "LaunchScreen", bundle: .main)
    let controller = try XCTUnwrap(storyboard.instantiateInitialViewController())
    controller.loadViewIfNeeded()
    let view = try XCTUnwrap(controller.view)
    let image = try XCTUnwrap(view.subviews.compactMap { $0 as? UIImageView }.first)
    XCTAssertNotNil(image.image)
    view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
    view.layoutIfNeeded()
    XCTAssertEqual(image.frame.width, 120, accuracy: 0.5)
    XCTAssertEqual(image.frame.height, 120, accuracy: 0.5)
    XCTAssertEqual(image.center.x, view.bounds.midX, accuracy: 0.5)
    XCTAssertEqual(image.center.y, view.bounds.midY, accuracy: 0.5)
    let color = try XCTUnwrap(UIColor(named: "LaunchCanvas", in: .main, compatibleWith: nil))
    assertComponents(
      color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)),
      expected: (247, 247, 248))
    assertComponents(
      color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)),
      expected: (17, 17, 20))
  }

  private func assertComponents(
    _ color: UIColor, expected: (CGFloat, CGFloat, CGFloat),
    file: StaticString = #filePath, line: UInt = #line
  ) {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    XCTAssertTrue(
      color.getRed(&red, green: &green, blue: &blue, alpha: &alpha), file: file, line: line)
    XCTAssertEqual(red, expected.0 / 255, accuracy: 1 / 255, file: file, line: line)
    XCTAssertEqual(green, expected.1 / 255, accuracy: 1 / 255, file: file, line: line)
    XCTAssertEqual(blue, expected.2 / 255, accuracy: 1 / 255, file: file, line: line)
    XCTAssertEqual(alpha, 1, accuracy: 1 / 255, file: file, line: line)
  }
}
