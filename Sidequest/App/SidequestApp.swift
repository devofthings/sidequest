import SwiftUI

@main
@MainActor
struct SidequestApp: App {
  @State private var session = SampleSession.make()

  var body: some Scene {
    WindowGroup {
      FoundationView(session: session)
    }
  }
}
