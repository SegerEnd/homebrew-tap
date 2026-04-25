#!/bin/bash
# Bump Formula/gbdk-2020.rb to the latest upstream GitHub release.
# Writes current=, latest=, changed= to $GITHUB_OUTPUT.
set -euo pipefail

formula=Formula/gbdk-2020.rb
repo=gbdk-2020/gbdk-2020

latest=$(gh release view --repo "$repo" --json tagName --jq .tagName)
current=$(sed -n 's/^[[:space:]]*version "\([^"]*\)".*/\1/p' "$formula" | head -n1)

{
  echo "current=$current"
  echo "latest=$latest"
} >> "$GITHUB_OUTPUT"

if [ "$current" = "$latest" ]; then
  echo "changed=false" >> "$GITHUB_OUTPUT"
  exit 0
fi

perl -i -pe "s|version \"\K[^\"]+(?=\")|${latest}|" "$formula"
perl -i -pe "s|releases/download/\K[^/]+(?=/)|${latest}|g" "$formula"

for asset in gbdk-macos.tar.gz gbdk-macos-arm64.tar.gz gbdk-linux64.tar.gz gbdk-linux-arm64.tar.gz; do
  sha=$(curl -fsSL "https://github.com/$repo/releases/download/$latest/$asset" | sha256sum | cut -d' ' -f1)
  # Slurp the file, find the asset URL, then rewrite the sha256 on the next sha256 line.
  perl -0 -i -pe "s|\Q${asset}\E\"\n\s+sha256 \"\K[0-9a-f]{64}|${sha}|" "$formula"
done

echo "changed=true" >> "$GITHUB_OUTPUT"
