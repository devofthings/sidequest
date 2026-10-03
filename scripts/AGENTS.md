# Repository tooling

Keep hook installation explicit and limited to the current clone's local Git configuration. Preserve an existing hooks path unless it already selects Sidequest hooks. Hook setup is separate from formatting, builds, and app implementation; see [FORMATTING.md](../docs/FORMATTING.md).

Run the tooling integration checks after changing hook or installer behavior. Their temporary repositories must remain outside the project checkout; preserve the author's index, working tree, and Git configuration.
