# Task workflow

The private [Sidequest MVP board](https://github.com/users/devofthings/projects/1) tracks workflow status. GitHub Issues own acceptance criteria and dependencies; repository documents own product scope and decisions.

| Status | Meaning |
| --- | --- |
| Ideas | Proposed features and other suggestions awaiting user agreement; work is limited to capturing the proposal. |
| Backlog | Planned work that has not been selected or whose prerequisites remain incomplete. |
| Ready | Scope is clear, prerequisites are complete, and work can start. |
| In progress | An agent or person is actively working on the issue. |
| Review | The acceptance criteria are implemented, validation is recorded, and the result is ready for review. |
| Done | The work is merged or explicitly accepted, and the issue is closed. |

Capture new suggestions in Ideas. Promote an idea to Backlog only after explicit user agreement and a bounded GitHub issue with an outcome and acceptance criteria; move it to Ready only when scope and prerequisites permit work. Ideas do not expand the confirmed MVP or authorize their own implementation.

Before starting an issue, confirm its prerequisites are complete and set its Project status to In progress. Move it to Review when a reviewable result and verification evidence are available, then run the [fresh-agent review and merge loop](REVIEW.md). After merge, close completed implementation issues, set them to Done, and move dependent issues to Ready when all their prerequisites are complete. Product-decision issues stay open until the user selects the proposed behavior or provider; merging research does not select it.

When a PR is ready, enter the [review handoff queue](REVIEW.md#review-handoff-queue). Missing subagent capability blocks merging in the author chat, not discoverability: keep the issue in Review and hand it to an active lead. Leads check the queue before taking new issues, including open ready PRs without the label.

The user requested on October 4, 2026 that Review items include instructions for testing on their personal iPhone without paid Apple Developer Program membership. For app changes, include a concise testing section in the issue/PR handoff, identify the current PR branch and reviewed commit, and link [local iPhone installation](INSTALL.md#install-on-your-own-iphone). Explain free Personal Team signing, the local ignored configuration, device pairing/Developer Mode/Run, seven-day reinstallation, and the relevant behavior checklist. Distinguish simulator downloads from physical-device builds and keep actual device verification truthful. This documentation rule does not authorize paid enrollment or account setup.

Keep unfinished work open. If work pauses or a new prerequisite blocks it, record the reason in the issue and move it to Ready or Backlog as appropriate.

After each resolved issue or ticket, follow the [chat checkpoint](../AGENTS.md#after-ticket-chat-checkpoint) before starting or assigning another issue. Incorporate newly delivered user steering before choosing the next task.

## Project updates

Publish a native status update in the private [Sidequest Project](https://github.com/users/devofthings/projects/1) after a completed ticket or a related batch of milestones, when a blocker or required decision meaningfully changes, and at an active work-session handoff if there is new progress. The lead coordinates one update for parallel work. Read the latest update and issue/PR state before posting; skip duplicate or unchanged reports.

Keep each update short and understandable without reading agent logs. Include the date, completed work with evidence links, work in progress or review, next planned action, blockers or required user decisions, and actual validation/build availability. Distinguish proposals, open PRs, and planned checks from merged work and verified results. Describe planned actions as pending when dependencies or another explicit hold apply; avoid invented deadlines or unsupported completion percentages.

Issue comments and PR audits retain detailed findings and commands; updates link those records. Leave credentials, private news captures, and other sensitive material out. Publishing an update does not change accepted scope, authorize an Idea, override another explicit hold, or permit spending. This cadence applies while authorized work is active and creates no recurring automation or messages to another chat.

## Ticket authorization

Agents may create and address bug-fix tickets without a separate feature approval. A bug fixes a reproducible defect or a demonstrated mismatch with accepted behavior; record the evidence, expected behavior, and link to its approved scope. Agents may also split already-approved work into necessary implementation subtasks without expanding it. Apply dependencies, current start authorization, spending/usage rules, and the normal review/verification loop to both.

New features and expanded behavior go into the Project's Ideas status, even when their scope is clear. Record the proposal, rationale, and open questions; beyond capturing it, start or assign no work on the idea until the user explicitly agrees. This includes research, design, prototypes, and implementation. If a proposed change cannot be established as a defect or a necessary part of approved scope, keep it in Ideas rather than treating it as a bug fix.

Accept approval from an explicit user instruction in chat or a user-authored issue response. Record its date, source, and exact approved scope in the issue and update [DECISIONS.md](DECISIONS.md) before promotion or work; update agent guidance only when durable future-agent behavior changes. Silence, agent-authored approval notes, labels, or moving an item out of Ideas do not authorize it. Approved features and the confirmed MVP do not need approval again; link their existing acceptance evidence. User approval of a feature does not separately authorize spending or lift an unrelated implementation hold.

## Unanswered decision requests

1. Confirm that the selected task actually needs a user decision or prerequisite, and check existing authorization and recorded decisions first. Prepare a concrete request with the proposed action, reason, cost or cost uncertainty, expected limit, alternatives, and affected task. Ask in chat before creating a fallback issue. A hypothetical future service is not a current blocker.
2. Give the user a reasonable opportunity to respond. If the required request remains unanswered at a chat checkpoint or handoff, search for an existing matching request before creating another. Use the [decision-request template](../.github/ISSUE_TEMPLATE/decision-request.md), assign the issue to `devofthings`, and apply `decision-needed`. Record when and what was asked in chat, and link the affected task. Leave credentials and other secrets out of the issue.
3. Add the reviewable request to the Project's Review column. Keep dependent implementation pending and record the request as its prerequisite; continue independent work. Distinguish approving an action from the user completing a prerequisite such as creating an account. Check that both are satisfied before proceeding.
4. Wait for an explicit user decision in chat or a user-authored issue response. Record the outcome as Pending, Approved, Declined, or Deferred, with date, source, precise scope, conditions, and any cost limit. Silence, an agent-authored decision note, checkboxes, labels, or issue closure alone are not authorization. Agents may document a decision they received but cannot approve their own request.
5. Preserve both approvals and refusals in [DECISIONS.md](DECISIONS.md), or an appropriate ADR linked from it, and update affected `AGENTS.md` guidance only for durable future-agent constraints. Link the request and decision evidence so future chats can revisit them. Close a request and mark it Done once an explicit final decision is recorded; a pending or deferred request stays open. A declined action remains excluded unless the user reopens the decision. An approved request can close while its separately tracked prerequisite remains pending.

This workflow captures missed chat requests. It does not adopt Mastra, require a Mastra account, activate billing, or replace the [spending approval rule](../AGENTS.md#spending-approval).
