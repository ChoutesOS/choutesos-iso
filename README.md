<p align="center">
  <img src="assets/banner.png" alt="ChoutesOS" width="100%">
</p>

<p align="center">
  <b>ISO build profile for ChoutesOS.</b>
</p>

<p align="center">
  <a href="https://choutes.com"><img src="https://img.shields.io/badge/choutes.com-5B18E5?style=for-the-badge" alt="Website"></a>
  <a href="https://wiki.choutes.com"><img src="https://img.shields.io/badge/Wiki-9660F8?style=for-the-badge" alt="Wiki"></a>
  <a href="https://discord.gg/nYdsKv7Fra"><img src="https://img.shields.io/badge/Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"></a>
  <img src="https://img.shields.io/badge/license-GPL--3.0-3a3a4a?style=for-the-badge" alt="GPL-3.0">
</p>

---

## About

Package lists, overlay files and scripts that build the ChoutesOS ISO. The [archiso](https://wiki.archlinux.org/title/Archiso) profile is generated from the official `releng` profile, so it always follows upstream.

> **Status:** early development.

## Layout

| Path | Purpose |
|---|---|
| `VERSION` | ISO version (`YEAR.MONTH.RELEASE`), raised automatically by every build |
| `packages/` | Package lists, grouped by purpose; `aur.txt` lists what is built into the local repository |
| `overlay/airootfs/` | Files copied into the live system |
| `overlay-target/` | Files only the installed system gets (pacman.conf, extra GRUB entries) |
| `scripts/build-aur-repo.sh` | Builds AUR packages and the prebuilt XanMod kernel into `repo/` |
| `scripts/publish-repo.sh` | Uploads `repo/` to the GitHub release behind packages.choutes.com |
| `scripts/build.sh` | Checks, prepares and builds the ISO |
| `scripts/vm.sh` | Tests the ISO and the installed system in QEMU with 3D graphics |

## Build

Requirements: Arch Linux with `archiso`, `qemu-desktop`, `edk2-ovmf` and `grub`, and at least 40 GB of free disk space.

    ./scripts/build-aur-repo.sh   # once, and whenever packages change
    ./scripts/build.sh            # raises the version, then builds the ISO into out/
    ./scripts/vm.sh install       # installs it into a virtual disk
    ./scripts/vm.sh run           # starts the installed system

## Support

Website [choutes.com](https://choutes.com) · Discord [discord.gg/nYdsKv7Fra](https://discord.gg/nYdsKv7Fra) · wafiq@choutes.com

## License

Released under the [GPL-3.0](LICENSE) license.
