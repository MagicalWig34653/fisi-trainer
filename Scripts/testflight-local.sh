#!/usr/bin/env bash
# Archiviert die iOS-App mit dem lokalen Xcode und lädt sie zu TestFlight hoch.
#
# Voraussetzung: In Xcode (Einstellungen > Accounts) ist die Apple-ID des Entwicklerteams angemeldet.
# Optional lässt sich stattdessen ein App-Store-Connect-API-Schlüssel mit der Rolle Admin verwenden:
#   ASC_KEY_PATH=/pfad/AuthKey_XXXX.p8 ASC_KEY_ID=XXXX ASC_ISSUER_ID=... Scripts/testflight-local.sh
set -euo pipefail

if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [MARKETING_VERSION]  (for example 1.5.0)" >&2
  exit 2
fi
version=${1:-}
if [[ -n $version && ! $version =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
  echo "Version must look like 1.5.0" >&2
  exit 2
fi

script_dir=$(cd "$(dirname "$0")" && pwd)
project_dir=$(cd "$script_dir/.." && pwd)
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/fisi-testflight.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT

# Die Build-Nummer muss bei jedem Upload steigen. Der UTC-Zeitstempel tut das ohne Zähler.
build_number=$(date -u +%Y%m%d%H%M)

auth=(-allowProvisioningUpdates)
if [[ -n ${ASC_KEY_PATH:-} ]]; then
  : "${ASC_KEY_ID:?ASC_KEY_ID fehlt}" "${ASC_ISSUER_ID:?ASC_ISSUER_ID fehlt}"
  auth+=(-authenticationKeyPath "$ASC_KEY_PATH"
         -authenticationKeyID "$ASC_KEY_ID"
         -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi

overrides=("CURRENT_PROJECT_VERSION=$build_number")
if [[ -n $version ]]; then
  overrides+=("MARKETING_VERSION=$version")
fi

echo "Archiviere Build $build_number${version:+ (Version $version)} ..."
xcodebuild archive \
  -project "$project_dir/FiSiTrainer.xcodeproj" \
  -scheme FiSiTrainer \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$work_dir/FiSiTrainer.xcarchive" \
  -derivedDataPath "$work_dir/DerivedData" \
  "${auth[@]}" "${overrides[@]}"

echo "Lade zu TestFlight hoch ..."
xcodebuild -exportArchive \
  -archivePath "$work_dir/FiSiTrainer.xcarchive" \
  -exportPath "$work_dir/export" \
  -exportOptionsPlist "$project_dir/Packaging/ExportOptions-TestFlight.plist" \
  "${auth[@]}"

echo "Fertig. Der Build erscheint nach der Verarbeitung durch Apple (einige Minuten) in TestFlight."
