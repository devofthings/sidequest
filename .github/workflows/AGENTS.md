# Native workflow budgets

Follow [GitHub automation](../AGENTS.md) and [CI guidance](../../docs/CI.md).

Integration #9 raises both PR and main/manual native verification budgets to 30 minutes for the larger integrated suite. Retain every existing check, exact-commit guard, dedicated free foreground runner, permissions, and the publisher's 10-minute budget. This is a validation bound, not a measured duration or a hosted-runner fallback. Main pushes continue verification without publication; readiness still requires the reviewed tracked flag and explicit manual dispatch.
