#!/bin/bash
# Bump Formula/aseprite.rb to the latest upstream Aseprite release and the
# latest matching Skia prebuilt binary.
#
# Aseprite pins to a specific Skia commit but doesn't expose that pin in a
# machine-readable way; in practice "latest aseprite/skia release" is what
# the upstream INSTALL.md tells humans to download, so we mirror that.
#
# Writes current=, latest=, changed= to $GITHUB_OUTPUT.
# `current` / `latest` track the user-facing Aseprite version; Skia bumps
# alone will still set changed=true (rare in practice).
set -euo pipefail

formula=Formula/aseprite.rb
aseprite_repo=aseprite/aseprite
skia_repo=aseprite/skia

# --- Detect current versions in formula ---
current=$(sed -n 's|.*aseprite/releases/download/v\([^/]*\)/.*|\1|p' "$formula" | head -n1)
skia_current=$(sed -n 's|.*skia/releases/download/\([^/]*\)/.*|\1|p' "$formula" | head -n1)

# --- Fetch latest upstream versions ---
latest=$(gh release view --repo "$aseprite_repo" --json tagName --jq .tagName)
latest=${latest#v}  # formula URLs include the v, but we treat version as bare
skia_latest=$(gh release view --repo "$skia_repo" --json tagName --jq .tagName)

{
  echo "current=$current"
  echo "latest=$latest"
} >> "$GITHUB_OUTPUT"

if [ "$current" = "$latest" ] && [ "$skia_current" = "$skia_latest" ]; then
  echo "changed=false" >> "$GITHUB_OUTPUT"
  exit 0
fi

# --- Update Aseprite (URL pieces + top-level sha256) ---
if [ "$current" != "$latest" ]; then
  asset_url="https://github.com/${aseprite_repo}/releases/download/v${latest}/Aseprite-v${latest}-Source.zip"
  sha=$(curl -fsSL "$asset_url" | sha256sum | cut -d' ' -f1)

  perl -i -pe "s|aseprite/releases/download/v\K[^/]+(?=/)|${latest}|" "$formula"
  perl -i -pe "s|Aseprite-v\K[^-]+(?=-Source\.zip)|${latest}|" "$formula"

  # Top-level sha256 = the one immediately after the top-level Aseprite URL
  perl -0 -i -pe "s|Aseprite-v[^\"]+\.zip\"\n\s+sha256 \"\K[0-9a-f]{64}|${sha}|" "$formula"
fi

# --- Update Skia (resource block: URL tag + per-arch sha256) ---
if [ "$skia_current" != "$skia_latest" ]; then
  for arch in arm64 x64; do
    asset="Skia-macOS-Release-${arch}.zip"
    asset_url="https://github.com/${skia_repo}/releases/download/${skia_latest}/${asset}"
    sha=$(curl -fsSL "$asset_url" | sha256sum | cut -d' ' -f1)
    perl -0 -i -pe "s|\Q${asset}\E\"\n\s+sha256 \"\K[0-9a-f]{64}|${sha}|" "$formula"
  done

  perl -i -pe "s|skia/releases/download/\K[^/]+(?=/)|${skia_latest}|g" "$formula"
fi

echo "changed=true" >> "$GITHUB_OUTPUT"
