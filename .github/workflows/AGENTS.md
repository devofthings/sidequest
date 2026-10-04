# Native workflow budgets

Follow [GitHub automation](../AGENTS.md) and [CI guidance](../../docs/CI.md).

Integration #9 raises both PR and main/manual native verification budgets to 30 minutes for the larger integrated suite. Retain every existing check, exact-commit guard, dedicated free foreground runner, permissions, and the publisher's 10-minute budget. The author's first 133-case native run took 19 minutes 18 seconds with one legacy picker-test failure; the budget leaves room for the unchanged tooling, discovery, and builds and does not certify CI success. Main pushes continue verification without publication; readiness still requires the reviewed tracked flag and explicit manual dispatch.
