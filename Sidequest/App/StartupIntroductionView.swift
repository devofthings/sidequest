import SwiftUI

@MainActor
struct StartupIntroductionView<Content: View>: View {
  let introduction: StartupIntroduction
  let content: Content
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    content
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color("LaunchCanvas").ignoresSafeArea())
      .overlay {
        if introduction.isShowing, !reduceMotion {
          Image("StartupLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .opacity(introduction.phase == .visible ? 1 : 0)
            .animation(.easeInOut(duration: 0.45), value: introduction.phase)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
      }
      .task(id: introduction.isFinished) {
        await introduction.present(reduceMotion: reduceMotion)
      }
      .onChange(of: scenePhase) { _, phase in
        if phase == .background { introduction.dismiss() }
      }
      .onChange(of: reduceMotion) { _, reduced in
        if reduced { introduction.dismiss() }
      }
      .onDisappear { introduction.dismiss() }
  }
}
