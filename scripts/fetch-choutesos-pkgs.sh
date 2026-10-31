#!/usr/bin/env bash
# Pulls the signed ChoutesOS packages (keyring, update backend) from the release into repo/
# so the offline ISO contains them. Run before scripts/build.sh.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO_DIR/repo"; mkdir -p "$OUT"
gh release download repo-x86_64 -R ChoutesOS/choutes-pkgs --clobber --dir "$OUT" \
  --pattern 'choutesos-keyring-*.pkg.tar.zst' --pattern 'choutesos-update-*.pkg.tar.zst'
repo-add "$OUT/choutesos.db.tar.zst" "$OUT"/choutesos-keyring-*.pkg.tar.zst "$OUT"/choutesos-update-*.pkg.tar.zst
echo "Done. Now run scripts/build.sh"
