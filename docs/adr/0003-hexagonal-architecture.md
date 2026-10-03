---
status: accepted
date: 2026-10-03
---

# Start with hexagonal architecture

The user chose hexagonal architecture from the start because the MVP's behavior and integrations may change after testing. Keep game rules and feed/session behavior in a pure Swift core, expose small ports at replaceable boundaries, and implement SwiftUI presentation and local news loading as adapters wired by the app's composition root. This trades a little initial boundary work for the ability to change presentation or content sources and verify core behavior independently, following the [ports and adapters pattern](https://alistair.cockburn.us/hexagonal-architecture).

## Implementation constraints

- Dependencies point toward the core. Core rules and use cases work without SwiftUI, UIKit, SpriteKit, networking clients, or storage SDKs.
- Each game owns its rules; the feed uses the shared lifecycle contract rather than knowing those rules. UI and rendering adapters translate interaction into core operations and render the resulting state.
- Introduce a port for a real replaceable boundary, such as news content loading. Inject randomness and time where behavior needs deterministic verification. Concrete value types and functions remain appropriate inside the core.
- The app foundation establishes the boundaries; the shared-contract issue establishes the actual interfaces. Separate packages and a dependency-injection framework are not prerequisites.
- The initial news adapter reads local snapshots. A server backend remains deferred. Hexagonal architecture does not mandate TDD; verification choices follow the behavior being changed.
