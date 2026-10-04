import SwiftUI

/// Reserves the natural size of every supported message at the current width and text size.
@MainActor
struct StableGameRegion<Content: View, Reservation: View>: View {
  private let content: Content
  private let reservation: Reservation

  init(
    @ViewBuilder reserving reservation: () -> Reservation,
    @ViewBuilder content: () -> Content
  ) {
    self.reservation = reservation()
    self.content = content()
  }

  var body: some View {
    ZStack(alignment: .top) {
      reservation
        .hidden()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
      content
    }
    .fixedSize(horizontal: false, vertical: true)
  }
}
