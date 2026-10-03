# Task workflow

The private [Sidequest MVP board](https://github.com/users/devofthings/projects/1) tracks workflow status. GitHub Issues own acceptance criteria and dependencies; repository documents own product scope and decisions.

| Status | Meaning |
| --- | --- |
| Backlog | Planned work that has not been selected or whose prerequisites remain incomplete. |
| Ready | Scope is clear, prerequisites are complete, and work can start. |
| In progress | An agent or person is actively working on the issue. |
| Review | The acceptance criteria are implemented, validation is recorded, and the result is ready for review. |
| Done | The work is merged or explicitly accepted, and the issue is closed. |

Before starting an issue, confirm its prerequisites are complete and set its Project status to In progress. Move it to Review when a reviewable result and verification evidence are available, then run the [fresh-agent review and merge loop](REVIEW.md). After merge, close completed implementation issues, set them to Done, and move dependent issues to Ready when all their prerequisites are complete. Product-decision issues stay open until the user selects the proposed behavior or provider; merging research does not select it.

Keep unfinished work open. If work pauses or a new prerequisite blocks it, record the reason in the issue and move it to Ready or Backlog as appropriate.

After each resolved issue or ticket, follow the [chat checkpoint](../AGENTS.md#after-ticket-chat-checkpoint) before starting or assigning another issue. Incorporate newly delivered user steering before choosing the next task.

## Unanswered decision requests

1. Confirm that the selected task actually needs a user decision or prerequisite, and check existing authorization and recorded decisions first. Prepare a concrete request with the proposed action, reason, cost or cost uncertainty, expected limit, alternatives, and affected task. Ask in chat before creating a fallback issue. A hypothetical future service is not a current blocker.
2. Give the user a reasonable opportunity to respond. If the required request remains unanswered at a chat checkpoint or handoff, search for an existing matching request before creating another. Use the [decision-request template](../.github/ISSUE_TEMPLATE/decision-request.md), assign the issue to `devofthings`, and apply `decision-needed`. Record when and what was asked in chat, and link the affected task. Leave credentials and other secrets out of the issue.
3. Add the reviewable request to the Project's Review column. Keep dependent implementation pending and record the request as its prerequisite; continue independent work. Distinguish approving an action from the user completing a prerequisite such as creating an account. Check that both are satisfied before proceeding.
4. Wait for an explicit user decision in chat or a user-authored issue response. Record the outcome as Pending, Approved, Declined, or Deferred, with date, source, precise scope, conditions, and any cost limit. Silence, an agent-authored decision note, checkboxes, labels, or issue closure alone are not authorization. Agents may document a decision they received but cannot approve their own request.
5. Preserve both approvals and refusals in [DECISIONS.md](DECISIONS.md), or an appropriate ADR linked from it, and update the affected `AGENTS.md` guidance. Link the request and decision evidence so future chats can revisit them. Close a request and mark it Done once an explicit final decision is recorded; a pending or deferred request stays open. A declined action remains excluded unless the user reopens the decision. An approved request can close while its separately tracked prerequisite remains pending.

This workflow captures missed chat requests. It does not adopt Mastra, require a Mastra account, activate billing, or replace the [spending approval rule](../AGENTS.md#spending-approval).
