#!/usr/bin/env bash
set -euo pipefail

# Detect qmlformat binary — name varies by Qt version and distro:
#   qmlformat   (Qt5 / Qt6 on Ubuntu 22.04)
#   qml6format  (Qt6 on Ubuntu 24.04+)
#   qmlformat6  (some Fedora/Arch packaging)
QML_FMT=""
for candidate in qmlformat qml6format qmlformat6; do
  if command -v "$candidate" &>/dev/null; then
    QML_FMT="$candidate"
    break
  fi
done

if [[ -z "$QML_FMT" ]]; then
  echo "WARNING: no QML formatter found (tried: qmlformat, qml6format, qmlformat6)." >&2
  echo "         Install qt6-declarative-dev-tools or qml6-tools to enable QML syntax checks." >&2
  echo "         Skipping QML validation."
  exit 0
fi

mapfile -t qml_files < <(find . -type f -name "*.qml" | sort)

if [[ ${#qml_files[@]} -eq 0 ]]; then
  echo "No QML files found."
  exit 0
fi

for file in "${qml_files[@]}"; do
  "$QML_FMT" "$file" >/dev/null
done

echo "QML syntax validation passed for ${#qml_files[@]} file(s) (via $QML_FMT)."
