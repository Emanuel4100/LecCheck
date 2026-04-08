#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-chrome}"

if [[ -n "${FLUTTER_BIN:-}" ]] && [[ -x "${FLUTTER_BIN}" ]]; then
  :
elif [[ -x "${HOME}/development/flutter/bin/flutter" ]]; then
  FLUTTER_BIN="${HOME}/development/flutter/bin/flutter"
elif F_PATH="$(command -v flutter 2>/dev/null)" && [[ -n "${F_PATH}" ]]; then
  FLUTTER_BIN="${F_PATH}"
else
  echo "Flutter not found. Put \`flutter\` on PATH or set FLUTTER_BIN=/path/to/flutter/bin/flutter"
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
