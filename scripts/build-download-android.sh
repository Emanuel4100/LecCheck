#!/usr/bin/env bash
set -euo pipefail

# Builds release APK and copies it to ../download/
# Usage: from repo root: ./scripts/build-download-android.sh

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-$HOME/development/flutter/bin/flutter}"
APP_DIR="${ROOT}/flutter_app"
PUBSPEC="${APP_DIR}/pubspec.yaml"
OUT_DIR="${ROOT}/download"

if [[ ! -x "${FLUTTER_BIN}" ]]; then
  echo "Flutter not found at ${FLUTTER_BIN}"
  echo "Set FLUTTER_BIN or install Flutter."
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
