#!/usr/bin/env bash
set -euo pipefail

project="ApplePlatformTemplate.xcodeproj"
if [[ ! -d "$project" ]]; then
  echo "Missing generated project: run xcodegen generate --spec project.yml first." >&2
  exit 1
fi

mkdir -p Artifacts/build

builds=(
  'iOSApp|generic/platform=iOS Simulator'
  'MacApp|platform=macOS'
  'WatchApp|generic/platform=watchOS Simulator'
  'TVApp|generic/platform=tvOS Simulator'
  'VisionApp|generic/platform=visionOS Simulator'
)

for build in "${builds[@]}"; do
  scheme="${build%%|*}"
  destination="${build#*|}"
  echo "::group::Building $scheme ($destination)"

  xcodebuild \
    -project "$project" \
    -scheme "$scheme" \
    -configuration Debug \
    -destination "$destination" \
    -derivedDataPath "${RUNNER_TEMP:-/tmp}/apple-platform-template-derived" \
    CODE_SIGNING_ALLOWED=NO \
    build 2>&1 | tee "Artifacts/build/${scheme}.log"

  echo "::endgroup::"
done

