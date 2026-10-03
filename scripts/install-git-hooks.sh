#!/bin/bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
if [ ! -x .githooks/pre-commit ]; then
  printf '%s\n' 'Hook setup: .githooks/pre-commit is missing or not executable.' >&2
  exit 1
fi

existing_path=$(git config --get core.hooksPath || true)
if [ -n "$existing_path" ] && [ "$existing_path" != .githooks ]; then
  printf 'Hook setup: existing core.hooksPath is %s; reconcile it before installing Sidequest hooks.\n' "$existing_path" >&2
  exit 1
fi

git config --local core.hooksPath .githooks
printf '%s\n' 'Sidequest hooks enabled for this clone.'
