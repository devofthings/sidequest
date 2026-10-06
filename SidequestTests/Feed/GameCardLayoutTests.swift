import SwiftUI
import XCTest

@testable import Sidequest

@MainActor
final class GameCardLayoutTests: XCTestCase {
  func testFittingContentCentersInsideTheActualHostedViewport() async throws {
    let measurement = try await measure(contentHeight: 120, viewportHeight: 600)
    XCTAssertEqual(measurement.content.midX, 375 / 2, accuracy: 0.5)
    XCTAssertEqual(measurement.content.midY, 300, accuracy: 0.5)
    XCTAssertEqual(measurement.content.height, 120, accuracy: 0.5)
    XCTAssertEqual(measurement.hostHeight, 600, accuracy: 0.5)
  }

  func testOversizedContentRetainsNaturalHeightAndReachableTop() async throws {
    let measurement = try await measure(contentHeight: 900, viewportHeight: 600)
    XCTAssertEqual(measurement.content.minY, 16, accuracy: 0.5)
    XCTAssertEqual(measurement.content.height, 900, accuracy: 0.5)
    XCTAssertGreaterThan(measurement.hostHeight, 600)
    XCTAssertLessThanOrEqual(measurement.content.maxY, measurement.hostHeight)
  }

  private func measure(contentHeight: CGFloat, viewportHeight: CGFloat) async throws -> Measurement
  {
    let ready = expectation(description: "Native hosted game geometry")
    var contentFrame: CGRect?
    let content = Color.clear.frame(height: contentHeight)
      .onGeometryChange(for: CGRect.self) {
        $0.frame(in: .global)
      } action: { frame in
        guard frame.width > 0, frame.height > 0 else { return }
        if contentFrame == nil { ready.fulfill() }
        contentFrame = frame
      }
    let root = GameCardLayout(showsStart: false, start: EmptyView(), content: content)
      .environment(\.sidequestCardViewport, CGSize(width: 375, height: viewportHeight))
      .ignoresSafeArea()
    let hosting = UIHostingController(rootView: root)
    // Match the production host: fixed width, natural height with a viewport minimum.
    hosting.view.translatesAutoresizingMaskIntoConstraints = false
    hosting.view.bounds = CGRect(x: 0, y: 0, width: 375, height: viewportHeight)
    NSLayoutConstraint.activate([
      hosting.view.widthAnchor.constraint(equalToConstant: 375),
      hosting.view.heightAnchor.constraint(greaterThanOrEqualToConstant: viewportHeight),
    ])
    let fitted = hosting.sizeThatFits(in: CGSize(width: 375, height: viewportHeight))
    let hostHeight = max(viewportHeight, fitted.height)
    hosting.view.frame = CGRect(x: 0, y: 0, width: 375, height: hostHeight)
    let scene = try XCTUnwrap(
      UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    window.frame = hosting.view.frame
    window.rootViewController = hosting
    window.isHidden = false
    defer {
      window.isHidden = true
      window.rootViewController = nil
    }
    hosting.view.layoutIfNeeded()
    let result = await XCTWaiter.fulfillment(of: [ready], timeout: 3)
    XCTAssertEqual(result, .completed)
    return Measurement(content: try XCTUnwrap(contentFrame), hostHeight: hostHeight)
  }

  private struct Measurement {
    let content: CGRect
    let hostHeight: CGFloat
  }
}
