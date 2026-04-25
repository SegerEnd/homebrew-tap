#!/bin/bash
# Bump Formula/emulicious.rb to the latest upstream release.
# Reads the authoritative date from WhatsNew.txt inside the rolling-latest zip
# (same approach as the AUR `emulicious-bin` PKGBUILD).
# Writes current=, latest=, changed= to $GITHUB_OUTPUT.
set -euo pipefail

formula=Formula/emulicious.rb

curl -fsSL "https://emulicious.net/download/emulicious" -o /tmp/emulicious.zip
latest_date=$(unzip -p /tmp/emulicious.zip WhatsNew.txt \
  | grep -oE "^[0-9]{4}-[0-9]{2}-[0-9]{2}" \
  | head -n1)
latest=${latest_date//-/.}
current=$(sed -n 's/^[[:space:]]*version "\([^"]*\)".*/\1/p' "$formula" | head -n1)

{
  echo "current=$current"
  echo "latest=$latest"
} >> "$GITHUB_OUTPUT"

if [ "$current" = "$latest" ]; then
  echo "changed=false" >> "$GITHUB_OUTPUT"
  exit 0
fi

# Verify the versioned URL exists and matches the rolling zip byte-for-byte.
versioned_url="https://emulicious.net/emulicious/downloads/emulicious-${latest_date}.zip"
curl -fsSL "$versioned_url" -o /tmp/emulicious-versioned.zip
sha=$(sha256sum /tmp/emulicious-versioned.zip | cut -d' ' -f1)
rolling_sha=$(sha256sum /tmp/emulicious.zip | cut -d' ' -f1)
if [ "$sha" != "$rolling_sha" ]; then
  echo "::error::Rolling and versioned zips differ; aborting."
  exit 1
fi

perl -i -pe "s|emulicious-\K[0-9]{4}-[0-9]{2}-[0-9]{2}(?=\.zip)|${latest_date}|" "$formula"
perl -i -pe "s|version \"\K[^\"]+(?=\")|${latest}|" "$formula"
perl -i -pe "s|sha256 \"\K[0-9a-f]{64}(?=\")|${sha}|" "$formula"

echo "changed=true" >> "$GITHUB_OUTPUT"
