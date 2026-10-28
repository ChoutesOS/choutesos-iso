#!/usr/bin/env bash
# Builds the ChoutesOS ISO. Run on an Arch Linux host with archiso installed.
#
#   ./scripts/build.sh                 raise the version number, then build
#   ./scripts/build.sh --keep-version  build without raising the version number
#   LIVE_GRUB=1 ./scripts/build.sh     use GRUB (with the ChoutesOS theme) for UEFI boot of the ISO
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" != "--keep-version" ]]; then
    "$REPO_DIR/scripts/bump-version.sh"
fi
echo "Building ChoutesOS $(<"$REPO_DIR/VERSION")"

"$REPO_DIR/scripts/check-packages.sh"
"$REPO_DIR/scripts/prepare-profile.sh"

sudo rm -rf "$REPO_DIR/work"
mkdir -p "$REPO_DIR/out"
sudo mkarchiso -v -w "$REPO_DIR/work" -o "$REPO_DIR/out" "$REPO_DIR/profile"

# The live initramfs must contain the archiso hooks, or the ISO cannot find its own files.
echo
echo "Checking the live initramfs..."
ok=1
while read -r img; do
    if lsinitcpio "$img" 2>/dev/null | grep -q 'archiso'; then
        echo "  OK: $(basename "$img") contains the archiso hooks"
    else
        echo "  PROBLEM: $(basename "$img") has no archiso hooks; the ISO will not boot" >&2
        ok=0
    fi
done < <(find "$REPO_DIR/work/iso" -name 'initramfs-*.img')
find "$REPO_DIR/work/iso" -name 'vmlinuz-*' -printf '  Kernel in the ISO: %f\n'
((ok)) || exit 1

echo
echo "Done. ISO files:"
ls -lh "$REPO_DIR/out"/*.iso
