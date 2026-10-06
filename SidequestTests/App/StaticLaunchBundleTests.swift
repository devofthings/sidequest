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
    XCTAssertEqual(
      color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)),
      UIColor(red: 247 / 255, green: 247 / 255, blue: 248 / 255, alpha: 1))
    XCTAssertEqual(
      color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)),
      UIColor(red: 17 / 255, green: 17 / 255, blue: 20 / 255, alpha: 1))
  }
}
