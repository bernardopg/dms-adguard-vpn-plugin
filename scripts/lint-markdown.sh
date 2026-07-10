#!/usr/bin/env bash
set -euo pipefail

mapfile -t markdown_files < <(
  find . -type f -name "*.md" \
    -not -path "./.git/*" \
    -not -path "./node_modules/*" \
    -not -path "./.github/agents/*" \
    -not -name "AGENTS.md" \
    | sort
)

if [[ ${#markdown_files[@]} -eq 0 ]]; then
  echo "No project Markdown files found."
  exit 0
fi

npx --no-install markdownlint "${markdown_files[@]}"
