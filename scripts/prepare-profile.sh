#!/usr/bin/env bash
# Generates profile/ from the official archiso "releng" profile and applies ChoutesOS customizations.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$REPO_DIR/profile"
SRC="${ARCHISO_RELENG:-/usr/share/archiso/configs/releng}"
VERSION="$(<"$REPO_DIR/VERSION")"

[[ -d "$SRC" ]] || { echo "archiso releng profile not found at $SRC (install the archiso package)." >&2; exit 1; }

rm -rf "$PROFILE"
cp -r "$SRC" "$PROFILE"
chmod -R u+w "$PROFILE"

# ISO identity
LABEL="CHOUTESOS_${VERSION%.*}"
LABEL="${LABEL//./}"
sed -i \
    -e "s|^iso_name=.*|iso_name=\"choutesos\"|" \
    -e "s|^iso_label=.*|iso_label=\"${LABEL}\"|" \
    -e "s|^iso_publisher=.*|iso_publisher=\"ChoutesOS <https://github.com/ChoutesOS>\"|" \
    -e "s|^iso_application=.*|iso_application=\"ChoutesOS Live/Installer\"|" \
    -e "s|^iso_version=.*|iso_version=\"${VERSION}\"|" \
    "$PROFILE/profiledef.sh"

# Boot menu names
for d in syslinux grub efiboot; do
    [[ -d "$PROFILE/$d" ]] || continue
    { grep -rl "Arch Linux" "$PROFILE/$d" || true; } | xargs -r sed -i 's/Arch Linux/ChoutesOS/g'
done

# Packages (deduplicated, original order kept)
{
    cat "$PROFILE/packages.x86_64"
    echo
    cat "$REPO_DIR"/packages/*.txt | sed 's/#.*//' | awk 'NF {print $1}'
} | awk 'NF && !seen[$0]++' > "$PROFILE/packages.x86_64.new"
mv "$PROFILE/packages.x86_64.new" "$PROFILE/packages.x86_64"

# Enable [multilib] for lib32-* packages and Steam
if ! grep -q '^\[multilib\]' "$PROFILE/pacman.conf"; then
    printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> "$PROFILE/pacman.conf"
fi

# Overlay files
cp -r "$REPO_DIR/overlay/airootfs/." "$PROFILE/airootfs/"
sed -i "s|__VERSION__|${VERSION}|g" "$PROFILE/airootfs/etc/os-release"

echo "Profile generated at $PROFILE (version $VERSION)."
