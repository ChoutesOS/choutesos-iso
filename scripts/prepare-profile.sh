#!/usr/bin/env bash
# Generates profile/ from the official archiso "releng" profile and applies ChoutesOS customizations.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$REPO_DIR/profile"
SRC="${ARCHISO_RELENG:-/usr/share/archiso/configs/releng}"
DESKTOP_REPO="${DESKTOP_REPO:-$REPO_DIR/../choutesos}"
INSTALLER_REPO="${INSTALLER_REPO:-$REPO_DIR/../choutesos-installer}"
VERSION="$(<"$REPO_DIR/VERSION")"
AIROOT="$PROFILE/airootfs"
SKEL="$AIROOT/etc/skel"
TARGET_OVERLAY="$AIROOT/usr/share/choutesos-installer/target-overlay"
DB="$REPO_DIR/repo/choutesos.db.tar.zst"
KERNEL_PACKAGE="linux-xanmod-linux-bin-x64v2"

[[ -d "$SRC" ]] || { echo "archiso releng profile not found at $SRC (install the archiso package)." >&2; exit 1; }
[[ -d "$DESKTOP_REPO/home" ]] || { echo "Desktop repo not found at $DESKTOP_REPO" >&2; exit 1; }
[[ -d "$INSTALLER_REPO/choutesos_installer" ]] || { echo "Installer repo not found at $INSTALLER_REPO" >&2; exit 1; }

rm -rf "$PROFILE"
cp -r "$SRC" "$PROFILE"
chmod -R u+w "$PROFILE"

# --- ISO identity
LABEL="CHOUTESOS_${VERSION%.*}"
LABEL="${LABEL//./}"
sed -i \
    -e "s|^iso_name=.*|iso_name=\"choutesos\"|" \
    -e "s|^iso_label=.*|iso_label=\"${LABEL}\"|" \
    -e "s|^iso_publisher=.*|iso_publisher=\"ChoutesOS <https://choutes.com>\"|" \
    -e "s|^iso_application=.*|iso_application=\"ChoutesOS Live/Installer\"|" \
    -e "s|^iso_version=.*|iso_version=\"${VERSION}\"|" \
    "$PROFILE/profiledef.sh"

for d in syslinux grub efiboot; do
    [[ -d "$PROFILE/$d" ]] || continue
    { grep -rl "Arch Linux" "$PROFILE/$d" || true; } | xargs -r sed -i 's/Arch Linux/ChoutesOS/g'
done

# --- quiet boot: hide the kernel and systemd logs, show only the splash
for d in syslinux grub efiboot; do
    [[ -d "$PROFILE/$d" ]] || continue
    { grep -rl 'archisosearchuuid=%ARCHISO_UUID%' "$PROFILE/$d" || true; } | xargs -r sed -i \
        's#archisosearchuuid=%ARCHISO_UUID%#archisosearchuuid=%ARCHISO_UUID% quiet splash loglevel=3 rd.udev.log_level=3 vt.global_cursor_default=0#g'
done
# the live initramfs needs the plymouth hook
ARCHISO_CONF="$AIROOT/etc/mkinitcpio.conf.d/archiso.conf"
[[ -f "$ARCHISO_CONF" ]] && sed -i -E '/^HOOKS=/ s/\budev\b/udev plymouth/' "$ARCHISO_CONF"

# --- helpers
available() {
    if command -v pacman >/dev/null 2>&1; then pacman -Si "$1" >/dev/null 2>&1; else return 0; fi
}
list() { sed 's/#.*//' "$@" | awk 'NF {print $1}'; }

# --- the local "choutesos" repository: AUR packages and the XanMod kernel
aur_pkgs=()
if [[ -f "$DB" ]]; then
    while read -r name; do aur_pkgs+=("$name"); done < <(bsdtar -tf "$DB" | sed -n 's#^\(.*\)-[^-]*-[0-9][0-9.]*/$#\1#p')
else
    echo "note: no local repository (run scripts/build-aur-repo.sh); building without Helium, yay, themes and XanMod." >&2
fi

# The kernel's real name (its pkgbase) is read from the package itself, so boot entries always match.
KERNEL=linux
if printf '%s\n' "${aur_pkgs[@]+"${aur_pkgs[@]}"}" | grep -qx "$KERNEL_PACKAGE"; then
    kernel_file="$(ls -v "$REPO_DIR"/repo/"$KERNEL_PACKAGE"-[0-9]*.pkg.tar.zst 2>/dev/null | tail -n1 || true)"
    if [[ -n "$kernel_file" ]]; then
        member="$(bsdtar -tf "$kernel_file" | grep -m1 '^usr/lib/modules/.*/pkgbase$' || true)"
        [[ -n "$member" ]] && KERNEL="$(bsdtar -xOf "$kernel_file" "$member" | head -n1 | tr -d '[:space:]')"
    fi
fi
if [[ -z "$KERNEL" || "$KERNEL" == "linux" ]]; then
    KERNEL=linux
    echo "warning: the XanMod kernel is not in the local repository; the ISO will use the stock Arch kernel." >&2
fi
echo "Kernel: $KERNEL"

desktop_pkgs=()
while read -r pkg; do
    if available "$pkg"; then desktop_pkgs+=("$pkg"); else echo "warning: desktop package '$pkg' not found, skipped" >&2; fi
done < <(list "$DESKTOP_REPO/packages/pacman.txt")

# --- packages
COMBINED="$(mktemp)"
REMOVE="$(mktemp)"
trap 'rm -f "$COMBINED" "$REMOVE"' EXIT
{
    cat "$PROFILE/packages.x86_64"
    echo
    list "$REPO_DIR"/packages/system.txt "$REPO_DIR"/packages/drivers.txt "$REPO_DIR"/packages/gaming.txt \
         "$REPO_DIR"/packages/fonts.txt "$REPO_DIR"/packages/storage-and-archives.txt \
         "$REPO_DIR"/packages/installer.txt "$REPO_DIR"/packages/desktop-extra.txt
    printf '%s\n' "${desktop_pkgs[@]}" ${aur_pkgs[@]+"${aur_pkgs[@]}"}
} | awk 'NF && !seen[$0]++' > "$COMBINED"
{
    echo "grml-zsh-config"                      # conflicts with the desktop's own .zshrc
    list "$REPO_DIR/packages/releng-remove.txt"
    if [[ "$KERNEL" != "linux" ]]; then echo "linux"; fi
} > "$REMOVE"
grep -vxFf "$REMOVE" "$COMBINED" > "$PROFILE/packages.x86_64" || true

# --- kernel: boot entries and the live initramfs preset follow the kernel name
if [[ "$KERNEL" != "linux" ]]; then
    rm -f "$AIROOT/etc/mkinitcpio.d/linux.preset"
    mkdir -p "$AIROOT/etc/mkinitcpio.d"
    cat > "$AIROOT/etc/mkinitcpio.d/$KERNEL.preset" <<PRESET
PRESETS=('archiso')
ALL_kver='/boot/vmlinuz-$KERNEL'
archiso_config='/etc/mkinitcpio.conf.d/archiso.conf'
archiso_image='/boot/initramfs-$KERNEL.img'
PRESET
    for d in syslinux grub efiboot; do
        [[ -d "$PROFILE/$d" ]] || continue
        { grep -rlE 'vmlinuz-linux|initramfs-linux' "$PROFILE/$d" || true; } | xargs -r sed -i -E \
            -e "s#vmlinuz-linux\\b#vmlinuz-$KERNEL#g" \
            -e "s#initramfs-linux\\.img#initramfs-$KERNEL.img#g"
    done
fi

# --- pacman.conf: multilib and the local repository
if ! grep -q '^\[multilib\]' "$PROFILE/pacman.conf"; then
    printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> "$PROFILE/pacman.conf"
fi
if [[ -f "$DB" ]]; then
    printf '\n[choutesos]\nSigLevel = Optional TrustAll\nServer = file://%s/repo\n' "$REPO_DIR" >> "$PROFILE/pacman.conf"
fi

# --- desktop: dotfiles into /etc/skel, system files into /
mkdir -p "$SKEL" "$TARGET_OVERLAY/etc/mkinitcpio.conf.d" "$TARGET_OVERLAY/etc/default/grub.d"
cp -a "$DESKTOP_REPO/home/." "$SKEL/"
cp -a "$DESKTOP_REPO/system/." "$AIROOT/"
# these only make sense on the installed system (the live initramfs must keep archiso's hooks)
mv "$AIROOT/etc/mkinitcpio.conf.d/choutesos.conf" "$TARGET_OVERLAY/etc/mkinitcpio.conf.d/"
mv "$AIROOT/etc/default/grub.d/choutesos.cfg" "$TARGET_OVERLAY/etc/default/grub.d/"
# files only the installed system gets (pacman.conf with our repository, extra GRUB entries)
cp -a "$REPO_DIR/overlay-target/." "$TARGET_OVERLAY/"
# every user gets a git checkout of the desktop, so `choutesos update` pulls from GitHub
if [[ -d "$DESKTOP_REPO/.git" ]]; then
    git clone --quiet --no-hardlinks "$DESKTOP_REPO" "$SKEL/choutesos"
    git -C "$SKEL/choutesos" remote set-url origin https://github.com/ChoutesOS/choutesos.git
fi

# --- installer, first-boot setup and the kiosk session that shows them (no desktop, no shortcuts)
mkdir -p "$AIROOT/usr/share/choutesos-installer" "$AIROOT/usr/bin" "$AIROOT/usr/share/applications" \
         "$AIROOT/usr/share/wayland-sessions" "$AIROOT/usr/lib/choutesos"
cp -a "$INSTALLER_REPO/choutesos_installer" "$AIROOT/usr/share/choutesos-installer/"
find "$AIROOT/usr/share/choutesos-installer" \( -name __pycache__ -o -name tests \) -prune -exec rm -rf {} \;
install -m 755 "$INSTALLER_REPO/bin/choutesos-installer" "$AIROOT/usr/bin/choutesos-installer"
install -m 755 "$INSTALLER_REPO/bin/choutesos-session" "$AIROOT/usr/bin/choutesos-session"
install -m 755 "$INSTALLER_REPO/bin/choutesos-oobe-helper" "$AIROOT/usr/lib/choutesos/oobe-helper"
install -m 644 "$INSTALLER_REPO/data/choutesos-installer.desktop" "$AIROOT/usr/share/applications/choutesos-installer.desktop"
install -m 644 "$INSTALLER_REPO/data/choutesos-installer.session.desktop" "$AIROOT/usr/share/wayland-sessions/choutesos-installer.desktop"
install -m 644 "$INSTALLER_REPO/data/choutesos-setup.session.desktop" "$AIROOT/usr/share/wayland-sessions/choutesos-setup.desktop"

# --- overlay files (os-release, live user, autologin into the installer, ...)
cp -r "$REPO_DIR/overlay/airootfs/." "$AIROOT/"
sed -i "s|__VERSION__|${VERSION}|g" "$AIROOT/etc/os-release"
# older versions of this repository shipped a hook for the kernel preset; it is no longer needed
rm -f "$AIROOT/etc/pacman.d/hooks/89-choutesos-archiso-preset.hook" "$AIROOT/usr/local/bin/choutesos-archiso-preset"

# --- services in the live system: graphical login, network, bluetooth
mkdir -p "$AIROOT/etc/systemd/system/multi-user.target.wants"
ln -sf /usr/lib/systemd/system/graphical.target "$AIROOT/etc/systemd/system/default.target"
ln -sf /usr/lib/systemd/system/sddm.service "$AIROOT/etc/systemd/system/display-manager.service"
ln -sf /usr/lib/systemd/system/NetworkManager.service "$AIROOT/etc/systemd/system/multi-user.target.wants/NetworkManager.service"
ln -sf /usr/lib/systemd/system/bluetooth.service "$AIROOT/etc/systemd/system/multi-user.target.wants/bluetooth.service"

# --- the ISO's boot menu: GRUB with the ChoutesOS theme (LIVE_GRUB=0 keeps the plain menu)
if [[ "${LIVE_GRUB:-1}" != "0" ]]; then
    if command -v grub-mkstandalone >/dev/null 2>&1; then
        sed -i "s/'uefi.systemd-boot'/'uefi.grub'/" "$PROFILE/profiledef.sh"
        mkdir -p "$PROFILE/grub/themes"
        cp -r "$REPO_DIR/overlay/airootfs/usr/share/grub/themes/choutesos" "$PROFILE/grub/themes/"
        BLOCK="$(mktemp)"
        cat > "$BLOCK" <<'THEME'
insmod all_video
insmod gfxterm
insmod png
insmod jpeg
set gfxmode=auto
set gfxpayload=keep
terminal_output gfxterm
set theme=/boot/grub/themes/choutesos/theme.txt
export theme
THEME
        awk 'FNR==NR {b = b $0 "\n"; next} /^menuentry/ && !done {printf "%s", b; done=1} {print}' \
            "$BLOCK" "$PROFILE/grub/grub.cfg" > "$PROFILE/grub/grub.cfg.new"
        mv "$PROFILE/grub/grub.cfg.new" "$PROFILE/grub/grub.cfg"
        rm -f "$BLOCK"
        echo "Boot menu: GRUB (ChoutesOS theme)"
    else
        echo "note: the grub package is not installed on this computer, so the ISO keeps the plain boot menu." >&2
    fi
fi

# --- file permissions
sed -i '/^file_permissions=(/a\  ["/etc/sudoers.d/10-live"]="0:0:440"\n  ["/usr/bin/choutesos-installer"]="0:0:755"\n  ["/usr/bin/choutesos-session"]="0:0:755"\n  ["/usr/lib/choutesos/oobe-helper"]="0:0:755"\n  ["/usr/lib/choutesos/login-background"]="0:0:755"\n  ["/usr/lib/choutesos/face"]="0:0:755"\n  ["/usr/lib/choutesos/avatar"]="0:0:755"' "$PROFILE/profiledef.sh"

echo "Profile generated at $PROFILE (version $VERSION)."
