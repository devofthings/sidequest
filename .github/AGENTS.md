# GitHub automation

Read [CI.md](../docs/CI.md) before changing runner setup, workflow triggers, permissions, check names, or diagnostics. Issue #15 selects this Mac's repository-specific foreground self-hosted runner because GitHub currently charges nothing for self-hosted execution. No hosted fallback, unattended service, scheduler, cache/artifact upload, or paid activation is approved.

Verification checks out the exact same-repository PR head, requires current base ancestry, and reports `Sidequest / verification`. Keep actions pinned to reviewed immutable SHAs and permissions at `contents: read`. Fork code cannot run on this Mac; do not introduce `pull_request_target` or execute unreviewed external actions.

Cancel obsolete PR verification only. Keep main verification for every merged SHA so release task #31 can bind publication to the exact successful commit. Release automation remains outside issue #15.
