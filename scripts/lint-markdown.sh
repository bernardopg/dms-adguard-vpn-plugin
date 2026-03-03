#!/usr/bin/env bash
set -euo pipefail

npx --yes markdownlint-cli "**/*.md" --ignore node_modules --ignore .git
