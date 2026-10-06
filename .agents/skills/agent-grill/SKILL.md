---
name: agent-grill
description: Resolve implementation questions through an evidence-based interview of an agent before bounded Sidequest work. Use when a ticket or technical plan has unresolved choices; reserve human-owned decisions for the project owner.
---

# Interview an agent before implementation

Turn the assigned issue's open questions into an implementable, verifiable plan. The interviewee is an implementation agent. The human project owner retains approval authority. This skill does not expand the task, permissions, or delegated authority.

## Establish the scope

Read the issue, its dependencies, applicable AGENTS.md files, and the confirmed MVP and decisions. In Sidequest, begin with [project guidance](../../../AGENTS.md), [MVP.md](../../../docs/MVP.md), and [DECISIONS.md](../../../docs/DECISIONS.md). Resolve questions from the checked-out project's current guidance rather than treating a prior agent answer as authoritative.

Identify the interviewee and who may settle each choice. Use a separate interviewer only when agent coordination is available and authorized; otherwise conduct the question review yourself and label it a self-assessment. Do not automatically create or contact agents. Send agent questions through authorized agent coordination, not a human input panel or fabricated user message.

Classify each question:

- **Fact:** Look it up in repository documents, code, official sources, or a permitted experiment. Separate an observed result from an assumption or a planned check.
- **Delegated technical choice:** Choose within the issue's acceptance criteria and established authority. Compare plausible options against the accepted boundaries and verification needs. Agent agreement alone does not support a choice.
- **Human-owned decision:** Keep it pending for the actual project owner when it changes accepted product behavior or crosses an approval boundary, including spending. An agent cannot provide human approval. If decision authority is unclear, preserve the current requirement and identify what needs clarification.

## Work the questions in rounds

1. List implementation-critical questions and the prerequisites connecting them. The current frontier contains only questions whose prerequisites are settled. Keep questions outside the assigned scope deferred.
2. For each frontier question, request a proposed answer and supporting evidence from the interviewee, or investigate it yourself in self-assessment mode. Ask about affected interfaces, failure cases, lifecycle behavior, and how the result will be verified when these matter to the issue.
3. Check answers against their sources. Resolve contradictions, inspect relevant code, or run a bounded experiment within existing permissions. Treat missing evidence as an open prerequisite. Keep unrelated work moving while only dependent choices wait.
4. Record settled facts and authorized technical choices, then recompute the frontier. Reopen an answer when new evidence contradicts it. If a round adds no evidence and cannot settle a necessary question, report the missing fact or human decision instead of repeating speculative answers.

Do not request implementation details or new research for choices already settled by an applicable accepted decision. The purpose is to expose gaps in the assigned work, not to redesign the project or make agreement substitute for verification.

## Record and hand off

Maintain a concise decision record with these fields:

| Question | Kind | Answer or pending decision | Evidence and rationale | Verification needed |
| --- | --- | --- | --- | --- |

Link specific files, issue criteria, official sources, or actual experiment results. Label planned validation as planned and proposals as proposed. Before handoff, record significant choices in the authoritative document. Update the closest applicable AGENTS.md only for durable future-agent constraints, linking shared decisions rather than copying them; routine implementation evidence belongs in the issue/PR under the repository's scoped-guidance rule. Edit only within the caller's authorized mutation scope; in a read-only session, return the proposed record for an authorized writer.

The plan is **ready for implementation** when every question necessary to meet the issue's acceptance criteria is resolved within scope, its dependencies are satisfied, and the affected behavior has a feasible verification plan. If a necessary fact or human-owned decision remains open, report that specific prerequisite and continue independent work. Defer optional questions explicitly.

An agent's confirmation means the technical plan is ready within delegated scope. It is not human approval, a completed test, or an independent code review. Implementation still follows [the project's review and merge loop](../../../docs/REVIEW.md).
