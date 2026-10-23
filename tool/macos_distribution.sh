#!/bin/bash
# Local App Store archive/export and unsigned CI input for Developer ID signing.
set -euo pipefail
cd "$(dirname "$0")/.."

mode="${1:-archive}"
case "$mode" in
  unsigned|archive|export) ;;
  *) echo "Usage: $0 {unsigned|archive|export}" >&2; exit 2 ;;
esac

archive="build/macos/archive/Bugaoshan.xcarchive"
if [ "$mode" = export ]; then
  test -d "$archive"
  xcodebuild -exportArchive -archivePath "$archive" \
    -exportPath build/macos/appstore \
    -exportOptionsPlist macos/ExportOptions-AppStore.plist \
    -allowProvisioningUpdates
  python3 tool/verify_macos_bundle.py build/macos/appstore/不高山上.pkg --package
  exit
fi

export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n

args=(--release --config-only)
if [ "$mode" = archive ]; then
  # Share the release pair with the notarized DMG; Android preview numbering is
  # independent and must not downgrade an already released Mac store version.
  MACOS_BUILD_NAME="${MACOS_BUILD_NAME:-$(python3 -c 'import json; print(json.load(open(".github/macos-signing.json"))["version"])')}"
  MACOS_BUILD_NUMBER="${MACOS_BUILD_NUMBER:-$(python3 -c 'import json; print(json.load(open(".github/macos-signing.json"))["build"])')}"
fi
if [ -n "${MACOS_BUILD_NAME:-}" ]; then args+=(--build-name "$MACOS_BUILD_NAME"); fi
if [ -n "${MACOS_BUILD_NUMBER:-}" ]; then args+=(--build-number "$MACOS_BUILD_NUMBER"); fi
flutter build macos "${args[@]}" \
  --dart-define="GIT_TAG=$(git describe --tags --always --dirty)" \
  --dart-define="GIT_COMMIT=$(git rev-parse HEAD)" \
  --dart-define="GIT_COMMIT_DATE=$(git log -1 --format=%ci)" \
  --dart-define="BUILD_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
(cd macos && pod install)

if [ "$mode" = unsigned ]; then
  xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
    -configuration Release -destination 'generic/platform=macOS' \
    -derivedDataPath build/macos CODE_SIGNING_ALLOWED=NO build
  python3 tool/verify_macos_bundle.py build/macos/Build/Products/Release/不高山上.app
  mkdir -p build/macos/validation
  ditto -c -k --sequesterRsrc --keepParent \
    build/macos/Build/Products/Release/不高山上.app \
    build/macos/validation/Bugaoshan-unsigned.zip
else
  xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
    -configuration Release -destination 'generic/platform=macOS' \
    -derivedDataPath build/macos -archivePath "$archive" -allowProvisioningUpdates archive
  python3 tool/verify_macos_bundle.py "$archive/Products/Applications/不高山上.app" \
    --signed --version "$MACOS_BUILD_NAME" --build "$MACOS_BUILD_NUMBER"
fi
