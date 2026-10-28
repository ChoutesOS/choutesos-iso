<p align="center">
  <img src="assets/banner.png" alt="ChoutesOS" width="100%">
</p>

<p align="center">
  <b>ISO build profile for ChoutesOS.</b>
</p>

<p align="center">
  <a href="https://github.com/ChoutesOS"><img src="https://img.shields.io/badge/ChoutesOS-5B18E5?style=for-the-badge&logo=archlinux&logoColor=white" alt="ChoutesOS"></a>
  <img src="https://img.shields.io/badge/license-GPL--3.0-9660F8?style=for-the-badge" alt="GPL-3.0">
  <img src="https://img.shields.io/badge/status-early%20development-3a3a4a?style=for-the-badge" alt="Early development">
</p>

---

## About

This repository holds the [archiso](https://wiki.archlinux.org/title/Archiso) profile, package lists and build scripts used to produce the ChoutesOS live and installer ISO.

> **Status:** early development.

## Build

Requirements: an Arch Linux host, the `archiso` package and at least 40 GB of free disk space.

    sudo mkarchiso -v -w /tmp/choutesos-work -o ~/ChoutesOS/out profile

## Related

- [`choutesos`](https://github.com/ChoutesOS/choutesos): desktop and dotfiles
- [`choutesos-installer`](https://github.com/ChoutesOS/choutesos-installer): graphical installer
- [`choutesos-pkgs`](https://github.com/ChoutesOS/choutesos-pkgs): packages and repository

## License

Released under the [GPL-3.0](LICENSE) license.
