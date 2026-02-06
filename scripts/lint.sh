#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

files=$(find . -type f \( -name "*.swift" -o -name "*.md" -o -name "*.yml" -o -name "*.yaml" -o -name "*.sh" \) \
  -not -path "./.git/*")

if [ -z "$files" ]; then
  echo "No files to lint"
  exit 0
fi

if grep -n $'\t' $files; then
  echo "Tab characters found. Use spaces for indentation."
  exit 1
fi

if grep -nE "[[:space:]]+$" $files; then
  echo "Trailing whitespace found."
  exit 1
fi

echo "Lint checks passed"
