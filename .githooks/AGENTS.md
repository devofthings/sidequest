# Maintaining commit checks

Keep the hook read-only: validate index blobs and the staged formatter configuration, preserving both the index and working tree. Use NUL-delimited path discovery and quoted arguments so partial staging and unusual filenames remain supported. Include staged type changes when discovering paths, then check regular Swift index entries; replacing a symlink with regular Swift source must receive the same lint as other source changes. Skip staged symlinks, deletions, and the generated/dependency directories listed in the hook.

Keep commit checks fast: staged whitespace and strict Swift lint only. Builds and gameplay tests remain in the separate verification workflow. Preserve explicit per-clone installation, respect existing hooks configuration, and document changes in [FORMATTING.md](../docs/FORMATTING.md). Local hooks provide feedback and can be bypassed; they do not satisfy independent review or replace CI.
