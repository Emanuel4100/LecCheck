#!/usr/bin/env bash
set -euo pipefail

APP_ID="com.leccheck.app"
APP_NAME="LecCheck"

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${DATA_DIR}/applications"
ICON_BASE="${DATA_DIR}/icons/hicolor"

echo "Uninstalling ${APP_NAME}..."

if [[ -L "${BIN_DIR}/leccheck" ]]; then
  rm -f "${BIN_DIR}/leccheck"
  echo "  Removed ${BIN_DIR}/leccheck"
fi

if [[ -f "${DESKTOP_DIR}/${APP_ID}.desktop" ]]; then
  rm -f "${DESKTOP_DIR}/${APP_ID}.desktop"
  echo "  Removed ${DESKTOP_DIR}/${APP_ID}.desktop"
fi

for SIZE in 64 128 256 512; do
  ICON="${ICON_BASE}/${SIZE}x${SIZE}/apps/${APP_ID}.png"
  if [[ -f "${ICON}" ]]; then
    rm -f "${ICON}"
    echo "  Removed ${ICON}"
  fi
done

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "${ICON_BASE}" 2>/dev/null || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
fi

echo ""
echo "${APP_NAME} uninstalled."
echo "You can now delete this bundle directory if you want."
