# Fresh-agent review and merging

The user authorizes agents to commit and push feature branches and merge PRs after this loop passes. All repository changes, including documentation, use feature branches and PRs. Direct commits or pushes to `main` are prohibited.

## Review loop

1. Finish the bounded change on its feature branch, run proportionate verification, and open a PR with the originating GitHub issue and evidence. Read applicable `AGENTS.md` files and the issue's acceptance criteria.
2. Capture the PR number, current head commit, and base commit. Dispatch a new reviewer agent that did not implement the change. Give it the explicit PR target and originating issue, and require the user's `my-review` skill. The installed portable version is [SKILL.md](/Users/dot/.codex/skills/my-review/SKILL.md). Review the diff against that issue and Sidequest guidance; the repository uses GitHub Issues rather than Linear. Review the raw diff unless a review worktree is explicitly authorized. If the skill is unavailable, report the missing dependency rather than silently substituting a review.
3. Have the reviewer report Bugs, Minors, Nits, and Prefs in the skill's format. An empty finding set is the clean-review result. The orchestrator records the reviewer identity and reviewed head/base commits separately from the findings.
4. Assign a fixing agent to address every finding on the feature branch. The fresh reviewer may make fixes when it has an authorized worktree; otherwise the implementation agent applies them. Record the resolution of each finding and rerun affected verification. A disputed finding needs a fresh review with concrete evidence; it cannot be silently dropped.
5. After fixes, dispatch another new reviewer for the complete current diff. Repeat until no findings remain and verification passes. Changes to the PR head or base invalidate the previous review/verification evidence. A reviewer that fixed code cannot certify those fixes as the final independent reviewer.
6. Before merging, recheck the current head/base, issue scope, check results, mergeability, and unresolved review findings. Publish the gates below only when the evidence is complete. If a check cannot run or review cannot converge, keep the PR open, record the cause, and continue independent work; a clean review is not proof that a build passed.
7. Use native GitHub auto-merge when supported, with the reviewed head pinned: `gh pr merge <number> --repo devofthings/sidequest --squash --auto --match-head-commit <reviewed-head-sha>`. Enable it only after the independent review and verification pass. If native auto-merge is unavailable, the orchestrator may use the same command without `--auto` after those gates pass. This is an agent-controlled merge, not server-enforced protection; never use an administrator bypass.
8. Verify the merge, close only completed issues, update Project status, and promote dependents whose prerequisites are complete. Research recommendations, provider selections, final branding, and personal testing remain subject to their issue's completion criteria.

## Commit-bound gates

- **Sidequest / independent review:** The orchestrator records a pending commit status when review starts and success only after a fresh reviewer returns no findings for the current head and base. Keep a PR-linked audit record of the reviewed commits, reviewer, rounds, and resolutions. A new commit or base change requires another round.
- **Sidequest / verification:** Record actual validation commands and results against the same commits. Until an executable app exists, documentation links and diff checks are appropriate and must be labeled as documentation verification. Once CI exists, the CI job owns this gate and must run the foundation's build/test commands for applicable changes. Verify all relevant checks, not just these names.

Agents share the user's GitHub credentials. A separate subagent review does not constitute approval from another GitHub account. Use the review status gate rather than configuring a required human approval that the same account cannot supply. These statuses record the orchestrator's evidence; they are not independent GitHub identities or proof of infallible review.

## GitHub enforcement

The user chose to proceed without a GitHub plan upgrade or main branch protection, recorded in [issue #23](https://github.com/devofthings/sidequest/issues/23). Keep the repository private and follow the feature-branch, review, verification, and agent-controlled merge process above. These instructions and commit statuses do not provide server enforcement or prevent another client from pushing. Revisit branch protection only when the user requests it.

GitHub reported on October 3, 2026 that private-repository protection and rulesets require Pro or a higher eligible plan. Native auto-merge has the same private-repository plan prerequisite and remains disabled; use the orchestrator fallback in step 7. [GitHub protection availability](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches), [auto-merge availability](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/automatically-merging-a-pull-request).

CI remains separate backlog work in issue #15. Before running CI or any other service that could incur charges, apply the spending approval rule in [AGENTS.md](../AGENTS.md): verify free execution or obtain explicit user approval.
