# Sidequest launch identity

The owner approved integrating the logo, splash treatment, and app design on October 5, 2026 in [#181](https://github.com/devofthings/sidequest/issues/181). The selected original Card S icon and byte-identical `StartupLogo` remain the identity. The existing #91 SwiftUI introduction supplies the brief decorative splash after process launch.

## Static launch and app canvas

The system launch screen uses only the `LaunchCanvas` background from the asset catalog. Any appearance is sRGB `#F5F3FF`; Dark is `#101427`, matching the current shared theme. The same named color fills the root SwiftUI view and safe areas underneath loading, failure, and ready states. Loading/error titles use rounded system type; Retry reuses the existing prominent accessible button style.

Both Debug and Release explicitly define `UILaunchScreen` → `UIColorName` in their input Info plists, alongside generated app metadata. Debug keeps its existing Files keys; Release's minimal plist contains only the launch dictionary. Empty generated launch-screen configuration is removed. No storyboard, launch text, fixed system logo, additional asset rendering, or new dependency is required.

Apple's [launching guidance](https://developer.apple.com/design/human-interface-guidelines/launching) recommends a launch surface matching the first app surface and current appearance. Its [UILaunchScreen reference](https://developer.apple.com/documentation/bundleresources/information-property-list/uilaunchscreen) supports dictionary configuration without a storyboard; [UIColorName](https://developer.apple.com/documentation/bundleresources/information-property-list/uilaunchscreen/uicolorname) resolves a named catalog color. These official DocC sources were read on October 5, 2026. The background-only choice follows that guidance while the existing native introduction remains separate from the system launch screen.

## Preserved introduction behavior

The retained App owner still permits an 80 ms visible phase and 350 ms contained opacity/scale fade, once per cold process. Preparation runs independently. Reduce Motion omits the decoration; background, disappearance, and cancellation finish it permanently. Retry/import/foreground cannot replay it. The image remains accessibility hidden and never captures input, starts a game, or sends haptics. `StartupIntroduction` and its existing model/UI assertions are unchanged.

## Verification and handoff

Author source checks validate both input XML plists, project syntax, named-color JSON components, selected image byte identity, strict Swift formatting, and documentation/statistics. They establish no compiled resources or measured launch appearance.

Root must verify actual Debug and Release `Info.plist` contain `UILaunchScreen = { UIColorName = LaunchCanvas; }`, retain normal bundle/icon metadata, and preserve Debug-only Files keys. Inspect the compiled catalog and actual resolved light/dark colors; record fresh-install cold launch on owned small/larger simulators in light/dark and system Reduce Motion as proportionate. Inspect startup transitions for unrelated background flashes and verify existing startup UI flows, all units, required smoke, and exact-head free CI before fresh-review merging. Initial system launch snapshots may be cached; fresh installation is part of appearance evidence. No second main check or release publication follows this ticket.

For personal testing, use branch `codex/181-branded-launch` and [free Personal Team installation](../INSTALL.md#install-on-your-own-iphone). Launch from the Home Screen in light and dark appearances, verify the selected icon and brief logo, and confirm Tap to play remains required immediately after launch and foreground return. Enable system Reduce Motion and repeat. Physical-device/iOS 17 execution and device VoiceOver remain unverified at author handoff.
