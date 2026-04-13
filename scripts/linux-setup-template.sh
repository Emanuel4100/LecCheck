#!/usr/bin/env bash
set -euo pipefail

# Interactive install/uninstall for the extracted Linux bundle.
# Non-interactive: ./setup.sh install | ./setup.sh uninstall

APP_ID="com.leccheck.app"
APP_NAME="LecCheck"
BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="${BUNDLE_DIR}/leccheck"

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_FILE="${DATA_DIR}/applications/${APP_ID}.desktop"
DESKTOP_DIR="${DATA_DIR}/applications"
ICON_BASE="${DATA_DIR}/icons/hicolor"
SYMLINK="${BIN_DIR}/leccheck"

refresh_menus() {
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "${ICON_BASE}" 2>/dev/null || true
  fi
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
  fi
}

do_install() {
  if [[ ! -x "${BINARY}" ]]; then
    echo "Error: ${BINARY} not found or not executable."
    echo "Run this script from inside the extracted bundle directory."
    exit 1
  fi

  echo "Installing ${APP_NAME} from this bundle..."

  mkdir -p "${BIN_DIR}"
  ln -sf "${BINARY}" "${SYMLINK}"

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
  } > "${DESKTOP_FILE}"

  for SIZE in 64 128 256 512; do
    ICON_SRC="${BUNDLE_DIR}/data/icons/${APP_ID}-${SIZE}.png"
    if [[ -f "${ICON_SRC}" ]]; then
      ICON_DIR="${ICON_BASE}/${SIZE}x${SIZE}/apps"
      mkdir -p "${ICON_DIR}"
      cp "${ICON_SRC}" "${ICON_DIR}/${APP_ID}.png"
    fi
  done

  refresh_menus

  echo ""
  echo "${APP_NAME} installed successfully!"
  echo "  Binary:  ${BINARY}"
  echo "  Symlink: ${SYMLINK}"
  echo "  Desktop: ${DESKTOP_FILE}"
  echo ""
  echo "Launch from your app menu or run: leccheck"
  echo "Run ${BUNDLE_DIR}/setup.sh again to update from another folder or uninstall."
}

do_uninstall() {
  echo "Uninstalling ${APP_NAME} (user integration only; this folder is kept)..."

  if [[ -L "${SYMLINK}" ]]; then
    rm -f "${SYMLINK}"
    echo "  Removed ${SYMLINK}"
  fi

  if [[ -f "${DESKTOP_FILE}" ]]; then
    rm -f "${DESKTOP_FILE}"
    echo "  Removed ${DESKTOP_FILE}"
  fi

  for SIZE in 64 128 256 512; do
    ICON="${ICON_BASE}/${SIZE}x${SIZE}/apps/${APP_ID}.png"
    if [[ -f "${ICON}" ]]; then
      rm -f "${ICON}"
      echo "  Removed ${ICON}"
    fi
  done

  refresh_menus

  echo ""
  echo "${APP_NAME} uninstalled."
  echo "You can delete this bundle directory if you no longer need it."
}

desktop_present() {
  [[ -f "${DESKTOP_FILE}" ]]
}

symlink_present() {
  [[ -L "${SYMLINK}" ]]
}

installed_marker() {
  desktop_present || symlink_present
}

print_status() {
  echo "Installation status for this user:"
  if desktop_present; then
    echo "  • Desktop menu entry: present"
  else
    echo "  • Desktop menu entry: not found"
  fi
  if symlink_present; then
    local target
    target="$(readlink -f "${SYMLINK}" 2>/dev/null || readlink "${SYMLINK}" 2>/dev/null || true)"
    echo "  • Command 'leccheck' (~/.local/bin): symlink → ${target:-?}"
  else
    echo "  • Command 'leccheck' (~/.local/bin): not found"
  fi
  if installed_marker; then
    echo ""
    echo "Overall: LecCheck appears to be installed."
  else
    echo ""
    echo "Overall: LecCheck does not appear to be installed."
  fi
}

interactive_menu() {
  echo "=== ${APP_NAME} — setup ==="
  echo "Bundle directory: ${BUNDLE_DIR}"
  echo ""
  print_status
  echo ""
  echo "What do you want to do?"
  echo "  1) Install or update (point menu + leccheck at this bundle)"
  echo "  2) Uninstall (remove menu entry, icons, ~/.local/bin/leccheck)"
  echo "  q) Quit"
  echo ""
  local default="1"
  read -r -p "Enter choice [${default}]: " choice
  choice="${choice:-$default}"

  case "${choice}" in
    1|i|I|install|Install)
      do_install
      ;;
    2|u|U|uninstall|Uninstall|remove|Remove)
      if ! installed_marker; then
        echo "Nothing to uninstall (no desktop entry and no leccheck symlink)."
        exit 0
      fi
      read -r -p "Remove LecCheck from your menu and PATH? [y/N] " confirm
      case "${confirm}" in
        y|Y|yes|Yes) do_uninstall ;;
        *) echo "Cancelled."; exit 0 ;;
      esac
      ;;
    q|Q|quit|Quit)
      echo "Bye."
      exit 0
      ;;
    *)
      echo "Invalid choice."
      exit 1
      ;;
  esac
}

case "${1:-}" in
  install)
    do_install
    ;;
  uninstall)
    do_uninstall
    ;;
  ""|-h|--help|help)
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == help ]]; then
      echo "Usage: $0 [install|uninstall]"
      echo "  (no args)  interactive menu — detects install state and asks what to do"
      echo "  install    install or update from this bundle (non-interactive)"
      echo "  uninstall  remove desktop integration (non-interactive)"
      exit 0
    fi
    interactive_menu
    ;;
  *)
    echo "Unknown argument: $1"
    echo "Run: $0 --help"
    exit 1
    ;;
esac
