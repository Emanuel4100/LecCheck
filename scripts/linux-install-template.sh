#!/usr/bin/env bash
set -euo pipefail

APP_ID="com.leccheck.app"
APP_NAME="LecCheck"
BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="${BUNDLE_DIR}/leccheck"

if [[ ! -x "${BINARY}" ]]; then
  echo "Error: ${BINARY} not found or not executable."
  echo "Run this script from inside the extracted bundle directory."
  exit 1
fi

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${DATA_DIR}/applications"
ICON_BASE="${DATA_DIR}/icons/hicolor"

echo "Installing ${APP_NAME}..."

mkdir -p "${BIN_DIR}"
ln -sf "${BINARY}" "${BIN_DIR}/leccheck"

mkdir -p "${DESKTOP_DIR}"
{
  echo "[Desktop Entry]"
  echo "Version=1.0"
  echo "Type=Application"
  echo "Name=${APP_NAME}"
  echo "GenericName=Lecture schedule"
  echo "Comment=Track lectures, attendance, and your semester schedule"
  echo "Exec=${BINARY} %u"
  echo "Icon=${APP_ID}"
  echo "Terminal=false"
  echo "Categories=Education;Office;"
  echo "StartupNotify=true"
  echo "StartupWMClass=${APP_ID}"
  echo "Keywords=lecture;schedule;school;university;calendar;"
  echo "MimeType="
} > "${DESKTOP_DIR}/${APP_ID}.desktop"

for SIZE in 64 128 256 512; do
  ICON_SRC="${BUNDLE_DIR}/data/icons/${APP_ID}-${SIZE}.png"
  if [[ -f "${ICON_SRC}" ]]; then
    ICON_DIR="${ICON_BASE}/${SIZE}x${SIZE}/apps"
    mkdir -p "${ICON_DIR}"
    cp "${ICON_SRC}" "${ICON_DIR}/${APP_ID}.png"
  fi
done

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "${ICON_BASE}" 2>/dev/null || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
fi

echo ""
echo "${APP_NAME} installed successfully!"
echo "  Binary:  ${BINARY}"
echo "  Symlink: ${BIN_DIR}/leccheck"
echo "  Desktop: ${DESKTOP_DIR}/${APP_ID}.desktop"
echo ""
echo "You can launch it from your application menu or run: leccheck"
echo "To uninstall, run: ${BUNDLE_DIR}/uninstall.sh"
