---
name: my-review
description: "Review a Sidequest PR, branch, or commit range in the user's preferred style: ticket-aware, guideline-aware findings grouped as Bugs, Minors, Nits, and Prefs."
---

# Personal code review

Resolve the review target explicitly. For a PR, use `gh pr diff` and `gh pr view`; for a branch, diff its merge-base against the repository default branch; for a supplied range or path, use that diff. When no target is supplied, ask whether to review the current branch against its default branch or a specific PR/branch/range. Use the explicit target rather than silently reviewing the working tree.

Resolve the originating GitHub issue from explicit assignment first, then issue links or closing references in the PR body, then the issue number in the `codex/<issue>-<description>` branch. Read its live acceptance criteria and dependencies. If the issue remains ambiguous, report the missing scope before certifying the review.

Compare the complete target diff against that issue, the applicable `AGENTS.md` files at the reviewed commit, and relevant linked project documentation. Read [Sidequest review gates](../../../docs/REVIEW.md) for commit-bound evidence and fresh-review requirements. Read raw diffs unless the caller explicitly authorizes an isolated review checkout; the reviewer preserves the author's checkout and index. If design evidence is linked and accessible, include implementation mismatches; report an unavailable design check only when material to the result.

Rate each deduplicated finding exactly once:

- **Bug:** correctness, crashes, data integrity, or visible behavior breakage.
- **Minor:** a worthwhile non-breaking fix, including missed error handling or a non-breaking guideline violation.
- **Nit:** pure style with no functional stake.
- **Pref:** a violation of an explicitly recorded user preference.

Respond in chat only, grouped in this order: `Bugs`, `Minors`, `Nits`, `Prefs`. Omit empty groups. Each line must be `path/to/file:123 — description`. Create no inline PR comments, summary, or next steps after findings. When there are no findings, return `No findings.`; provide a separately requested verification receipt to the lead without changing the findings format.

## Provenance

Adapted on October 3, 2026 from the user's installed `my-review` skill. Preserves explicit targets, ticket and guideline checks, severity groups, file-and-line findings, and chat-only output. Sidequest GitHub Issues replace unrelated Linear discovery and machine-specific Plancraft memory paths. This tracked version is canonical for Sidequest; accepted preferences live in repository guidance and decisions.
