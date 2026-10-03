# Agent checkout setup

Use this procedure at chat startup and before handing a checkout to another agent. This is local preparation authorized by the user on October 3, 2026; app implementation and scheduling remain on hold.

## Isolate and synchronize

1. Inspect `git status --short --branch` and the active agent's checkout ownership. Preserve existing work. A dirty or stale shared checkout is not a safe place to switch branches or install tooling.
2. Check included Codex allowance with the account tool under [the spending rule](../AGENTS.md#spending-approval), then check the [PR handoff queue](REVIEW.md#review-handoff-queue) and assigned issue. The preflight CLI cannot check account billing or lift the app hold.
3. Fetch current refs with `git fetch origin`. For a new issue, create an isolated worktree from `origin/main`, for example `git worktree add -b codex/62-agent-bootstrap /private/tmp/sidequest-62-agent-bootstrap origin/main`. Use the actual assigned issue number and a fresh path; continuing an existing PR starts from its current feature branch instead. Record checkout path, branch, issue, agent identity, and ownership in the lead's handoff. Assign one editing agent per checkout; reviewers inspect explicit commit targets or receive their own isolated checkout.
4. Read applicable guidance in that checkout. The canonical Sidequest review skill is [my-review](../.agents/skills/my-review/SKILL.md), tracked with the project. Agents read it directly even if the host's skill catalog has not refreshed; an external skill installation is unnecessary.
5. Install commit checks explicitly with `bash scripts/install-git-hooks.sh` from the isolated checkout. The installer preserves recognized existing hook chains and refuses unknown hooks requiring reconciliation; follow [hook setup](FORMATTING.md#install-commit-checks). In linked worktrees, Git configuration may be shared: do not switch an unknown shared hooks path or change global configuration. The preserved forwarding path uses a dispatcher in the current worktree's Git directory.
6. Run `python3 scripts/agent-preflight.py` from the checkout. All applicable checks must pass before assigning edits. Failures require the reported correction; the check installs nothing, changes no Git configuration, and leaves existing work intact.

A fresh checkout may inherit Git configuration from its parent repository, but never assume hooks are operational: verify every checkout. Feature branches and current `origin/main` protect isolation; pending reviews must still be refreshed if either PR commit changes. Preflight checks tools, repository identity, branch, cleanliness, skill, formatter/configuration, GitHub access, and actual recognized hook wiring. It does not prove issue authorization, supported app toolchain selection, a completed review, or merge readiness.

## Verify preparation tooling

After changing preflight behavior, run `python3 scripts/test-agent-preflight.py`. Its isolated repositories and stub GitHub/Xcode tools cover successful setup, failures, hook forwarding, and preservation of checkout contents. Hook or installer changes also require `python3 scripts/test-git-hooks.py`. App builds and gameplay tests remain unavailable until issue #1 establishes the foundation.

Run preflight on a clean checkout before edits and after the final commit. A failed cleanliness check during implementation is expected; preserve the changes and finish the authorized work before repeating the readiness check. For missing credentials or other human-owned blockers, use the [unanswered decision workflow](WORKFLOW.md#unanswered-decision-requests).
