#!/usr/bin/env bash
set -euo pipefail

# Builds release Linux bundle and archives to your Downloads folder (or LEC_CHECK_OUT_DIR).
# The archive includes install.sh and uninstall.sh inside the bundle.
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

ENV_FILE="${APP_DIR}/.env"
DART_DEFINE_ARGS=()
if [[ -f "${ENV_FILE}" ]]; then
  DART_DEFINE_ARGS+=("--dart-define-from-file=${ENV_FILE}")
fi

echo "Building Linux release (${RAW_VERSION})..."
"${FLUTTER_BIN}" build linux --release "${DART_DEFINE_ARGS[@]}"

BUNDLE="${APP_DIR}/build/linux/x64/release/bundle"
if [[ ! -d "${BUNDLE}" ]]; then
  echo "Expected bundle at ${BUNDLE}"
  exit 1
fi

# --- Write install.sh and uninstall.sh as standalone files ---
_write_install_script() {
  local dest="$1"
  cat > "${dest}" << 'SCRIPTEOF'
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
SCRIPTEOF
  chmod +x "${dest}"
}

_write_uninstall_script() {
  local dest="$1"
  cat > "${dest}" << 'SCRIPTEOF'
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
SCRIPTEOF
  chmod +x "${dest}"
}

_write_install_script "${BUNDLE}/install.sh"
_write_uninstall_script "${BUNDLE}/uninstall.sh"

# --- Copy icon assets into the bundle for install.sh to use ---
APP_ID="com.leccheck.app"
ICON_DEST="${BUNDLE}/data/icons"
mkdir -p "${ICON_DEST}"
for SIZE in 64 128 256 512; do
  SRC="${APP_DIR}/linux/assets/${APP_ID}-${SIZE}.png"
  if [[ -f "${SRC}" ]]; then
    cp "${SRC}" "${ICON_DEST}/${APP_ID}-${SIZE}.png"
  fi
done

# --- Archive ---
ARCHIVE="${OUT_DIR}/leccheck-linux-x64-${FILE_VERSION}.tar.gz"
tar -C "${APP_DIR}/build/linux/x64/release" -czf "${ARCHIVE}" bundle

echo "Done: ${ARCHIVE}"
echo ""
echo "To install after extracting:"
echo "  tar xzf $(basename "${ARCHIVE}")"
echo "  cd bundle"
echo "  ./install.sh"

# Also run desktop integration for the current build
echo ""
echo "Installing desktop integration for this build..."
"${BUNDLE}/install.sh"
