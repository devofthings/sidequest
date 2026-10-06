# Sidequest launch identity

The owner selected a static system launch screen and removal of the custom introduction in [#215](https://github.com/devofthings/sidequest/issues/215), then authorized implementation on October 6, 2026. The original selected Card S icon and byte-identical `StartupLogo` remain unchanged.

## Static launch and app canvas

Both Debug and Release Info inputs name `LaunchScreen` through `UILaunchStoryboardName`. The filesystem-synchronized resource folder supplies its launch storyboard, with the existing logo centered at 120×120 points. The owner's October 6 correction #226 selects `LaunchPurple`, original Card S background sRGB #653BE8, across the entire native launch screen in light and dark. `LaunchCanvas` remains neutral #F7F7F8/#111114 for the SwiftUI root and safe areas underneath preparation, failure/retry, and ready content. Launch purple does not recolor app utilities. Debug keeps its Files keys; generated metadata, signing, and app icon settings stay intact.

The system owns launch-screen duration. There is no custom SwiftUI logo overlay, artificial hold, opacity fade, animation state owner, or persisted launch preference. Preparation and foreground news refresh retain their existing owners. Loading errors and Retry remain ordinary app content. No game begins until meaningful input; returning to the foreground never displays an app-owned splash. Static logo geometry does not depend on Dynamic Type or Reduce Motion.

Apple's [launching guidance](https://developer.apple.com/design/human-interface-guidelines/launching) recommends matching the initial app background and current appearance. The bounded owner-selected logo treatment uses a storyboard so its size and centering remain explicit across devices; it adds no animated launch behavior or dependency.

## Agent-grill readiness self-assessment

| Question | Kind | Selected answer | Evidence and rationale | Verification needed |
| --- | --- | --- | --- | --- |
| Keep a custom animated introduction? | Owner decision | Remove it. | #215 and October 6 implementation authorization supersede #91/#192. | Cold launch and foreground observation; inspect source for obsolete owner. |
| How is fixed logo geometry expressed? | Technical choice | Static launch storyboard, centered 120-point logo. | Existing named artwork and adaptive color; Auto Layout fixes bounds without an app lifecycle owner. | Compile Debug/Release storyboard, inspect built metadata/resources and light/dark appearance. |
| Which canvas? | Owner decision | Full-screen logo purple #653BE8 for launch; neutral adaptive canvas for app utilities. | October 6 #226 correction supersedes #215's neutral launch treatment. Original logo SVG provides the exact color. | Resolve compiled catalog/storyboard colors in both appearances and inspect fresh installation. |
| Preserve preparation and game activation? | Fact and boundary | Keep original session tasks, error/retry, and first-input policy. | Only remove the decorative wrapper; retain its root background directly. | Units, routine smoke, cold/foreground real Sudoku input, largest text and native Reduce Motion. |

## Verification and personal testing

`StaticLaunchBundleTests` verifies the compiled launch name/storyboard, actual image, centered 120-point bounds, and resolved purple catalog colors in both appearances. `StaticLaunchFlowTests` retains cold-launch/foreground and actual native Reduce Motion checks, and adds largest-text coverage. The three-case routine smoke gate remains unchanged. Actual compiled/native/CI execution results are recorded in [PR #227](https://github.com/devofthings/sidequest/pull/227); the earlier neutral treatment was verified in [PR #222](https://github.com/devofthings/sidequest/pull/222); source configuration and test definitions alone do not establish successful execution. Source XML/JSON validation and strict formatting establish source validity only.

The lead must inspect actual Debug and Release Info, compiled storyboard/assets and icon metadata, then fresh-install cold launch in light and dark to avoid cached launch snapshots. Observe direct transition to real content, no second custom logo, inactive games, and ordinary first input. No second main build or release publication follows this ticket.

For iPhone review use `codex/226-purple-launch` and [free Personal Team installation](../INSTALL.md#install-on-your-own-iphone). Run from Xcode, then close and open from the Home Screen in light/dark; confirm one static logo and direct content transition, first interaction starts/applies, and background/foreground keeps feed position without a custom splash. Existing seven-day reinstallation applies. Physical-device appearance, iOS 17, and VoiceOver remain unverified until actual testing.

## Historical policy

#181 originally configured a tinted background-only system screen and #91 supplied a separate custom logo. #192 changed that decoration to a 150 ms hold and 450 ms fade. #215 supersedes both the tinted canvas and custom introduction; historical installation evidence remains in INSTALL.md and does not certify the new treatment.
