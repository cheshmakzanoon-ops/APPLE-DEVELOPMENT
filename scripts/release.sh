#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Release must run on a macOS runner." >&2
  exit 1
fi

for required in APPLE_TEAM_ID APP_STORE_CONNECT_KEY_ID APP_STORE_CONNECT_ISSUER_ID APP_STORE_CONNECT_PRIVATE_KEY_BASE64 RELEASE_PLATFORM; do
  if [[ -z "${!required:-}" ]]; then
    echo "Missing required GitHub environment secret/input: $required" >&2
    exit 1
  fi
done

if grep -q 'dev.example.appleplatformtemplate' project.yml; then
  echo "Replace ALL example PRODUCT_BUNDLE_IDENTIFIER values in project.yml before releasing." >&2
  exit 1
fi

case "$RELEASE_PLATFORM" in
  ios) scheme=iOSApp; destination='generic/platform=iOS' ;;
  macos) scheme=MacApp; destination='generic/platform=macOS' ;;
  watchos) scheme=WatchApp; destination='generic/platform=watchOS' ;;
  tvos) scheme=TVApp; destination='generic/platform=tvOS' ;;
  visionos) scheme=VisionApp; destination='generic/platform=visionOS' ;;
  *) echo "Unsupported platform: $RELEASE_PLATFORM" >&2; exit 1 ;;
esac

if [[ ! -d ApplePlatformTemplate.xcodeproj ]]; then
  echo "Generate the Xcode project before releasing." >&2
  exit 1
fi

key_directory="$(mktemp -d)"
key_path="$key_directory/AuthKey_${APP_STORE_CONNECT_KEY_ID}.p8"
trap 'rm -f "$key_path"; rmdir "$key_directory"' EXIT

printf '%s' "$APP_STORE_CONNECT_PRIVATE_KEY_BASE64" | base64 -D > "$key_path"
chmod 600 "$key_path"

archive="${RUNNER_TEMP:-/tmp}/${scheme}.xcarchive"
export_directory="${RUNNER_TEMP:-/tmp}/${scheme}-export"

xcodebuild \
  -project ApplePlatformTemplate.xcodeproj \
  -scheme "$scheme" \
  -configuration Release \
  -destination "$destination" \
  -archivePath "$archive" \
  -authenticationKeyPath "$key_path" \
  -authenticationKeyID "$APP_STORE_CONNECT_KEY_ID" \
  -authenticationKeyIssuerID "$APP_STORE_CONNECT_ISSUER_ID" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  archive

# destination=upload in ExportOptions.plist asks Xcode to send this build to
# App Store Connect. It does not submit the build for App Review.
xcodebuild \
  -exportArchive \
  -archivePath "$archive" \
  -exportPath "$export_directory" \
  -exportOptionsPlist Config/ExportOptions.plist \
  -authenticationKeyPath "$key_path" \
  -authenticationKeyID "$APP_STORE_CONNECT_KEY_ID" \
  -authenticationKeyIssuerID "$APP_STORE_CONNECT_ISSUER_ID" \
  -allowProvisioningUpdates

echo "Upload requested for $scheme. Confirm build processing in App Store Connect."

