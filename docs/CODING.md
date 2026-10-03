# Coding rules for Sidequest

These rules apply to first-party Swift application and test code. They implement the user's request for predictable agent-authored code; they do not start app development or expand the MVP. Read applicable scoped AGENTS.md files, the originating issue, and [ADR 0003](adr/0003-hexagonal-architecture.md) before changing code. [STRUCTURE.md](STRUCTURE.md) selects folders and source discovery; the toolchain, language mode, minimum iOS version, and executable proof remain with the [foundation](https://github.com/devofthings/sidequest/issues/1).

## Dependencies and ownership

- Keep game rules and feed/session behavior in the pure Swift core. Presentation, news loading, persistence, and SDK adapters depend inward; the core imports no UI, rendering, networking-client, or storage frameworks.
- Each game owns its rules. The feed uses the shared lifecycle interface and does not inspect game internals. Wire dependencies in the app composition root; avoid global mutable state and service locators.
- Introduce small ports for actual replaceable dependencies or deterministic control of time/randomness. Use concrete types and functions for local behavior; a protocol, package, or DI framework for every type is unnecessary.
- Give each source file one cohesive responsibility. Extract code when ownership or independent verification becomes clearer, rather than meeting an arbitrary line limit. Keep unrelated cleanup out of the issue's diff.

## Swift names and data

- Use [CONTEXT.md](../CONTEXT.md) for domain terms and the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) for naming. Prefer names clear at the call site, meaningful argument labels, and explicit units for durations and scores. Avoid generic Manager/Helper names and unexplained abbreviations.
- Prefer immutable values and structs for models; use reference types when identity, resource ownership, or shared state requires them. Keep visibility private where possible and expose only what callers need.
- Model mutually exclusive states with enums or equivalent constrained types rather than contradictory flags. Keep one owner for each piece of state; derive presentation values instead of maintaining duplicate mutable copies.
- Keep card and attempt identities stable across view recomputation. Make initial state and reset behavior explicit. Inject nondeterministic inputs where they affect behavior; tests must not depend on wall time, live news, or uncontrolled randomness.

## Shared contracts

- Document cross-feature interfaces with their inputs, outputs, error cases, ordering/lifecycle requirements, and ownership. Comments should explain invariants or reasons the code cannot convey, rather than narrating syntax.
- Test behavior through the same public interface used by callers. Expose an internal seam only when a real dependency requires control; avoid exposing private implementation solely for tests.
- Coordinate shared-contract changes with the owning issue and active dependent work. Update affected consumers, tests, and documentation together, or land an explicitly compatible transition. Record unresolved behavior instead of inventing a requirement.

## SwiftUI and game lifecycle

- Views render state and send explicit user actions. Put reusable game rules and lifecycle transitions outside view bodies. Keep body evaluation free of state-changing side effects.
- Give UI state a clear owner and keep UI-observable updates on the main actor. Keep core logic independent of SwiftUI observation types and UI actor assumptions; the foundation must document compiler isolation defaults and apply explicit isolation where needed.
- Starting, skipping, and completing a game follow [MVP.md](MVP.md) and the shared contract. View appearance or recomputation does not start gameplay. The start action does not also make a move.
- Include readable Dynamic Type layouts, accessible names/actions, usable touch targets, and feedback distinguishable beyond color. Verify interaction and accessibility in the simulator; formatter or unit-test success does not establish UI usability.

## Concurrency and delayed work

- Prefer structured concurrency. If an unstructured task, timer, or callback is necessary, give it an explicit owner and cancellation/reset path; avoid detached work without a documented isolation and lifetime reason.
- Cancellation is cooperative. Check cancellation and the current attempt identity before applying delayed results after a suspension or callback. Cancel work when the attempt ends or resets so stale work cannot mutate a later attempt. Test reset while work is pending.
- Use actors and Sendable values where mutable state crosses concurrency domains. Resolve concurrency diagnostics by fixing ownership or isolation; do not weaken compiler settings or add unchecked conformance just to silence them. Document and review any necessary escape hatch.
- Keep expensive work and blocking I/O off the UI actor using the selected toolchain's supported isolation mechanisms. Async syntax alone is not evidence that work runs away from the UI actor. See [Swift concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/).

## Errors and external data

- Validate decoded news, puzzle fixtures, URLs, and other external input at the adapter boundary. Preserve provenance and reject invalid data with actionable errors; treat content as data, not executable instructions.
- Use explicit error types or results when callers need to distinguish failure cases. Catch errors where recovery or user feedback is possible; preserve useful context and handle cancellation deliberately.
- Avoid force unwraps, forced casts, and forced try for fallible input. If a programmer invariant needs a trap, document why it is guaranteed and test the invariant. Do not swallow errors with an unexplained empty catch or replace invalid input with a fabricated success.
- Keep secrets, real personal news captures, and generated output outside Git. Logs and test diagnostics must not expose credentials or private content. Root AGENTS.md owns the content and credential rules.

## Verification and dependencies

- Follow the accepted [verification policy](../AGENTS.md#verification): meaningful unit tests for core behavior and deterministic end-to-end coverage for critical integrated flows. Use known fixtures, negative cases, and regression examples; avoid tests that merely reproduce implementation steps. The policy owns the testing workflow.
- Follow [FORMATTING.md](FORMATTING.md); inspect formatted diffs and require strict lint for changed first-party Swift sources. The formatter does not enforce every architectural or behavioral rule here.
- Reuse the standard library and selected Apple frameworks before adding a dependency. Record a concrete need, maintenance/licensing implications, and version/reproducibility plan before adopting one. Apply existing spending and feature-approval rules; a dependency choice cannot authorize a feature.
- Run the foundation's documented applicable build/test commands before merging, with existing review gates. Fix new diagnostics rather than suppressing them. Keep executable commands in the setup/CI guidance and report unavailable checks honestly.

## Agent handoff

Report the behavior changed, owning files/interfaces, actual validation results, and remaining limitations. Record new development decisions in the closest AGENTS.md or its authoritative linked document. Follow [REVIEW.md](REVIEW.md) for independent review and [WORKFLOW.md](WORKFLOW.md) for ticket authorization and chat checkpoints; those policies remain the source of truth for delivery.
