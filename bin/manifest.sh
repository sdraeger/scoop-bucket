#!/usr/bin/env bash
# Writes bucket/ddalab.json for the latest DDALAB release (pre-releases excluded) that has a Windows archive.
# Needs gh with a token (GH_TOKEN). Exits 0 without a change when the release has no archive yet.
set -euo pipefail
asset=ddalab-x86_64-pc-windows-msvc.zip
tag="$(gh release view --repo sdraeger/DDALAB --json tagName --jq .tagName)"
dir="$(mktemp -d)"
if ! gh release download "$tag" --repo sdraeger/DDALAB --pattern "$asset.sha256" --dir "$dir"; then
  echo "$tag has no $asset yet"
  exit 0
fi
hash="$(cut -d ' ' -f 1 "$dir/$asset.sha256")"
[[ "$hash" =~ ^[0-9a-f]{64}$ ]] || { echo "Unexpected checksum file: $(cat "$dir/$asset.sha256")" >&2; exit 1; }
version="${tag#v}"
cat > bucket/ddalab.json <<JSON
{
  "version": "$version",
  "description": "Delay differential analysis of EEG, iEEG and other multichannel recordings: the ddalab command line",
  "homepage": "https://github.com/sdraeger/DDALAB",
  "license": "MIT",
  "architecture": {
    "64bit": {
      "url": "https://github.com/sdraeger/DDALAB/releases/download/$tag/$asset",
      "hash": "$hash"
    }
  },
  "bin": "ddalab.exe",
  "checkver": "github",
  "autoupdate": {
    "architecture": {
      "64bit": {
        "url": "https://github.com/sdraeger/DDALAB/releases/download/v\$version/$asset",
        "hash": {
          "url": "\$url.sha256"
        }
      }
    }
  }
}
JSON
echo "bucket/ddalab.json: $version"
