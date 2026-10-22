#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Apple app builds require a GitHub-hosted macOS runner." >&2
  exit 1
fi

# The xcode-27 image currently contains Xcode 27.1 RC. Prefer the final app
# when available, but do not silently fall back to Xcode 27.0: Duo support
# specifically needs 27.1.
for candidate in \
  /Applications/Xcode_27.1.app \
  /Applications/Xcode_27.1.0.app \
  /Applications/Xcode_27.1_Release_Candidate.app; do
  if [[ -d "$candidate/Contents/Developer" ]]; then
    sudo xcode-select --switch "$candidate/Contents/Developer"
    version="$(xcodebuild -version)"
    echo "$version"
    if [[ "$version" == *"Xcode 27.1"* ]]; then
      xcodebuild -showsdks
      exit 0
    fi
  fi
done

echo "Xcode 27.1 is missing. Check the xcode-27 image release notes before retrying." >&2
exit 1

