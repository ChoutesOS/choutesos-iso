#!/usr/bin/env bash
# Builds the ChoutesOS ISO. Run on an Arch Linux host with archiso installed.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$REPO_DIR/scripts/check-packages.sh"
"$REPO_DIR/scripts/prepare-profile.sh"

sudo rm -rf "$REPO_DIR/work"
mkdir -p "$REPO_DIR/out"
sudo mkarchiso -v -w "$REPO_DIR/work" -o "$REPO_DIR/out" "$REPO_DIR/profile"

echo
echo "Done. ISO files:"
ls -lh "$REPO_DIR/out"/*.iso
