#!/usr/bin/env bash
set -euo pipefail

# Builds release Linux bundle and archives to your Downloads folder (or LEC_CHECK_OUT_DIR).
# Usage: from repo root: ./scripts/build-download-linux.sh

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

# version: 0.6.0+1 -> 0.6.0-1 for filenames
RAW_VERSION="$(grep -E '^version:' "${PUBSPEC}" | head -1 | sed 's/^version:[[:space:]]*//' | tr -d '\r')"
FILE_VERSION="${RAW_VERSION//+/-}"

mkdir -p "${OUT_DIR}"
cd "${APP_DIR}"

echo "Building Linux release (${RAW_VERSION})..."
"${FLUTTER_BIN}" build linux --release

BUNDLE="${APP_DIR}/build/linux/x64/release/bundle"
if [[ ! -d "${BUNDLE}" ]]; then
  echo "Expected bundle at ${BUNDLE}"
  exit 1
fi

ARCHIVE="${OUT_DIR}/leccheck-linux-x64-${FILE_VERSION}.tar.gz"
tar -C "${APP_DIR}/build/linux/x64/release" -czf "${ARCHIVE}" bundle

echo "Done: ${ARCHIVE}"
