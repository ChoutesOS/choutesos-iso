#!/usr/bin/env bash
# Boots the newest ISO in QEMU with UEFI.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="$(ls -t "$REPO_DIR"/out/*.iso | head -n1)"

echo "Booting $ISO"
run_archiso -u -i "$ISO"
