#!/usr/bin/env bash
# Tests ChoutesOS in QEMU with UEFI and 3D graphics (virtio-gpu). Hyprland needs 3D graphics,
# so use this instead of VirtualBox.
#
#   ./scripts/vm.sh install   boot the newest ISO with an empty 40 GB virtual disk
#   ./scripts/vm.sh run       boot the installed system from that disk
#   ./scripts/vm.sh reset     delete the virtual disk and start over
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM="$REPO_DIR/vm"
DISK="$VM/disk.qcow2"
mkdir -p "$VM"

CODE="$(ls /usr/share/edk2/x64/OVMF_CODE*.fd 2>/dev/null | grep -v secboot | head -n1 || true)"
[[ -n "$CODE" ]] || { echo "OVMF firmware not found. Install it: sudo pacman -S edk2-ovmf" >&2; exit 1; }
VARS_SRC="${CODE/OVMF_CODE/OVMF_VARS}"

case "${1:-}" in
    reset)
        rm -f "$DISK" "$VM/OVMF_VARS.fd"
        echo "Virtual disk deleted."
        exit 0
        ;;
    install | run) ;;
    *)
        echo "usage: $0 install | run | reset" >&2
        exit 2
        ;;
esac

[[ -f "$DISK" ]] || qemu-img create -f qcow2 "$DISK" 40G
[[ -f "$VM/OVMF_VARS.fd" ]] || cp "$VARS_SRC" "$VM/OVMF_VARS.fd"

args=(
    -enable-kvm -cpu host -smp 4 -m 6G -machine q35
    -drive "if=pflash,format=raw,readonly=on,file=$CODE"
    -drive "if=pflash,format=raw,file=$VM/OVMF_VARS.fd"
    -drive "file=$DISK,if=virtio,format=qcow2"
    -vga none -device virtio-vga-gl -display gtk,gl=on
    -device qemu-xhci -device usb-tablet -device usb-kbd
    -netdev user,id=net0 -device virtio-net-pci,netdev=net0
)

if [[ "$1" == "install" ]]; then
    ISO="$(ls -t "$REPO_DIR"/out/*.iso | head -n1)"
    echo "Booting $ISO"
    args+=(-cdrom "$ISO")
fi

exec qemu-system-x86_64 "${args[@]}"
