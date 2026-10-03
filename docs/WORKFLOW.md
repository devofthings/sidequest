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
