import SwiftUI

/// Presentation-only palette shared by card chrome and game surfaces.
struct SidequestTheme {
  let scheme: ColorScheme
  let contrast: ColorSchemeContrast

  var canvas: Color { scheme == .dark ? Self.color(0x101427) : Self.color(0xF5F3FF) }
  var surface: Color { scheme == .dark ? Self.color(0x1B2037) : .white }
  var ink: Color { scheme == .dark ? Self.color(0xF8FAFC) : Self.darkInk }
  var secondaryInk: Color { scheme == .dark ? Self.color(0xCBD5E1) : Self.color(0x475569) }
  var border: Color { contrast == .increased ? ink : secondaryInk.opacity(0.3) }
  var borderWidth: CGFloat { contrast == .increased ? 2 : 1 }

  static let darkInk = color(0x111827)
  static let lime = color(0xC5F36B)
  static let lavender = color(0xC4B5FD)
  static let coral = color(0xFDA4AF)
  static let cyan = color(0x67E8F9)

  private static func color(_ value: UInt32) -> Color {
    Color(
      .sRGB, red: Double((value >> 16) & 255) / 255,
      green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, opacity: 1)
  }
}

/// Press transforms stay inside the control footprint and never own eligibility.
struct SidequestButtonStyle: ButtonStyle {
  var prominent = false
  var compact = false
  @Environment(\.colorScheme) private var scheme
  @Environment(\.colorSchemeContrast) private var systemContrast
  @Environment(\.sidequestContrast) private var contrastOverride
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @Environment(\.sidequestReduceMotion) private var motionOverride
  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    let contrast = contrastOverride ?? systemContrast
    let reduceMotion = motionOverride ?? systemReduceMotion
    let theme = SidequestTheme(scheme: scheme, contrast: contrast)
    configuration.label
      .font(.headline)
      .padding(.horizontal, compact ? 0 : (prominent ? 20 : 12))
      .padding(.vertical, compact ? 0 : (prominent ? 12 : 8))
      .frame(minHeight: 44)
      .foregroundStyle(prominent ? SidequestTheme.darkInk : theme.ink)
      .background(prominent ? SidequestTheme.lime : theme.surface)
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .overlay {
        RoundedRectangle(cornerRadius: 16)
          .strokeBorder(
            prominent ? SidequestTheme.darkInk : theme.border, lineWidth: theme.borderWidth)
      }
      .brightness(configuration.isPressed ? -0.06 : 0)
      .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
      .opacity(isEnabled ? 1 : 0.65)
      .animation(reduceMotion ? nil : .smooth(duration: 0.14), value: configuration.isPressed)
  }
}

// Read-only system preferences need writable presentation overrides across separate hosting roots.
private struct SidequestContrastKey: EnvironmentKey {
  static let defaultValue: ColorSchemeContrast? = nil
}

private struct SidequestReduceMotionKey: EnvironmentKey {
  static let defaultValue: Bool? = nil
}

extension EnvironmentValues {
  var sidequestContrast: ColorSchemeContrast? {
    get { self[SidequestContrastKey.self] }
    set { self[SidequestContrastKey.self] = newValue }
  }

  var sidequestReduceMotion: Bool? {
    get { self[SidequestReduceMotionKey.self] }
    set { self[SidequestReduceMotionKey.self] = newValue }
  }
}
