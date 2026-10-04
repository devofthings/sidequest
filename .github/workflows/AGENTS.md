# Native workflow budgets

Follow [GitHub automation](../AGENTS.md) and [CI guidance](../../docs/CI.md).

Integration #9 raises both PR and main/manual native verification budgets to 30 minutes for the larger integrated suite. Retain every existing check, exact-commit guard, dedicated free foreground runner, permissions, and the publisher's 10-minute budget. The author's first 133-case native run took 19 minutes 18 seconds with one legacy picker-test failure; the budget leaves room for the unchanged tooling, discovery, and builds and does not certify CI success. Main pushes continue verification without publication; readiness still requires the reviewed tracked flag and explicit manual dispatch.

Issue #104 raises both native verification budgets to 40 minutes for the preserved full suite plus three actual endless flows. The first new Files flow alone passed in 257.824 seconds; the original 133-case run took about 19 minutes 18 seconds, and the additional all-game and system-accessibility flows require further time. Keep all checks and the publisher's separate 10-minute bound. This capacity change does not authorize test weakening, parallel simulator jobs, publication, or paid execution. Final measured local/CI evidence belongs in [ENDLESS.md](../../docs/ENDLESS.md).
