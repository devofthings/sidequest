import SwiftUI
import UIKit

struct FeedPageRequest: Equatable {
  let id = UUID()
  let step: Int
  let owner: ObjectIdentifier

  init(controller: FeedController, step: Int) {
    owner = ObjectIdentifier(controller)
    self.step = step
  }
}

/// The platform owns drag physics; the feed commits only a settled page.
@MainActor
struct VerticalFeedPager: UIViewControllerRepresentable {
  let controller: FeedController
  let request: FeedPageRequest?
  let reduceMotion: Bool
  let content: (FeedCard) -> AnyView

  func makeUIViewController(context: Context) -> FeedPagerController {
    FeedPagerController(controller: controller, content: content)
  }

  func updateUIViewController(_ pager: FeedPagerController, context: Context) {
    pager.update(content: content, request: request, reduceMotion: reduceMotion)
  }

  static func dismantleUIViewController(_ pager: FeedPagerController, coordinator: ()) {
    pager.stop()
  }
}

@MainActor
final class FeedPagerController: UIViewController, UIScrollViewDelegate {
  private let controller: FeedController
  private let pager = FeedPagingScrollView()
  private var content: (FeedCard) -> AnyView
  private var pages: [Int: FeedCardController] = [:]
  private var window: [Int] = []
  private var pageHeight: CGFloat = 0
  private var lastRequestID: UUID?
  private var isStopped = false
  private var suppressCompletion = false
  private var settledIndex: Int?

  init(controller: FeedController, content: @escaping (FeedCard) -> AnyView) {
    self.controller = controller
    self.content = content
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { nil }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    pager.isPagingEnabled = true
    pager.isDirectionalLockEnabled = true
    pager.showsVerticalScrollIndicator = false
    pager.showsHorizontalScrollIndicator = false
    pager.contentInsetAdjustmentBehavior = .never
    pager.delaysContentTouches = false
    pager.delegate = self
    pager.accessibilityIdentifier = "feed.pager"
    view.addSubview(pager)
    rebuildWindow()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let changed = pager.bounds.size != view.bounds.size
    pager.frame = view.bounds
    pageHeight = pager.bounds.height
    layoutPages()
    if changed { centerOnCommittedPage() }
  }

  func update(
    content: @escaping (FeedCard) -> AnyView, request: FeedPageRequest?, reduceMotion: Bool
  ) {
    guard !isStopped else { return }
    self.content = content
    loadViewIfNeeded()
    if settledIndex != controller.selectedIndex { rebuildWindow() }
    for (index, page) in pages {
      page.update(content(controller.cards[index]))
      page.view.accessibilityElementsHidden = index != controller.selectedIndex
      page.view.isUserInteractionEnabled = index == controller.selectedIndex
    }
    pager.isScrollEnabled = controller.canNavigate
    if !controller.canNavigate {
      lastRequestID = request?.id
      centerOnCommittedPage()
    }
    guard controller.canNavigate, let request, request.owner == ObjectIdentifier(controller),
      request.id != lastRequestID,
      let selected = controller.selectedIndex,
      let slot = window.firstIndex(of: selected + request.step), pageHeight > 0
    else { return }
    lastRequestID = request.id
    pager.setContentOffset(CGPoint(x: 0, y: CGFloat(slot) * pageHeight), animated: !reduceMotion)
    if reduceMotion { commitSettledPage() }
  }

  func stop() {
    isStopped = true
    pager.delegate = nil
    pager.isScrollEnabled = false
  }

  private func rebuildWindow() {
    guard let selected = controller.selectedIndex else { return }
    suppressCompletion = true
    let nextWindow = Array(max(0, selected - 1)...min(controller.count - 1, selected + 1))
    for (index, page) in pages where !nextWindow.contains(index) {
      page.willMove(toParent: nil)
      page.view.removeFromSuperview()
      page.removeFromParent()
      pages.removeValue(forKey: index)
    }
    for index in nextWindow where pages[index] == nil {
      let page = FeedCardController(content: content(controller.cards[index]))
      addChild(page)
      pager.addSubview(page.view)
      page.scroller.panGestureRecognizer.require(toFail: pager.panGestureRecognizer)
      page.didMove(toParent: self)
      pages[index] = page
    }
    window = nextWindow
    settledIndex = selected
    layoutPages()
    centerOnCommittedPage()
    suppressCompletion = false
  }

  private func layoutPages() {
    guard pageHeight > 0 else { return }
    pager.contentSize = CGSize(
      width: pager.bounds.width, height: pageHeight * CGFloat(window.count))
    for (slot, index) in window.enumerated() {
      pages[index]?.view.frame = CGRect(
        x: 0, y: CGFloat(slot) * pageHeight, width: pager.bounds.width, height: pageHeight)
    }
  }

  private func centerOnCommittedPage() {
    guard let selected = controller.selectedIndex, let slot = window.firstIndex(of: selected),
      pageHeight > 0
    else { return }
    suppressCompletion = true
    pager.setContentOffset(CGPoint(x: 0, y: CGFloat(slot) * pageHeight), animated: false)
    suppressCompletion = false
  }

  private func commitSettledPage() {
    guard !isStopped, !suppressCompletion, controller.canNavigate, pageHeight > 0 else { return }
    let slot = Int((pager.contentOffset.y / pageHeight).rounded())
    guard window.indices.contains(slot) else {
      centerOnCommittedPage()
      return
    }
    let index = window[slot]
    controller.commitPage(at: index)
    rebuildWindow()
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { commitSettledPage() }
  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { commitSettledPage() }
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate { commitSettledPage() }
  }
}

/// Each page owns exactly one content scroller, including at large text sizes.
@MainActor
private final class FeedCardController: UIViewController {
  let scroller = FeedCardScrollView()
  private let hosting: UIHostingController<AnyView>

  init(content: AnyView) {
    hosting = UIHostingController(rootView: content)
    hosting.sizingOptions = .intrinsicContentSize
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { nil }

  override func viewDidLoad() {
    super.viewDidLoad()
    scroller.contentInsetAdjustmentBehavior = .never
    scroller.bounces = false
    scroller.isDirectionalLockEnabled = true
    scroller.delaysContentTouches = false
    scroller.accessibilityIdentifier = "feed.cardScroll"
    view.addSubview(scroller)
    addChild(hosting)
    hosting.view.backgroundColor = .systemBackground
    hosting.view.translatesAutoresizingMaskIntoConstraints = false
    scroller.addSubview(hosting.view)
    NSLayoutConstraint.activate([
      hosting.view.leadingAnchor.constraint(equalTo: scroller.contentLayoutGuide.leadingAnchor),
      hosting.view.trailingAnchor.constraint(equalTo: scroller.contentLayoutGuide.trailingAnchor),
      hosting.view.topAnchor.constraint(equalTo: scroller.contentLayoutGuide.topAnchor),
      hosting.view.bottomAnchor.constraint(equalTo: scroller.contentLayoutGuide.bottomAnchor),
      hosting.view.widthAnchor.constraint(equalTo: scroller.frameLayoutGuide.widthAnchor),
      hosting.view.heightAnchor.constraint(
        greaterThanOrEqualTo: scroller.frameLayoutGuide.heightAnchor),
    ])
    hosting.didMove(toParent: self)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    scroller.frame = view.bounds
  }

  func update(_ content: AnyView) { hosting.rootView = content }
}

@MainActor
private final class FeedPagingScrollView: UIScrollView {
  private weak var touchedScroller: FeedCardScrollView?
  private var beganOnControl = false

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let hit = super.hitTest(point, with: event)
    if event?.type == .touches {
      touchedScroller = nil
      beganOnControl = false
      var ancestor = hit
      while let current = ancestor, current !== self {
        if current is UISlider { beganOnControl = true }
        if let child = current as? FeedCardScrollView { touchedScroller = child }
        ancestor = current.superview
      }
    }
    return hit
  }

  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard gestureRecognizer === panGestureRecognizer else {
      return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    let velocity = panGestureRecognizer.velocity(in: self)
    guard !beganOnControl, abs(velocity.y) > abs(velocity.x) * 1.2 else { return false }
    if let touchedScroller, touchedScroller.canConsume(verticalVelocity: velocity.y) {
      return false
    }
    return super.gestureRecognizerShouldBegin(gestureRecognizer)
  }
}

@MainActor
private final class FeedCardScrollView: UIScrollView {
  func canConsume(verticalVelocity: CGFloat) -> Bool {
    let end = max(0, contentSize.height - bounds.height)
    if verticalVelocity < 0 { return contentOffset.y < end - 1 }
    return contentOffset.y > 1
  }

  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard gestureRecognizer === panGestureRecognizer else {
      return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    let velocity = panGestureRecognizer.velocity(in: self)
    guard abs(velocity.y) > abs(velocity.x) * 1.2 else { return false }
    return super.gestureRecognizerShouldBegin(gestureRecognizer)
  }
}
