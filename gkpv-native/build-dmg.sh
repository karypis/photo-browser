#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="GK Photo Viewer"
BUNDLE_NAME="${APP_NAME}.app"
DMG_NAME="GKPhotoViewer.dmg"
BUILD_DIR="${SCRIPT_DIR}/.build/release"
STAGING_DIR=$(mktemp -d)

trap "rm -rf '$STAGING_DIR'" EXIT

echo "==> Building release..."
cd "$SCRIPT_DIR"
swift build -c release

echo "==> Creating app bundle..."
mkdir -p "${STAGING_DIR}/${BUNDLE_NAME}/Contents/"{MacOS,Resources}

cat > "${STAGING_DIR}/${BUNDLE_NAME}/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>GK Photo Viewer</string>
    <key>CFBundleDisplayName</key>
    <string>GK Photo Viewer</string>
    <key>CFBundleIdentifier</key>
    <string>com.karypis.gkphotoviewer</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>GKPhotoViewer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright 2026 karypis. MIT License.</string>
</dict>
</plist>
PLIST

cp "${BUILD_DIR}/GKPhotoViewer" "${STAGING_DIR}/${BUNDLE_NAME}/Contents/MacOS/GKPhotoViewer"
chmod +x "${STAGING_DIR}/${BUNDLE_NAME}/Contents/MacOS/GKPhotoViewer"

ln -s /Applications "${STAGING_DIR}/Applications"

echo "==> Creating DMG..."
rm -f "${SCRIPT_DIR}/${DMG_NAME}"
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov -format UDZO \
    "${SCRIPT_DIR}/${DMG_NAME}"

echo ""
echo "==> Done: ${SCRIPT_DIR}/${DMG_NAME}"
ls -lh "${SCRIPT_DIR}/${DMG_NAME}"
