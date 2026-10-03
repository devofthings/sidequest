import Observation

@MainActor
@Observable
final class FeedController {
  private var selection: FeedSelection
  private var sceneIsActive = false
  private var hostIsAvailable = true
  private var isRetired = false
  let runtimes: [CardID: GameRuntime]

  var cards: [FeedCard] { selection.cards }
  var selectedIndex: Int? { selection.index }
  var canNavigate: Bool { sceneIsActive && hostIsAvailable && !isRetired }

  var selectedCard: FeedCard? { selection.card }
  var position: Int? { selection.index.map { $0 + 1 } }
  var count: Int { selection.cards.count }
  var canGoBack: Bool { selection.canGoBack }
  var canGoForward: Bool { selection.canGoForward }

  init(cards: [FeedCard], runtimes: [CardID: GameRuntime]) {
    // DeckBuilder has already validated card identity. Missing adapters are a
    // composition error, rather than a game that silently accepts no input.
    precondition(
      cards.allSatisfy { card in
        if case .game(let game) = card { return runtimes[game.id] != nil }
        return true
      }, "Every game card needs a retained runtime.")
    selection = FeedSelection(cards: cards)
    self.runtimes = runtimes
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
    updateVisibility()
  }

  func commitPage(at index: Int) {
    guard selection.cards.indices.contains(index), let current = selection.index,
      abs(index - current) == 1
    else { return }
    move(by: index - current)
  }

  func next() { move(by: 1) }
  func previous() { move(by: -1) }

  private func move(by offset: Int) {
    guard canNavigate, selection.move(by: offset) else { return }
    updateVisibility()
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
  }
}
