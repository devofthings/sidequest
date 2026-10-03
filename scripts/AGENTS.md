# Repository tooling

Keep hook installation explicit and local to the current clone or worktree. Preserve an existing hooks path unless it already selects Sidequest hooks. With no configured hooks path, refuse installation if executable native hooks would be disabled; resolve their directory through Git so linked worktrees preserve shared hooks too. Sample files are inactive and do not block setup. The installer may use the recognized Tokensave repository-hook forwarder through a local dispatcher, preserving global configuration and other hooks. Refuse unknown hooks paths and existing repository hooks that need reconciliation. Hook setup is separate from formatting, builds, and app implementation; see [FORMATTING.md](../docs/FORMATTING.md).

Run the tooling integration checks after changing hook or installer behavior. Their temporary repositories must remain outside the project checkout; preserve the author's index, working tree, and Git configuration.

Agent preflight is read-only: report missing tools, checkout ownership prerequisites, repository identity, review skill, formatting setup, and hook wiring without installing dependencies, modifying Git configuration, or checking account billing through an invented CLI. Follow [agent setup](../docs/AGENT_SETUP.md); included usage remains a separate account-tool check. Test preflight with isolated repositories and stub external tools.

For review/verification gate changes, follow [REVIEW_GATES.md](../docs/REVIEW_GATES.md) and run `python3 scripts/test-review-gate.py`. Keep default execution read-only, receipt commands as evidence rather than executable input, and all live mutations explicit. Preserve CI verification ownership and the documented API atomicity limits; fixtures use fake GitHub and isolated temporary Git repositories.

Gate receipts distinguish complete issues from partial contributions under [completion semantics](../docs/REVIEW_GATES.md#prepare-the-receipt). Complete remains the backwards-compatible default. Explicit partial receipts require the same open issue reference and reject its closing references, so recording a decision cannot complete deferred parent work.
