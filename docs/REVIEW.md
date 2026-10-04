# Fresh-agent review and merging

The user authorizes agents to commit and push feature branches and merge PRs after this loop passes. All repository changes, including documentation, use feature branches and PRs. Direct commits or pushes to `main` are prohibited.

## Delegated review responsibilities

Use a fresh subagent for ticket-readiness/spec checks and PR code reviews when the active lead can delegate. Ticket review checks accepted scope, dependencies, acceptance criteria, and feasible verification; it does not approve a feature idea or replace the later PR review. PR reviewers use the `my-review` skill and exact targets under the loop below.

Dispatch a review as soon as its bounded result is ready and commits are captured. Give the reviewer the originating issue, applicable guidance, verification responsibilities, and an explicit read-only or isolated mutation scope. The lead can perform independent authorized work while review runs. Separate ready PRs may be reviewed in parallel when allowance and isolation permit; shared checkout changes must not affect the review's target or fixtures. Recheck all head/base evidence before merge, including after another PR merges.

The reviewer owns substantive standards/spec findings. The lead owns coordination, assigning fixes, assessing reported evidence, and rechecking authorization and merge gates; it may delegate actual validation to a reviewer or validation agent. Require exact commands/results against the reviewed target and keep unavailable checks explicit. Do not add a duplicate full lead code review after a clean fresh review. Fixes still require another new reviewer, and a reviewer's proposed product changes remain unapproved Ideas.

Apply the included-usage and spending rules before dispatch. When no eligible fresh reviewer can run, use the handoff queue instead of author self-certification. These responsibilities add no recurring execution or cross-chat messaging authorization.

## Review handoff queue

`review-needed` marks an open, non-draft PR ready for independent review or a new round. Keep the originating issue in the Project's Review column. A label is a durable queue entry, not a background worker: pickup occurs when an authorized lead chat is active. Recurring pickup requires separately authorized scheduling and the project's spending and usage checks.

1. **Author handoff:** After verification, apply `review-needed` and put a handoff in the PR body or a linked PR comment: originating issue, exact current head/base commits, validation commands/results and unavailable checks, author chat identity or context, and the reason an independent reviewer is needed. Set `Sidequest / independent review` pending on the current head. If this chat cannot dispatch a reviewer, finish with the PR URL and waiting state; leave merging pending. Author self-review does not satisfy the gate.
2. **Lead pickup:** At chat startup and after the after-ticket chat checkpoint, inspect all open non-draft PRs before selecting new work. Inspect labeled PRs first, then ready PRs missing the label so older work is discoverable. Read the issue, handoff, latest comments, and live head/base; add the label if a review handoff is missing. Drafts and incomplete implementation stay with their author rather than being certified as ready. Confirm current start authorization and respect usage/spending limits.
3. **Claim and dispatch:** Check for an active claim in the PR audit before dispatching. Record lead/reviewer identity, time, and exact head/base in a PR comment, then run the review loop below with a fresh agent. Keep the queue label while review or fixes are underway. A claim prevents duplicate work by convention; GitHub comments provide no exclusive lock. Recheck comments and commits before recording gates or merging. If a claim is interrupted, record its release and checkpoint; a later lead must confirm it is inactive before replacing it.
4. **Requeue or finish:** Findings, failed verification, or changed head/base leave the PR open with its current review state and next action recorded. Changes invalidate existing evidence and require a new fresh round. After a verified merge or intentional closure, remove `review-needed` and update the issue/Project according to its completion criteria. A restricted chat may execute an independent review directly when it did not implement or fix the change, using the same skill and commit-bound evidence; another lead can record the gates and merge.

Use GitHub for the handoff so it survives chat boundaries. Messaging another Codex chat requires explicit user authorization; a queue label does not authorize a message or create a new chat. If no capable lead is running, checkpoint the queued PRs and resume pickup in a later authorized run. Do not claim continuous monitoring from these instructions.

To inspect the queue and older unlabeled work:

```sh
gh pr list --repo devofthings/sidequest --state open --limit 1000 --json number,title,isDraft,labels,headRefOid,url
```

The list limit is bounded; paginate through the API if the repository exceeds it. For a review handoff, capture both commits with `gh pr view <number> --repo devofthings/sidequest --json headRefOid,baseRefOid`.

## Review loop

1. Finish the bounded change on its feature branch, run proportionate verification, and open a PR with the originating GitHub issue and evidence. Read applicable `AGENTS.md` files and the issue's acceptance criteria. Use a closing reference only when the issue is complete. A partial contribution names its precise approved scope and explicitly references the parent without closing it; follow [receipt completion semantics](REVIEW_GATES.md#prepare-the-receipt).
2. Capture the PR number, current head commit, and base commit. Dispatch a new reviewer agent that did not implement the change. Give it the explicit PR target and originating issue, and require the user's `my-review` skill. The canonical tracked version is [SKILL.md](../.agents/skills/my-review/SKILL.md); read it directly from the reviewed checkout or commit. Review the diff against that issue and Sidequest guidance; the repository uses GitHub Issues rather than Linear. Review the raw diff unless a review worktree is explicitly authorized. If the skill is unavailable, report the missing dependency rather than silently substituting a review.
3. Have the reviewer report Bugs, Minors, Nits, and Prefs in the skill's format. An empty finding set is the clean-review result. The orchestrator records the reviewer identity and reviewed head/base commits separately from the findings.
4. Assign a fixing agent to address every finding on the feature branch. The fresh reviewer may make fixes when it has an authorized worktree; otherwise the implementation agent applies them. Record the resolution of each finding and rerun affected verification. A disputed finding needs a fresh review with concrete evidence; it cannot be silently dropped.
5. After fixes, dispatch another new reviewer for the complete current diff. Repeat until no findings remain and verification passes. Changes to the PR head or base invalidate the previous review/verification evidence. A reviewer that fixed code cannot certify those fixes as the final independent reviewer.
6. Before merging, recheck the current head/base, issue scope, check results, mergeability, and unresolved review findings. Publish the gates below only when the evidence is complete. If a check cannot run or review cannot converge, keep the PR open, record the cause, and continue independent work; a clean review is not proof that a build passed.
7. Use native GitHub auto-merge when supported, with the reviewed head pinned: `gh pr merge <number> --repo devofthings/sidequest --squash --auto --match-head-commit <reviewed-head-sha>`. Enable it only after the independent review and verification pass. If native auto-merge is unavailable, the orchestrator may use the same command without `--auto` after those gates pass. This is an agent-controlled merge, not server-enforced protection; never use an administrator bypass.
8. Verify the merge metadata and, under #112, absence of an automatic main run; do not dispatch a second test/build check. Close only completed issues, update Project status, and promote dependents whose prerequisites are complete. Complete the [after-ticket chat checkpoint](../AGENTS.md#after-ticket-chat-checkpoint) before starting or assigning the next issue. Research recommendations, provider selections, final branding, and personal testing remain subject to their issue's completion criteria.

## Commit-bound gates

- **Sidequest / independent review:** The orchestrator records a pending commit status when review starts and success only after a fresh reviewer returns no findings for the current head and base. Keep a PR-linked audit record of the reviewed commits, reviewer, rounds, and resolutions. A new commit or base change requires another round.
- **Sidequest / verification:** Record actual validation commands and results against the same commits. Until an executable app exists, documentation links and diff checks are appropriate and must be labeled as documentation verification. Once CI exists, the CI job owns this gate and must run the foundation's build/test commands for applicable changes. Verify all relevant checks, not just these names.

Agents share the user's GitHub credentials. A separate subagent review does not constitute approval from another GitHub account. Use the review status gate rather than configuring a required human approval that the same account cannot supply. These statuses record the orchestrator's evidence; they are not independent GitHub identities or proof of infallible review.

## Repository gate commands

Execute the [tracked review gates](REVIEW_GATES.md) after fresh review and actual verification. `python3 scripts/review-gate.py <receipt.json>` validates without mutation; explicit `--record` publishes evidence and `--merge` rechecks before a pinned squash merge. Use its target-bound receipt, documented CI ownership, and API race limits instead of temporary helpers. A failed command leaves the next action pending.

## GitHub enforcement

The user chose to proceed without a GitHub plan upgrade or main branch protection, recorded in [issue #23](https://github.com/devofthings/sidequest/issues/23). Keep the repository private and follow the feature-branch, review, verification, and agent-controlled merge process above. These instructions and commit statuses do not provide server enforcement or prevent another client from pushing. Revisit branch protection only when the user requests it.

GitHub reported on October 3, 2026 that private-repository protection and rulesets require Pro or a higher eligible plan. Native auto-merge has the same private-repository plan prerequisite and remains disabled; use the orchestrator fallback in step 7. [GitHub protection availability](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches), [auto-merge availability](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/automatically-merging-a-pull-request).

[CI verification](CI.md) owns `Sidequest / verification` using the approved foreground repository-specific self-hosted Mac runner. Require the actual successful check-run URL and exact reviewed head; stale, failed, pending, canceled, or skipped checks block merging. Before running CI or any other service that could incur charges, apply the spending approval rule in [AGENTS.md](../AGENTS.md): verify free execution or obtain explicit user approval.

Routine verification is PR-only under the owner's October 4 #112 decision. Exact-head CI and independent review remain merge prerequisites; no automatic main workflow or substitute manual check follows a merge. Release dispatch needs explicit owner publication authorization and its separate [manual verification gates](RELEASES.md).
