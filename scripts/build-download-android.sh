#!/usr/bin/env bash
set -euo pipefail

# Builds release APK and copies it to your Downloads folder (or LEC_CHECK_OUT_DIR).
# Usage: from repo root: ./scripts/build-download-android.sh

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT}/flutter_app"
PUBSPEC="${APP_DIR}/pubspec.yaml"

if [[ -n "${LEC_CHECK_OUT_DIR:-}" ]]; then
  OUT_DIR="${LEC_CHECK_OUT_DIR}"
elif command -v xdg-user-dir >/dev/null 2>&1; then
  OUT_DIR="$(xdg-user-dir DOWNLOAD 2>/dev/null || true)"
fi
if [[ -z "${OUT_DIR:-}" ]]; then
  OUT_DIR="${HOME}/Downloads"
fi

# Prefer explicit FLUTTER_BIN, then ~/development/flutter, then flutter on PATH
if [[ -n "${FLUTTER_BIN:-}" ]] && [[ -x "${FLUTTER_BIN}" ]]; then
  :
elif [[ -x "${HOME}/development/flutter/bin/flutter" ]]; then
  FLUTTER_BIN="${HOME}/development/flutter/bin/flutter"
elif F_PATH="$(command -v flutter 2>/dev/null)" && [[ -n "${F_PATH}" ]]; then
  FLUTTER_BIN="${F_PATH}"
else
  echo "Flutter not found."
  echo "Install Flutter and ensure \`flutter\` is on your PATH, or set e.g.:"
  echo "  export FLUTTER_BIN=/path/to/flutter/bin/flutter"
  exit 1
fi

if [[ ! -f "${PUBSPEC}" ]]; then
  echo "Missing ${PUBSPEC}"
  exit 1
fi

RAW_VERSION="$(grep -E '^version:' "${PUBSPEC}" | head -1 | sed 's/^version:[[:space:]]*//' | tr -d '\r')"
FILE_VERSION="${RAW_VERSION//+/-}"

mkdir -p "${OUT_DIR}"
cd "${APP_DIR}"

echo "Building Android APK (${RAW_VERSION})..."
"${FLUTTER_BIN}" build apk --release

SRC="${APP_DIR}/build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "${SRC}" ]]; then
  echo "Expected APK at ${SRC}"
  exit 1
fi

DEST="${OUT_DIR}/leccheck-android-${FILE_VERSION}.apk"
cp -f "${SRC}" "${DEST}"

echo "Done: ${DEST}"
echo "Note: For Google Play use \`flutter build appbundle\` (AAB), not this APK script."
