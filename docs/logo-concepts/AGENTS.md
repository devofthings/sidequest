# Logo concept ownership

- Preserve selected A — Card S under [owner approval](https://github.com/devofthings/sidequest/issues/14#issuecomment-5990513554). Read [identity and production guidance](README.md) before changing the icon. B and C remain unselected alternatives; changes to the selected identity need new owner steering.
- Preserve editable, original SVG geometry and accessible title/description metadata. Review PNGs are derived previews; SVGs own the artwork. Keep the provenance and reproduction instructions current when geometry changes.
- Use the existing local Node.js/Sharp renderer for proof images. This is a delegated implementation choice to make original SVGs reviewable without a new dependency, account, or charge. It is unrelated to native app verification.
- Render the selected opaque 1024-pixel Any asset through `render-icon.cjs`. Use the system's automatic dark/tinted treatments as documented in the identity guidance; actual Home Screen appearance checks remain a lead-owned merge gate. The [selected MVP visual baseline](../DESIGN.md) guides coherence; purple is accepted for the icon background.
