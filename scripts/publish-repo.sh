#!/usr/bin/env bash
# Uploads locally built (AUR) packages to the ChoutesOS release, then asks CI in
# ChoutesOS/choutes-pkgs to sign them and regenerate the signed pacman database.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GH_REPO="ChoutesOS/choutes-pkgs"
TAG="repo-x86_64"
OUT="$REPO_DIR/repo"
ls "$OUT"/*.pkg.tar.zst >/dev/null 2>&1 || { echo "No packages in $OUT. Run scripts/build-aur-repo.sh first." >&2; exit 1; }
gh release view "$TAG" -R "$GH_REPO" >/dev/null 2>&1 || \
  gh release create "$TAG" -R "$GH_REPO" --latest=false --title "ChoutesOS repository (x86_64)" --notes "Pacman repository assets. Do not delete this release."
gh release upload "$TAG" -R "$GH_REPO" --clobber "$OUT"/*.pkg.tar.zst
gh workflow run publish.yml -R "$GH_REPO"
echo "Uploaded. CI signs and publishes the database: gh run watch -R $GH_REPO"
