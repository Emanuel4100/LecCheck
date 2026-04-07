#!/usr/bin/env bash
set -euo pipefail

FLUTTER_BIN="${FLUTTER_BIN:-$HOME/development/flutter/bin/flutter}"
TARGET="${1:-chrome}"

if [[ ! -x "${FLUTTER_BIN}" ]]; then
  echo "Flutter not found at ${FLUTTER_BIN}"
  echo "Set FLUTTER_BIN or install Flutter in ~/development/flutter"
  exit 1
fi

echo "Starting LecCheck Flutter app on target: ${TARGET}"
echo "Press Ctrl+C to stop."
cd flutter_app

if [[ "${TARGET}" == "chrome" ]] && [[ -z "${CHROME_EXECUTABLE:-}" ]]; then
  for browser in /usr/bin/brave-browser /usr/bin/brave-browser-stable /usr/bin/chromium-browser /usr/bin/chromium /usr/bin/google-chrome; do
    if [[ -x "${browser}" ]]; then
      export CHROME_EXECUTABLE="${browser}"
      echo "Using browser executable: ${CHROME_EXECUTABLE}"
      break
    fi
  done
fi

"${FLUTTER_BIN}" run -d "${TARGET}"
