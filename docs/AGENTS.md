# Maintaining project documentation

- Product scope belongs in MVP.md, lightweight choices in DECISIONS.md, consequential tradeoffs in sequential docs/adr/ files, and domain vocabulary in CONTEXT.md. Link authoritative content instead of copying it.
- Mark choices as accepted, proposed, declined, deferred, or superseded; preserve user approval/refusal evidence. Recommendations and issue closure do not approve scope.
- Apply the [decision-recording rule](../AGENTS.md#development-decisions-and-scoped-guidance): change scoped agent instructions only for durable constraints on future work. Put routine implementation history, commands, findings, and verification evidence in issues/PRs.
- Include runnable commands only when supported. Distinguish current source, immutable releases, actual simulator proof, and owner-reported device outcomes; preserve unknown details.

## README maintenance

Keep [README.md](../README.md) a concise product pitch led by the selected logo and truthful playable experience, with installation links and a short visible technical section explaining the native SwiftUI experiment and 100% agent-driven workflow. This owner-selected #235 direction keeps technical instructions in linked documentation. Update material changes to those items in the same PR. Avoid per-ticket summaries, repeated test inventories, source counts, or release-cleanup history; link detailed evidence instead. Native workflow/platform badges may remain, with no credentials or private data in external URLs. Screenshots remain deferred.

Source statistics are optional read-only output under [tooling guidance](../scripts/AGENTS.md#readme-statistics), not a required README update. The October 6 cleanup decision supersedes dashboard #93's automatic refresh policy; see [DECISIONS.md](DECISIONS.md).

## Installation and delivery evidence

When changing installation or delivery, update [INSTALL.md](INSTALL.md) and follow [RELEASES.md](RELEASES.md). Documentation updates do not authorize publication. Keep retained simulator downloads distinct from current iPhone builds.

For app-change Review handoffs, follow [WORKFLOW.md](WORKFLOW.md): identify reviewed source, link free Personal Team signing instructions, and include the relevant behavior checklist. Credentials and local signing stay outside Git; paid enrollment requires explicit approval.
