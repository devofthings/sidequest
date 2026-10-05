# Sidequest icon proposals

Status: **A — Card S selected**, October 5, 2026. The owner replied “go ahead” after the recommended direction was presented; see [recorded approval](https://github.com/devofthings/sidequest/issues/14#issuecomment-5990513554). Its recognizable S at small sizes and vivid purple/lime palette are the selected rationale. B and C remain unselected alternatives. The app icon is integrated in this feature branch; actual CI and simulator appearance verification remain pending.

![Three Sidequest icon proposals, with 256, 64, 40, and 24 pixel samples](size-proof.png)

View the sheet at 100% to inspect its actual small samples. Each SVG has a 1024 × 1024 canvas; individual PNG previews are 256 × 256 review images, not production assets.

## Directions

| Proposal | Idea | Editable master | Main tradeoff |
| --- | --- | --- | --- |
| A — Card S | A chunky lime S over a tilted lavender feed card. The strongest direct connection to the name. | [card-s.svg](card-s.svg) | The lavender card becomes a subtle rim at 24 px; the S remains dominant. |
| B — Sidepath | A thick route branches toward a coral destination: a short diversion from the feed. | [sidepath.svg](sidepath.svg) | The silhouette is clear at 24 px, but can resemble a lowercase h; its meaning needs the Sidequest name. |
| C — Mixed Deck | A lime reading card overlaps a coral playing card, expressing news plus games. | [mixed-deck.svg](mixed-deck.svg) | Most explicit product meaning; the smaller card details lose definition at 24 px. |

**Selected: A — Card S.** Its simple S survives reduction and provides a recognizable name cue. B emphasizes curiosity, and C emphasizes the mixed feed. The comparison sheet preserves the original proposal labels as historical exploration. The [earlier branching-card proposal](../design/LOGO.md) is superseded by Card S.

## References and originality

The owner's issue brief names [Picnic's official website](https://www.picnic.photos/) and [its App Store listing](https://apps.apple.com/us/app/photo-organizer-picnic/id6450713784). The publisher presents swipe-based sorting as a playful activity. We use that broad energy and the owner's purple/lime, chunky-shape brief; no Picnic icon, screenshot, tracing, or downloaded artwork is included.

The palette relates to the selected [MVP design](../DESIGN.md): lime, lavender, and coral, with an exploratory saturated purple icon background. Purple is selected for the icon background; shared app tokens are unchanged. All shapes, coordinates, and SVG paths were authored for Sidequest in this branch. There are no external fonts, symbols, embedded images, or AI-generated raster inputs.

## Selected production composition

[Apple's app-icon guidance](https://developer.apple.com/design/human-interface-guidelines/app-icons/) recommends a simple, unique core idea with few shapes and a 1024 × 1024 iPhone canvas. The system applies the corner mask. These masters therefore use a full square, opaque background without a baked outer corner radius; foreground shapes stay away from the edges.

The existing asset catalog now contains [AppIcon](../../Sidequest/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json), with a single opaque 1024 × 1024 sRGB PNG rendered directly from the selected SVG. The app Debug and Release configurations name this icon set; signing settings and target membership are unchanged.

Dark and tinted icons use the system's automatic treatment, explicitly supported by [Apple's asset-catalog guide](https://developer.apple.com/documentation/xcode/configuring-your-app-icon?changes=_3). This keeps one selected identity across iOS versions and avoids introducing unapproved custom colors. No separate dark/tinted bitmap or Icon Composer document is required for this selected route. The raster proof sheet does not establish the actual system treatments: install and inspect the Home Screen's light, dark, and tinted styles before merging. Clear styles use system handling where supported and are not a separately authored variant. Physical-device and iOS 17 execution remain unverified.

## Actual checks and reproduction

The three SVGs were rendered locally using the already available Node.js runtime and Sharp library, without package installation, a service account, or paid generation. The resulting sheet was visually inspected: every primary silhouette remains distinct at 64 and 40 px; A is the clearest name cue at 24 px. B's h-like interpretation and C's reduced detail remain design tradeoffs, not hidden results.

The scoped renderer reproduces the three individual PNG previews and the size sheet:

```sh
NODE_PATH=<existing-node_modules-directory> node docs/logo-concepts/render.cjs
```

Run from the repository root with an existing Node.js/Sharp environment. Obtain the host's bundled paths through Codex's workspace-dependencies tool; no repository dependency is added. SVG XML parsing, canvas/background checks, PNG dimensions, and repository documentation checks are reported in the PR. Actual platform appearance validation remains a lead-owned merge gate.

### Agent-grill self-assessment

| Question | Kind | Settled answer or pending choice | Evidence and verification |
| --- | --- | --- | --- |
| Can we create editable originals without paid generation? | Delegated technical choice | Author simple SVG geometry and render with the existing Sharp library. | The bundled library resolved locally; all three SVGs rendered successfully and their small samples were inspected. |
| Is final branding selected by the lead's general design authority? | Human-owned decision | A — Card S approved by the owner. | The October 5 reply and linked issue approval select the recommended direction. |
| How should production appearance variants work? | Delegated technical choice | Use the selected opaque Any icon and the system's automatic dark/tinted treatment. | Apple explicitly supports this route; actual Home Screen inspection remains pending before merge. |

### Produce the selected app asset

```sh
NODE_PATH=<existing-node_modules-directory> node docs/logo-concepts/render-icon.cjs
```

The scoped command reads `card-s.svg` and writes only the selected catalog's `AppIcon.png`. The editable master and original geometry remain unchanged. This is local vector rendering without AI raster generation, a new dependency, or a paid service. The production PNG is 1024 × 1024, RGB, sRGB, and fully opaque; no corner mask is baked into it.
