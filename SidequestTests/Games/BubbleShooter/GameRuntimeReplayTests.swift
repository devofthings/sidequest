import Foundation
import XCTest

@testable import Sidequest

@MainActor
final class GameRuntimeReplayTests: XCTestCase {
  func testReplayInvalidatesOldBeforeResetThenStartsFreshWithoutInput() {
    var number: UInt8 = 0
    let runtime = GameRuntime(makeAttemptID: {
      number += 1
      return GameAttemptID(UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, number)))
    })
    var effects: [GameLifecycleEffect] = []
    runtime.installEffectHandler { effect in
      effects.append(effect)
      if case .reset(let old) = effect {
        XCTAssertEqual(runtime.phase, .preview)
        XCTAssertTrue(runtime.isVisible)
        XCTAssertFalse(runtime.acceptsInput(from: old))
      }
    }
    XCTAssertFalse(runtime.replay())
    runtime.setVisible(true)
    XCTAssertFalse(runtime.replay())
    runtime.start()
    guard case .playing(let old) = runtime.phase else { return XCTFail("Expected start") }
    XCTAssertFalse(runtime.replay())
    runtime.complete(attempt: old)
    XCTAssertTrue(runtime.replay())
    guard case .playing(let fresh) = runtime.phase else { return XCTFail("Expected replay") }
    XCTAssertNotEqual(old, fresh)
    XCTAssertEqual(effects, [.start(old), .stop(old), .reset(old), .start(fresh)])
    runtime.complete(attempt: old)
    XCTAssertEqual(runtime.phase, .playing(fresh))
    XCTAssertFalse(runtime.acceptsInput(from: old))
    XCTAssertTrue(runtime.acceptsInput(from: fresh))
  }

  func testHiddenAndDuplicateIdentityReplayPreserveCompletion() {
    let token = GameAttemptID()
    let runtime = GameRuntime(makeAttemptID: { token })
    var effects: [GameLifecycleEffect] = []
    runtime.installEffectHandler { effects.append($0) }
    runtime.setVisible(true)
    runtime.start()
    runtime.complete(attempt: token)
    runtime.setVisible(false)
    XCTAssertFalse(runtime.replay())
    runtime.setVisible(true)
    XCTAssertFalse(runtime.replay())
    XCTAssertEqual(runtime.phase, .completed(token))
    XCTAssertEqual(effects, [.start(token), .stop(token)])
  }

  func testResetThatHidesCardCannotStartReplay() {
    let runtime = GameRuntime()
    runtime.installEffectHandler { effect in
      if case .reset = effect { runtime.setVisible(false) }
    }
    runtime.setVisible(true)
    runtime.start()
    guard case .playing(let old) = runtime.phase else { return XCTFail("Expected start") }
    runtime.complete(attempt: old)
    XCTAssertTrue(runtime.replay())
    XCTAssertEqual(runtime.phase, .preview)
    XCTAssertFalse(runtime.isVisible)
  }
}
