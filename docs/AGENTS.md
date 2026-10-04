# Maintaining project documentation

- Mark decisions as accepted, proposed, declined, deferred, or superseded. Record user choices faithfully; recommendations remain proposed until confirmed. Preserve approval and refusal evidence under the [decision-request workflow](WORKFLOW.md#unanswered-decision-requests).
- Keep CONTEXT.md limited to domain vocabulary. Put product scope in MVP.md and lightweight decisions in DECISIONS.md.
- Use docs/adr/ for consequential architecture or scope tradeoffs, with sequential numbers. Link accepted ADRs from DECISIONS.md.
- Update the authoritative document when a decision changes. Link it from issues instead of copying entire specifications.
- When recording or changing a development decision, apply the [scoped agent guidance rule](../AGENTS.md#development-decisions-and-scoped-guidance); link the authoritative document from the applicable AGENTS.md.
- Include exact, runnable commands only after the repository supports them. Distinguish verified results from planned validation.

## README dashboard

Keep [README.md](../README.md) concise and tied to merged capabilities. Update game readiness, installation links, and recorded release/test evidence only from actual source and successful checks. A recorded release is a historical snapshot; the main workflow badge reports live status. Use native GitHub workflow badges and repository-local platform SVGs, with no credentials or private-data metrics in external image URLs. Screenshots are deferred by the user on October 4, 2026.

When refreshing delivery or navigation status, preserve the current [release hold](RELEASES.md#accepted-delivery-policy) and [merged feed behavior](FEED.md#navigation-and-eligibility). Distinguish the retained development preview from current source and keep deferred physical installation labeled unverified.

When a PR changes first-party Swift source, refresh the marked source-statistics block using the README command after staging new files. Preserve its selected release baseline unless deliberately updating it to a verified release. Statistics include physical lines, not coverage or quality; [tooling guidance](../scripts/AGENTS.md#readme-statistics) owns computation. Refresh within feature PRs; do not add automated commits or release loops. This implements accepted [dashboard decision #93](DECISIONS.md).
