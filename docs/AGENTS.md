# Maintaining project documentation

- Mark decisions as accepted, proposed, declined, deferred, or superseded. Record user choices faithfully; recommendations remain proposed until confirmed. Preserve approval and refusal evidence under the [decision-request workflow](WORKFLOW.md#unanswered-decision-requests).
- Keep CONTEXT.md limited to domain vocabulary. Put product scope in MVP.md and lightweight decisions in DECISIONS.md.
- Use docs/adr/ for consequential architecture or scope tradeoffs, with sequential numbers. Link accepted ADRs from DECISIONS.md.
- Update the authoritative document when a decision changes. Link it from issues instead of copying entire specifications.
- When recording or changing a development decision, apply the [scoped agent guidance rule](../AGENTS.md#development-decisions-and-scoped-guidance); link the authoritative document from the applicable AGENTS.md.
- Include exact, runnable commands only after the repository supports them. Distinguish verified results from planned validation.

## README dashboard

Keep [README.md](../README.md) concise and tied to merged capabilities. Update game readiness, installation links, and recorded release/test evidence only from actual source and successful checks. A recorded release is a historical snapshot; the PR verification workflow badge reports live PR-check status. Routine merging starts no automatic main job under #112; manual releases require explicit owner publication authorization. Use native GitHub workflow badges and repository-local platform SVGs, with no credentials or private-data metrics in external image URLs. Screenshots are deferred by the user on October 4, 2026.

When refreshing delivery or navigation status, preserve the current [release hold](RELEASES.md#accepted-delivery-policy) and [merged feed behavior](FEED.md#navigation-and-eligibility). Keep the retained development preview separate from current source and the owner-reported iPhone installation/basic play separate from exact agent-run verification; preserve unknown device details. See [the owner report](INSTALL.md#owner-reported-iphone-test).

When a PR changes first-party Swift source, refresh the marked source-statistics block using the README command after staging new files. Preserve its selected release baseline unless deliberately updating it to a verified release. Statistics include physical lines, not coverage or quality; [tooling guidance](../scripts/AGENTS.md#readme-statistics) owns computation. Refresh within feature PRs; do not add automated commits or release loops. This implements accepted [dashboard decision #93](DECISIONS.md).

Integration #9’s readiness PR was partial until actual selected published-tag source/checksum/install proof existed. [Verified MVP delivery](INSTALL.md#verified-mvp-delivery) now records that actual proof. Preserve the manual-only release policy and immutable source/assets; document future versions only from successful publication and actual installation evidence. Seven old preview downloads were removed under the user’s request; source tags remain, including the README’s `2026.10.7` baseline. [Personal feedback #10](MVP.md#personal-test-outcome) is complete: the owner wants to keep the mixed concept and improve design, animation, and fun. Preserve unknown device/build metadata and detailed accessibility outcomes; owner-reported basic play is separate from the exact release evidence. Do not infer new feature approval or another publication from technical delivery or documentation updates.

## Endless follow-up evidence

[ENDLESS.md](ENDLESS.md) owns #104's generated challenge, bounded adapter, retained lightweight-history, transaction, and verification decisions. Keep current-source behavior distinct from immutable `2026.10.14` finite-deck delivery. Optional news-once and Chess-reuse policies are explicitly labeled implementation defaults, not user replies. Physical-device and personal enjoyment evidence remain outside automated delivery.

## Demo news and cadence #106

DEMO_NEWS.md owns the approved #106 cadence, fictional-data, absence/empty/error and counter-removal decisions. Update current contracts consistently, distinguish source stories from appearances, and preserve immutable finite-release and historical test evidence. See [demo news policy](DEMO_NEWS.md).

## Personal iPhone Review instructions

Accepted owner steering on October 4, 2026: app-change Review handoffs include concrete personal-iPhone testing instructions using a free Apple Account/Personal Team, the ignored local signing configuration, pairing/Developer Mode/Run, and seven-day reinstallation. Follow [the workflow rule](WORKFLOW.md) and [installation steps](INSTALL.md#install-on-your-own-iphone). Identify the current PR source; do not describe old simulator downloads as an iPhone installation or infer actual device verification from simulator tests. Credentials and personal signing settings stay out of Git, and paid enrollment requires separate approval.
