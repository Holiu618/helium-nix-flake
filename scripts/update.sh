#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

repo="imputnet/helium-linux"

latest=$(curl -fsSL \
  ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
  "https://api.github.com/repos/$repo/releases/latest" | jq -r .tag_name)

current=$(sed -n 's/^  version = "\(.*\)";/\1/p' packages.nix)

if [ "$latest" = "$current" ]; then
  exit 0
fi

prefetch() {
  nix --extra-experimental-features 'nix-command flakes' \
    store prefetch-file --json \
    "https://github.com/$repo/releases/download/$latest/helium-$latest-$1_linux.tar.xz" \
    | jq -r .hash
}

hash_x86=$(prefetch x86_64)
hash_arm=$(prefetch arm64)

sed -i "s|^  version = \".*\";|  version = \"$latest\";|" packages.nix
sed -i "/arch = \"x86_64\";/{n;s|hash = \"[^\"]*\"|hash = \"$hash_x86\"|}" packages.nix
sed -i "/arch = \"arm64\";/{n;s|hash = \"[^\"]*\"|hash = \"$hash_arm\"|}" packages.nix

echo "helium: $current -> $latest"
echo "version=$latest" >> "${GITHUB_OUTPUT:-/dev/null}"
