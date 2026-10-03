# Repository tooling

Keep hook installation explicit and local to the current clone or worktree. Preserve an existing hooks path unless it already selects Sidequest hooks. The installer may use the recognized Tokensave repository-hook forwarder through a local dispatcher, preserving global configuration and other hooks. Refuse unknown hooks paths and existing repository hooks that need reconciliation. Hook setup is separate from formatting, builds, and app implementation; see [FORMATTING.md](../docs/FORMATTING.md).

Run the tooling integration checks after changing hook or installer behavior. Their temporary repositories must remain outside the project checkout; preserve the author's index, working tree, and Git configuration.
