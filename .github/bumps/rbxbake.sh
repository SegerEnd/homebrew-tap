#!/bin/bash
# Bump Casks/rbxbake.rb when segerend.nl serves a new cli.mjs (the engine
# updates itself at runtime). Version is the file's Last-Modified date.
# Writes current=, latest=, changed= to $GITHUB_OUTPUT.
set -euo pipefail

cask=Casks/rbxbake.rb

curl -fsSL -D /tmp/rbxbake.headers "https://segerend.nl/rbxbake/cli.mjs" -o /tmp/rbxbake.mjs
sha=$(sha256sum /tmp/rbxbake.mjs | cut -d' ' -f1)
current=$(sed -n 's/^[[:space:]]*version "\([^"]*\)".*/\1/p' "$cask" | head -n1)
current_sha=$(sed -n 's/^[[:space:]]*sha256 "\([0-9a-f]*\)".*/\1/p' "$cask" | head -n1)

if [ "$sha" = "$current_sha" ]; then
  printf 'current=%s\nlatest=%s\nchanged=false\n' "$current" "$current" >> "$GITHUB_OUTPUT"
  exit 0
fi

modified=$(sed -n 's/^last-modified:[[:space:]]*//Ip' /tmp/rbxbake.headers | tr -d '\r' | tail -n1)
latest=$(date -u -d "$modified" +%Y.%m.%d)
# Second release on the same day: add the time.
case "$current" in "$latest"*) latest="$latest.$(date -u -d "$modified" +%H%M)" ;; esac

perl -i -pe "s|version \"\K[^\"]+(?=\")|${latest}|" "$cask"
perl -i -pe "s|sha256 \"\K[0-9a-f]{64}(?=\")|${sha}|" "$cask"

printf 'current=%s\nlatest=%s\nchanged=true\n' "$current" "$latest" >> "$GITHUB_OUTPUT"
