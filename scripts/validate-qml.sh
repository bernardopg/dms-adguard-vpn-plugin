#!/usr/bin/env bash
set -euo pipefail

mapfile -t qml_files < <(find . -type f -name "*.qml" | sort)

if [[ ${#qml_files[@]} -eq 0 ]]; then
  echo "No QML files found."
  exit 0
fi

for file in "${qml_files[@]}"; do
  qmlformat "$file" >/dev/null
done

echo "QML syntax validation passed for ${#qml_files[@]} file(s)."
