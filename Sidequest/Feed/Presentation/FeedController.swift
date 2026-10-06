import Observation

@MainActor
@Observable
final class FeedController {
  private var selection: FeedSelection
  private var sceneIsActive = false
  private var hostIsAvailable = true
  private var isRetired = false
  private(set) var runtimes: [CardID: GameRuntime]
  let isEndless: Bool
  var replenishmentMessage: String?
  @ObservationIgnored var physicalSwipeDidCommit: (() -> Void)?
  @ObservationIgnored var windowDidChange:
    (([FeedCard]) -> Result<[CardID: GameRuntime], FeedWindowError>)?
  @ObservationIgnored var demandDidChange: (() -> Void)?
  @ObservationIgnored var retryReplenishment: (() -> Void)?

  var cards: [FeedCard] { selection.cards }
  var selectedIndex: Int? { selection.index }
  var canNavigate: Bool { sceneIsActive && hostIsAvailable && !isRetired }

  var selectedCard: FeedCard? { selection.card }
  var position: Int? { selection.index.map { $0 + 1 } }
  var count: Int { selection.cards.count }
  var canGoBack: Bool { selection.canGoBack }
  var canGoForward: Bool { selection.canGoForward }

  init(cards: [FeedCard], runtimes: [CardID: GameRuntime], isEndless: Bool = false) {
    // DeckBuilder has already validated card identity. Missing adapters are a
    // composition error, rather than a game that silently accepts no input.
    precondition(
      isEndless
        || cards.allSatisfy { card in
          if case .game(let game) = card { return runtimes[game.id] != nil }
          return true
        }, "Every game card needs a retained runtime.")
    selection = FeedSelection(cards: cards)
    self.runtimes = runtimes
    self.isEndless = isEndless
  }

  func setSceneActive(_ active: Bool) {
    sceneIsActive = active
    updateVisibility()
  }

  func setHostAvailable(_ available: Bool) {
    hostIsAvailable = available
    updateVisibility()
  }

  func retire() {
    isRetired = true
    for runtime in runtimes.values { runtime.retire() }
    demandDidChange?()
  }

  /// Prepared descriptors have been validated before this synchronous append.
  @discardableResult
  func append(_ cards: [FeedCard]) -> Bool {
    guard !isRetired else { return false }
    var candidate = selection
    candidate.append(cards)
    guard adoptWindow(candidate) else { return false }
    selection = candidate
    updateVisibility()
    return true
  }

  /// News-only updates do not reconcile owners or deliver visibility/reset effects.
  @discardableResult
  func refreshNews(_ snapshots: [NewsSnapshot]) -> Bool {
    guard !isRetired, !snapshots.isEmpty else { return false }
    selection.refreshNews(snapshots)
    return true
  }

  @discardableResult
  func reconcileWindow() -> Bool { adoptWindow(selection) }

  private func adoptWindow(_ candidate: FeedSelection) -> Bool {
    guard let index = candidate.index, let windowDidChange else { return true }
    let window = Array(
      candidate.cards[max(0, index - 1)...min(candidate.cards.count - 1, index + 1)])
    switch windowDidChange(window) {
    case .success(let prepared):
      runtimes = prepared
      return true
    case .failure:
      replenishmentMessage = "Could not prepare this game. Retry games, then swipe again."
      return false
    }
  }

  func commitPage(at index: Int, origin: FeedNavigationOrigin = .programmatic) {
    guard selection.cards.indices.contains(index), let current = selection.index,
      abs(index - current) == 1
    else { return }
    move(by: index - current, origin: origin)
  }

  func next() { move(by: 1) }
  func previous() { move(by: -1) }

  private func move(by offset: Int, origin: FeedNavigationOrigin = .programmatic) {
    guard canNavigate else { return }
    var candidate = selection
    guard candidate.move(by: offset), adoptWindow(candidate) else { return }
    selection = candidate
    updateVisibility()
    if origin == .physicalSwipe { physicalSwipeDidCommit?() }
  }

  private func updateVisibility() {
    let visibleID: CardID?
    if canNavigate, case .game(let game) = selectedCard {
      visibleID = game.id
    } else {
      visibleID = nil
    }
    // Invalidate and synchronously cancel old work before enabling another card.
    for (id, runtime) in runtimes where id != visibleID {
      runtime.setVisible(false)
    }
    if let visibleID { runtimes[visibleID]?.setVisible(true) }
    demandDidChange?()
  }
}

/// Feed presentation knows only whether an adjacent game window can be prepared.
enum FeedWindowError: Error { case preparationFailed }

/// Programmatic/menu movement never qualifies the owner-selected physical-swipe streak.
enum FeedNavigationOrigin { case physicalSwipe, programmatic }
