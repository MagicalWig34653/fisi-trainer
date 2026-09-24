#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 OUTPUT_DIRECTORY VERSION_TAG (for example v1.0.0)" >&2
  exit 2
fi

output_dir=$1
version_tag=$2
if [[ ! $version_tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version tag must look like v1.0.0" >&2
  exit 2
fi

script_dir=$(cd "$(dirname "$0")" && pwd)
project_dir=$(cd "$script_dir/.." && pwd)
mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd)
derived_data="$output_dir/DerivedData"
built_app="$derived_data/Build/Products/Release/FiSiTrainer.app"
app="$output_dir/Stage/FiSiTrainer.app"
dmg="$output_dir/FiSiTrainer-$version_tag-macOS-universal.dmg"
checksum="$dmg.sha256"

xcodebuild build \
  -project "$project_dir/FiSiTrainer.xcodeproj" \
  -scheme FiSiTrainer \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$derived_data" \
  "MARKETING_VERSION=${version_tag#v}" \
  'ARCHS=arm64 x86_64' \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO

if [[ ! -d $built_app ]]; then
  echo "Built app not found: $built_app" >&2
  exit 1
fi

architectures=$(lipo -archs "$built_app/Contents/MacOS/FiSiTrainer")
if [[ " $architectures " != *" arm64 "* || " $architectures " != *" x86_64 "* ]]; then
  echo "Expected arm64 and x86_64 slices; found: $architectures" >&2
  exit 1
fi

# Copy into a clean staging bundle so Finder metadata cannot break signing.
rm -rf "$app"
mkdir -p "$(dirname "$app")"
ditto --norsrc --noextattr --noqtn "$built_app" "$app"
actual_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
  "$app/Contents/Info.plist")
if [[ $actual_version != "${version_tag#v}" ]]; then
  echo "App version $actual_version does not match release tag $version_tag" >&2
  exit 1
fi

# This is an ad-hoc signature. Public downloads are not notarized.
codesign --force --sign - \
  --entitlements "$project_dir/FiSiTrainer/FiSiTrainer.entitlements" \
  "$app"
codesign --verify --deep --strict "$app"

bash "$script_dir/create-dmg.sh" "$app" "$dmg"
(
  cd "$output_dir"
  shasum -a 256 "$(basename "$dmg")" > "$(basename "$checksum")"
)

echo "Release package: $dmg"
echo "SHA-256: $checksum"
