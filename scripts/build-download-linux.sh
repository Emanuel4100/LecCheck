#!/usr/bin/env bash
set -euo pipefail

# Builds release Linux bundle and archives it to ../download/
# Usage: from repo root: ./scripts/build-download-linux.sh

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
