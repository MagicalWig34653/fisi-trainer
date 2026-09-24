#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 APP_PATH OUTPUT_DMG" >&2
  exit 2
fi

app_path=$1
output_dmg=$2
script_dir=$(cd "$(dirname "$0")" && pwd)
project_dir=$(cd "$script_dir/.." && pwd)

if [[ $(uname -s) != Darwin ]]; then
  echo "DMG creation requires macOS." >&2
  exit 1
fi
if [[ $(basename "$app_path") != FiSiTrainer.app || ! -f "$app_path/Contents/Info.plist" ||
      ! -f "$app_path/Contents/MacOS/FiSiTrainer" ]]; then
  echo "Expected a built FiSiTrainer.app bundle: $app_path" >&2
  exit 2
fi
if [[ ${output_dmg##*.} != dmg ]]; then
  echo "Output path must end in .dmg" >&2
  exit 2
fi

app_path=$(cd "$(dirname "$app_path")" && pwd)/FiSiTrainer.app
mkdir -p "$(dirname "$output_dmg")"
output_dmg=$(cd "$(dirname "$output_dmg")" && pwd)/$(basename "$output_dmg")

background="$project_dir/Packaging/dmg-background.png"
background_2x="$project_dir/Packaging/dmg-background@2x.png"
if [[ ! -f $background || ! -f $background_2x ]]; then
  echo "Both 1x and 2x DMG backgrounds are required in Packaging/." >&2
  exit 1
fi
for image in "$background:760x500" "$background_2x:1520x1000"; do
  path=${image%:*}
  expected=${image##*:}
  actual=$(sips -g pixelWidth -g pixelHeight "$path" | \
    awk '/pixelWidth:/{width=$2} /pixelHeight:/{height=$2} END{print width "x" height}')
  if [[ $actual != "$expected" ]]; then
    echo "Wrong DMG background size for $path: expected $expected, got $actual" >&2
    exit 1
  fi
done

# Preserve the source app. A valid signature is required before packaging.
codesign --verify --deep --strict "$app_path"

venv_dir=$(mktemp -d "${TMPDIR:-/tmp}/fisi-dmgbuild.XXXXXX")
trap 'rm -rf "$venv_dir"' EXIT
python3 -m venv "$venv_dir"
"$venv_dir/bin/python" -m pip install --disable-pip-version-check --quiet \
  -r "$project_dir/Packaging/requirements-dmg.txt"

rm -f "$output_dmg"
"$venv_dir/bin/dmgbuild" \
  -s "$project_dir/Packaging/dmg-settings.py" \
  -D "app=$app_path" \
  -D "background=$background" \
  "FiSi Trainer" "$output_dmg"
hdiutil verify "$output_dmg"
echo "DMG created: $output_dmg"
