# News transaction tests

Follow [test ownership](../AGENTS.md) and the [news transaction contract](../../Sidequest/News/AGENTS.md#transaction-decisions-for-9). Use only fictional fixtures and local temporary files.

Control asynchronous read, load, and save boundaries with actor-owned checked continuations. A gate may deliberately ignore cancellation so tests can release an obsolete operation and assert public model state. Resume every requested gate; do not use sleeps, polling yields, private production task handles, or expose implementation state for testing.

Immutable startup loads must leave snapshots, messages, and operation ownership unchanged. Before-save failures or cancellation must preserve the previous bytes and set; after a durable save, cancellation must still adopt snapshots and call the prepared commit exactly once. Assert serialization and successful retries in addition to failure messages. Real adapter round trips separately verify the original timestamp precision and bytes.
