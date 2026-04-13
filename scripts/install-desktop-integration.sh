#!/usr/bin/env bash
set -euo pipefail

# Installs LecCheck .desktop file and icons to the current user's XDG directories
# so GNOME (and other DEs) show the correct app name and icon in the dock.
#
# Usage:
#   ./scripts/install-desktop-integration.sh [/path/to/leccheck/binary]
#
# If no binary path is given, Exec= in the .desktop will just be "leccheck"
# (assumes it's on PATH or launched via Flatpak).

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINUX_DIR="${ROOT}/flutter_app/linux"
ASSETS_DIR="${LINUX_DIR}/assets"
APP_ID="com.leccheck.app"

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
DESKTOP_DIR="${DATA_DIR}/applications"
ICON_BASE="${DATA_DIR}/icons/hicolor"

BINARY_PATH="${1:-}"

mkdir -p "${DESKTOP_DIR}"

# Write .desktop file with the correct Exec path
if [[ -n "${BINARY_PATH}" ]] && [[ -x "${BINARY_PATH}" ]]; then
  ABS_BIN="$(realpath "${BINARY_PATH}")"
  sed "s|^Exec=.*|Exec=${ABS_BIN} %u|" "${LINUX_DIR}/${APP_ID}.desktop" \
    > "${DESKTOP_DIR}/${APP_ID}.desktop"
else
  cp "${LINUX_DIR}/${APP_ID}.desktop" "${DESKTOP_DIR}/${APP_ID}.desktop"
fi

# Install icons at multiple sizes
for SIZE in 64 128 256 512; do
  ICON_DIR="${ICON_BASE}/${SIZE}x${SIZE}/apps"
  mkdir -p "${ICON_DIR}"
  cp "${ASSETS_DIR}/${APP_ID}-${SIZE}.png" "${ICON_DIR}/${APP_ID}.png"
done

# Refresh icon cache if available
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "${ICON_BASE}" 2>/dev/null || true
fi

# Notify desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
fi

echo "Desktop integration installed:"
echo "  ${DESKTOP_DIR}/${APP_ID}.desktop"
echo "  Icons in ${ICON_BASE}/{64,128,256,512}x{64,128,256,512}/apps/"
