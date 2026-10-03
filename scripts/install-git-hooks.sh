#!/bin/bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
if [ ! -x .githooks/pre-commit ]; then
  printf '%s\n' 'Hook setup: .githooks/pre-commit is missing or not executable.' >&2
  exit 1
fi

existing_path=$(git config --get core.hooksPath || true)
if [ -n "$existing_path" ] && [ "$existing_path" != .githooks ]; then
  # The installed Tokensave hook forwards to this repository's own hook.
  forwarding_hook=$(cat <<'HOOK'
#!/bin/sh
# tokensave: chain-repo-hook
repo_hook="$(git rev-parse --git-dir 2>/dev/null)/hooks/pre-commit"
if [ -x "$repo_hook" ] && [ "$repo_hook" != "$0" ]; then
	"$repo_hook" "$@"
fi
HOOK
)
  current_hook=$(cat "$existing_path/pre-commit" 2>/dev/null || true)
  if [ "$current_hook" != "$forwarding_hook" ] || [ ! -x "$existing_path/pre-commit" ]; then
    printf 'Hook setup: existing core.hooksPath is %s; reconcile it before installing Sidequest hooks.\n' "$existing_path" >&2
    exit 1
  fi

  dispatcher=$(cat <<'HOOK'
#!/bin/sh
# Sidequest: delegate to the tracked pre-commit hook.
exec "$(git rev-parse --show-toplevel)/.githooks/pre-commit" "$@"
HOOK
)
  repo_hooks_dir="$(git rev-parse --absolute-git-dir)/hooks"
  repo_hook="$repo_hooks_dir/pre-commit"
  if [ -L "$repo_hook" ] || { [ -e "$repo_hook" ] && [ ! -f "$repo_hook" ]; }; then
    printf '%s\n' 'Hook setup: a linked or nonregular repository hook needs explicit reconciliation.' >&2
    exit 1
  fi
  if [ -e "$repo_hook" ] || [ -L "$repo_hook" ]; then
    installed_dispatcher=$(cat "$repo_hook" 2>/dev/null || true)
    if [ "$installed_dispatcher" != "$dispatcher" ]; then
      printf '%s\n' 'Hook setup: an existing repository pre-commit hook needs explicit reconciliation.' >&2
      exit 1
    fi
  fi
  mkdir -p "$repo_hooks_dir"
  printf '%s\n' "$dispatcher" > "$repo_hook"
  chmod +x "$repo_hook"
  printf '%s\n' 'Sidequest hook enabled through the existing Tokensave forwarder; hooks configuration preserved.'
  exit 0
fi

if [ -z "$existing_path" ]; then
  # Native hooks may live in the common Git directory for linked worktrees.
  native_hooks_dir=$(git rev-parse --git-path hooks)
  for native_hook in "$native_hooks_dir"/*; do
    case "$native_hook" in
      *.sample) continue ;;
    esac
    if [ -f "$native_hook" ] && [ -x "$native_hook" ]; then
      printf 'Hook setup: existing executable native hook %s would be disabled; reconcile it before installing Sidequest hooks.\n' "$native_hook" >&2
      exit 1
    fi
  done
fi

git config --local core.hooksPath .githooks
printf '%s\n' 'Sidequest hooks enabled for this clone.'
