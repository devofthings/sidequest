# GitHub automation

Read [CI.md](../docs/CI.md) before changing runner setup, workflow triggers, permissions, check names, or diagnostics. Issue #15 selects this Mac's repository-specific foreground self-hosted runner because GitHub currently charges nothing for self-hosted execution. No hosted fallback, unattended service, scheduler, cache/artifact upload, or paid activation is approved.

Verification checks out the exact same-repository PR head, requires current base ancestry, and reports `Sidequest / verification`. Keep actions pinned to reviewed immutable SHAs and verification permissions at `contents: read`. Fork code cannot run on this Mac; do not introduce `pull_request_target` or execute unreviewed external actions.

Cancel obsolete PR verification only. The main-only [release workflow](../docs/RELEASES.md) retains exact-commit `Sidequest / verification` for every merged SHA, then publishes on the same foreground runner only after success. Only publishing receives `contents: write` plus read permissions needed to verify run/check identity. Unique label `sidequest-mac-foreground`, API runner-ID checks, and local manifest validation prevent a different-host handoff; no upload fallback is approved.

Issue #31 selects full-SHA preview tags and draft-first complete assets because retries must preserve original release identity/bytes. Never overwrite assets/tags or publish a failed/incomplete build. Its first contribution stays partial until actual first/second main releases prove history. Follow [release guidance](../docs/RELEASES.md) before publication, retries, or cost changes.
