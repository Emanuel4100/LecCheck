#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# LecCheck Release Script
# =============================================================================
# Bumps the version, builds Linux + Android, and collects artifacts in
# releases/vX.Y.Z/ ready for GitHub Release upload.
#
# Usage:
#   ./scripts/release.sh              # interactive version-bump prompt
#   ./scripts/release.sh --major      # non-interactive: bump major
#   ./scripts/release.sh --minor      # non-interactive: bump minor
#   ./scripts/release.sh --hotfix     # non-interactive: bump patch
#   ./scripts/release.sh --publish    # also create GitHub Release via gh CLI
# =============================================================================

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT}/flutter_app"
PUBSPEC="${APP_DIR}/pubspec.yaml"
RELEASES_DIR="${ROOT}/releases"
APP_ID="com.leccheck.app"

PUBLISH=false
BUMP_TYPE=""

for arg in "$@"; do
  case "${arg}" in
    --major)   BUMP_TYPE="major" ;;
    --minor)   BUMP_TYPE="minor" ;;
    --hotfix)  BUMP_TYPE="hotfix" ;;
    --publish) PUBLISH=true ;;
    --help|-h)
      echo "Usage: $0 [--major|--minor|--hotfix] [--publish]"
      echo ""
      echo "  --major    Bump major version  (X+1.0.0)"
      echo "  --minor    Bump minor version  (X.Y+1.0)"
      echo "  --hotfix   Bump patch version  (X.Y.Z+1)"
      echo "  --publish  Create a GitHub Release via gh CLI after building"
      echo ""
      echo "Without flags, the script will prompt interactively."
      exit 0
      ;;
    *) echo "Unknown flag: ${arg}. Use --help for usage."; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve Flutter
# ---------------------------------------------------------------------------
if [[ -n "${FLUTTER_BIN:-}" ]] && [[ -x "${FLUTTER_BIN}" ]]; then
  :
elif [[ -x "${HOME}/development/flutter/bin/flutter" ]]; then
  FLUTTER_BIN="${HOME}/development/flutter/bin/flutter"
elif F_PATH="$(command -v flutter 2>/dev/null)" && [[ -n "${F_PATH}" ]]; then
  FLUTTER_BIN="${F_PATH}"
else
  echo "Error: Flutter not found."
  echo "Set FLUTTER_BIN or add flutter to your PATH."
  exit 1
fi

if [[ ! -f "${PUBSPEC}" ]]; then
  echo "Error: ${PUBSPEC} not found."
  exit 1
fi

# ---------------------------------------------------------------------------
# Parse current version from pubspec.yaml
# ---------------------------------------------------------------------------
RAW_LINE="$(grep -E '^version:' "${PUBSPEC}" | head -1)"
RAW_VERSION="$(echo "${RAW_LINE}" | sed 's/^version:[[:space:]]*//' | tr -d '\r')"

# Split "0.7.2+1" into semver "0.7.2" and build number "1"
SEMVER="${RAW_VERSION%%+*}"
BUILD_NUM="${RAW_VERSION#*+}"
if [[ "${BUILD_NUM}" == "${RAW_VERSION}" ]]; then
  BUILD_NUM="1"
fi

IFS='.' read -r V_MAJOR V_MINOR V_PATCH <<< "${SEMVER}"

echo "========================================"
echo "  LecCheck Release Builder"
echo "========================================"
echo ""
echo "  Current version: ${SEMVER}+${BUILD_NUM}"
echo ""

# ---------------------------------------------------------------------------
# Version bump prompt
# ---------------------------------------------------------------------------
if [[ -z "${BUMP_TYPE}" ]]; then
  echo "  What kind of release?"
  echo ""
  echo "    1) major  — $(( V_MAJOR + 1 )).0.0   (breaking changes / big milestone)"
  echo "    2) minor  — ${V_MAJOR}.$(( V_MINOR + 1 )).0   (new features)"
  echo "    3) hotfix — ${V_MAJOR}.${V_MINOR}.$(( V_PATCH + 1 ))   (bug fixes)"
  echo ""
  read -rp "  Choose [1/2/3]: " CHOICE
  case "${CHOICE}" in
    1|major)  BUMP_TYPE="major" ;;
    2|minor)  BUMP_TYPE="minor" ;;
    3|hotfix) BUMP_TYPE="hotfix" ;;
    *) echo "Invalid choice."; exit 1 ;;
  esac
fi

case "${BUMP_TYPE}" in
  major)
    V_MAJOR=$(( V_MAJOR + 1 ))
    V_MINOR=0
    V_PATCH=0
    ;;
  minor)
    V_MINOR=$(( V_MINOR + 1 ))
    V_PATCH=0
    ;;
  hotfix)
    V_PATCH=$(( V_PATCH + 1 ))
    ;;
esac

NEW_BUILD=$(( BUILD_NUM + 1 ))
NEW_SEMVER="${V_MAJOR}.${V_MINOR}.${V_PATCH}"
NEW_VERSION="${NEW_SEMVER}+${NEW_BUILD}"
TAG_NAME="v${NEW_SEMVER}"
FILE_VERSION="${NEW_SEMVER}-${NEW_BUILD}"

echo ""
echo "  Bumping: ${RAW_VERSION} → ${NEW_VERSION}  (tag: ${TAG_NAME})"
echo ""

# ---------------------------------------------------------------------------
# Apply version to pubspec.yaml
# ---------------------------------------------------------------------------
sed -i "s/^version:.*$/version: ${NEW_VERSION}/" "${PUBSPEC}"
echo "  ✓ Updated ${PUBSPEC}"

# ---------------------------------------------------------------------------
# Prepare output directory and env file
# ---------------------------------------------------------------------------
OUT_DIR="${RELEASES_DIR}/${TAG_NAME}"
mkdir -p "${OUT_DIR}"

ENV_FILE="${APP_DIR}/.env"
DART_DEFINE_ARGS=()
if [[ -f "${ENV_FILE}" ]]; then
  DART_DEFINE_ARGS+=("--dart-define-from-file=${ENV_FILE}")
fi

# ---------------------------------------------------------------------------
# Build Android APK
# ---------------------------------------------------------------------------
echo ""
echo "  Building Android APK..."
cd "${APP_DIR}"
"${FLUTTER_BIN}" build apk --release "${DART_DEFINE_ARGS[@]}"

APK_SRC="${APP_DIR}/build/app/outputs/flutter-apk/app-release.apk"
APK_DEST="${OUT_DIR}/leccheck-android-${FILE_VERSION}.apk"
if [[ -f "${APK_SRC}" ]]; then
  cp -f "${APK_SRC}" "${APK_DEST}"
  echo "  ✓ ${APK_DEST}"
else
  echo "  ✗ APK not found at ${APK_SRC}"
fi

# ---------------------------------------------------------------------------
# Build Linux bundle
# ---------------------------------------------------------------------------
echo ""
echo "  Building Linux bundle..."
"${FLUTTER_BIN}" build linux --release "${DART_DEFINE_ARGS[@]}"

BUNDLE="${APP_DIR}/build/linux/x64/release/bundle"
if [[ ! -d "${BUNDLE}" ]]; then
  echo "  ✗ Bundle not found at ${BUNDLE}"
else
  # Inject install.sh
  cat > "${BUNDLE}/install.sh" << 'SCRIPTEOF'
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
  chmod +x "${BUNDLE}/install.sh"

  # Inject uninstall.sh
  cat > "${BUNDLE}/uninstall.sh" << 'SCRIPTEOF'
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
  chmod +x "${BUNDLE}/uninstall.sh"

  # Copy icons into the bundle
  ICON_DEST="${BUNDLE}/data/icons"
  mkdir -p "${ICON_DEST}"
  for SIZE in 64 128 256 512; do
    SRC="${APP_DIR}/linux/assets/${APP_ID}-${SIZE}.png"
    if [[ -f "${SRC}" ]]; then
      cp "${SRC}" "${ICON_DEST}/${APP_ID}-${SIZE}.png"
    fi
  done

  # Archive
  LINUX_ARCHIVE="${OUT_DIR}/leccheck-linux-x64-${FILE_VERSION}.tar.gz"
  tar -C "${APP_DIR}/build/linux/x64/release" -czf "${LINUX_ARCHIVE}" bundle
  echo "  ✓ ${LINUX_ARCHIVE}"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "========================================"
echo "  Release ${TAG_NAME} ready!"
echo "========================================"
echo ""
echo "  Artifacts in: ${OUT_DIR}/"
ls -1h "${OUT_DIR}/"
echo ""

# ---------------------------------------------------------------------------
# Git tag + GitHub Release (optional)
# ---------------------------------------------------------------------------
if [[ "${PUBLISH}" == true ]]; then
  echo "  Creating git tag ${TAG_NAME}..."
  cd "${ROOT}"
  git add "${PUBSPEC}"
  git commit -m "release: bump version to ${NEW_VERSION}" || true
  git tag -a "${TAG_NAME}" -m "Release ${TAG_NAME}"
  git push origin HEAD --follow-tags

  if command -v gh >/dev/null 2>&1; then
    echo "  Creating GitHub Release..."
    RELEASE_NOTES="## LecCheck ${TAG_NAME}

### Downloads
- **Android**: \`leccheck-android-${FILE_VERSION}.apk\`
- **Linux**: \`leccheck-linux-x64-${FILE_VERSION}.tar.gz\` (extract and run \`./install.sh\`)
"
    gh release create "${TAG_NAME}" \
      --title "LecCheck ${TAG_NAME}" \
      --notes "${RELEASE_NOTES}" \
      "${OUT_DIR}"/*

    echo ""
    echo "  ✓ GitHub Release created!"
    echo "  $(gh release view "${TAG_NAME}" --json url -q .url)"
  else
    echo "  gh CLI not found — skipping GitHub Release."
    echo "  Install it (https://cli.github.com) or upload manually:"
    echo "    gh release create ${TAG_NAME} ${OUT_DIR}/*"
  fi
else
  echo "  Next steps:"
  echo ""
  echo "    # Commit the version bump"
  echo "    git add flutter_app/pubspec.yaml"
  echo "    git commit -m 'release: bump version to ${NEW_VERSION}'"
  echo ""
  echo "    # Tag and push"
  echo "    git tag -a ${TAG_NAME} -m 'Release ${TAG_NAME}'"
  echo "    git push origin HEAD --follow-tags"
  echo ""
  echo "    # Create GitHub Release (uploads all artifacts)"
  echo "    gh release create ${TAG_NAME} --title 'LecCheck ${TAG_NAME}' ${OUT_DIR}/*"
  echo ""
  echo "  Or re-run with --publish to do it all automatically:"
  echo "    ./scripts/release.sh --publish"
fi
