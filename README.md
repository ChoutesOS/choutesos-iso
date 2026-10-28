<p align="center">
  <img src="assets/banner.png" alt="ChoutesOS" width="100%">
</p>

<p align="center">
  <b>ISO build profile for ChoutesOS.</b>
</p>

---

## About

This repository holds the package lists, overlay files and build scripts used to produce the ChoutesOS live and installer ISO. The [archiso](https://wiki.archlinux.org/title/Archiso) profile is generated from the official `releng` profile, so it always tracks upstream.

> **Status:** early development.

## Layout

| Path | Purpose |
|---|---|
| `VERSION` | ISO version (`YEAR.MONTH.RELEASE`) |
| `packages/` | Package lists, grouped by purpose |
| `overlay/airootfs/` | Files copied into the live system |
| `scripts/check-packages.sh` | Verifies every listed package exists |
| `scripts/prepare-profile.sh` | Generates `profile/` and applies customizations |
| `scripts/build.sh` | Checks, prepares and builds the ISO |
| `scripts/test-iso.sh` | Boots the newest ISO in QEMU (UEFI) |

## Build

Requirements: an Arch Linux host with `archiso`, `qemu-desktop` and `edk2-ovmf`, and at least 40 GB of free disk space.

    ./scripts/build.sh
    ./scripts/test-iso.sh

The ISO is written to `out/`.

## License

Released under the [GPL-3.0](LICENSE) license.
