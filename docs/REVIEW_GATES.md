# Execute review and merge gates

Use `scripts/review-gate.py` after the fresh reviewer and actual verification finish. It replaces temporary gate helpers. Python 3, Git, authenticated `gh`, and the reviewed Git objects are required. Fetch the feature branch and main explicitly before running it; the validator never fetches, changes the checkout, or executes receipt commands.

The lead must first confirm the issue's accepted scope, prerequisites, implementation hold, spending rules, included allowance, and the reviewer's independence. The CLI checks the evidence's structure and consistency with GitHub and Git. It cannot read chat authorization, prove that an agent ran a command, authenticate agent identities, or substitute for substantive review. A linked issue, Ready status, or receipt does not approve a feature.

## Prepare the receipt

Have the reviewer return the exact current head/base, identity, no findings, and actual command results. The lead records every implementing/fixing agent, earlier finding resolutions, and the existing approval's source and precise scope. Keep secrets, private captures, and personal signing information out of the receipt: recording publishes it to the private PR.

Save this shape as JSON outside the checkout, replacing every example value with actual evidence. `changed_paths` must list the complete diff, including removed files. `head` and `base` are full 40-character lowercase commit SHAs; verification repeats them to prevent mixed targets.

```json
{
  "schema": 1,
  "pr": 123,
  "issue": 63,
  "issue_completion": "complete",
  "head": "0000000000000000000000000000000000000000",
  "base": "1111111111111111111111111111111111111111",
  "reviewer": "/root/fresh-reviewer",
  "contributors": ["/root/implementer", "/root/fixer"],
  "round": 2,
  "findings": [],
  "resolutions": ["Round 1: stale-base handling fixed; fresh round verified the complete diff."],
  "authorization": {
    "source": "User chat, October 3, 2026; issue #63 records the request",
    "decision": "The user instructed the lead to fix the audited preparation gaps.",
    "approved_scope": "Repository-owned gate tooling; app implementation remains on hold.",
    "confirmed_by": "/root",
    "changed_paths": ["scripts/review-gate.py"]
  },
  "verification": {
    "mode": "tooling",
    "head": "0000000000000000000000000000000000000000",
    "base": "1111111111111111111111111111111111111111",
    "commands": [
      {"command": "python3 scripts/test-review-gate.py", "exit_code": 0, "result": "Record the actual test count and outcome here."}
    ],
    "unavailable_checks": ["No application target or CI exists; app builds and gameplay tests are unavailable."]
  }
}
```

Verification modes:

- `documentation`: only Markdown changed; report actual documentation checks.
- `tooling`: Markdown, files under `scripts/` or `.githooks/`, and `.swift-format`; report relevant local integration checks. Application files require a different mode.
- `ci`: CI owns verification. Include `verification.run_url` matching a successful `Sidequest / verification` check run's details URL. That check run must identify the reviewed head SHA; the receipt binds its run to the reviewed head/base, and the local ancestry check requires the current base inside that tested head. Local agents do not publish or overwrite the CI verification gate. Once workflows exist, the CLI requires this mode; issue #15 must implement the check contract before using these gates for CI-backed changes.

Every listed command must have a real result and numeric zero exit code. Local modes must explain unavailable app/CI checks. The CLI independently checks Git ancestry and whitespace; other command evidence remains the reviewer's and lead's responsibility. These checks are not permission to start app development or potentially chargeable CI.

`issue_completion` is `complete` by default for existing receipts. A complete contribution requires a closing reference and must meet the issue's completion criteria. For a reviewed contribution that finishes only a bounded part of an open issue, set `issue_completion` to `partial`, state that narrower approved scope in `authorization.approved_scope`, and use an explicit `Refs #<issue>`, `Part of #<issue>`, or `Related to #<issue>` in the PR body (the full repository issue URL also works). Partial contributions must have no closing reference to their parent in their body or title, and no native GitHub closing link. The gate recognizes uppercase keywords, optional colons, repository-qualified references, and full issue URLs. For partial merges it uses the checked PR title and an empty squash body, preventing feature commit messages from closing the parent through default squash text. The receipt audit labels the contribution, and the lead leaves the issue open and updates only its actual progress. This supports decision-recording PRs without claiming the later design or implementation is complete.

## Validate, record, merge

Run from a checkout containing the reviewed commits, or pass `--checkout /absolute/path`:

```sh
python3 scripts/review-gate.py /private/tmp/review-receipt.json
```

The default makes GitHub reads and local Git reads only. It rejects malformed or stale evidence, prohibited targets, drafts, conflicts or unknown mergeability, unresolved threads or change requests, and pending/failed checks. It requires an open originating issue, a matching `codex/<issue>-...` branch, and the appropriate completion or partial reference described above. For local verification, prior Sidequest status gates may be pending or stale while a fresh receipt is validated; all other gates must pass.

Publish a new audit comment and local commit statuses explicitly:

```sh
python3 scripts/review-gate.py /private/tmp/review-receipt.json --record
```

Revalidate recorded evidence and merge with the reviewed head pinned:

```sh
python3 scripts/review-gate.py /private/tmp/review-receipt.json --merge
```

`--record --merge` combines the two explicit actions. A merge requires passing published gates linked to a comment containing the identical receipt on this PR. Any changed head/base needs new verification and a fresh independent reviewer. The command always uses squash and `--match-head-commit`, with no administrator bypass or auto-merge activation. A nonzero exit stops the sequence; never issue a separate merge after a gate fails.

GitHub exposes separate reads, status writes, and merge operations. Head pinning prevents merging a different head, but the API cannot atomically pin the base, checks, threads, and authorization together. The CLI rechecks before writes and immediately before merge, then verifies that the resulting squash commit has the reviewed base as its sole parent. A base change after the last check can still merge; a detected mismatch returns failure and requires a checkpoint/audit of the actual result. It does not claim rollback or server enforcement. The shared account can also edit comments/statuses; receipts are durable agent evidence, not cryptographic independence.

## Verify gate changes

```sh
python3 scripts/test-review-gate.py
```

Tests use fake GitHub responses and temporary local repositories with hooks disabled for fixtures. They never mutate live GitHub or run CI. Review changes against the originating issue, run these tests and documentation/diff checks, then use a fresh reviewer. Current app build and gameplay checks remain unavailable.

## Implementation choices for issue #63

This is the implementation agent's self-assessment under the project-local agent-grill skill.

| Question | Kind | Answer | Evidence and rationale | Verification |
| --- | --- | --- | --- | --- |
| How should default execution behave? | Delegated choice | Read-only; separate explicit record/merge flags. | Issue #63 requires reviewable commands without accidental mutation. | Fake client proves default makes no writes and failures stop mutations. |
| Can issue links prove approval? | Fact | No; require a precise decision and lead confirmation. | WORKFLOW.md distinguishes explicit user approval from labels and issue status. | Reject missing and link-only decisions; lead checks authorization before execution. |
| Who owns future verification? | Fact | CI once workflows exist; local tooling does not overwrite its gate. | REVIEW.md assigns CI gate ownership to issue #15. | Successful run URL/head evidence required; failed/pending checks block. |
| Can merge be fully atomic? | Fact | Head is pinned; other state has a documented API race. | The accepted CLI merge process exposes a head-match option and separate checks. | Simulated premerge races stop merging; postmerge parent mismatch reports failure. |
