#!/usr/bin/env bash
# Uploads repo/ to a GitHub release. packages.choutes.com redirects to that release,
# so pacman downloads the packages from GitHub.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GH_REPO="ChoutesOS/choutesos-pkgs"
TAG="repo-x86_64"
NAME="choutesos"
OUT="$REPO_DIR/repo"

[[ -f "$OUT/$NAME.db.tar.zst" ]] || { echo "No repository found. Run scripts/build-aur-repo.sh first." >&2; exit 1; }

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp "$OUT"/*.pkg.tar.zst "$STAGE/"
cp "$OUT/$NAME.db.tar.zst" "$STAGE/$NAME.db"
cp "$OUT/$NAME.files.tar.zst" "$STAGE/$NAME.files"

if ! gh release view "$TAG" -R "$GH_REPO" >/dev/null 2>&1; then
    gh release create "$TAG" -R "$GH_REPO" --latest=false \
        --title "ChoutesOS package repository (x86_64)" \
        --notes "Pacman repository served at https://packages.choutes.com/choutesos/x86_64/. Do not delete this release."
fi

echo "Uploading $(ls "$STAGE" | wc -l) files..."
gh release upload "$TAG" -R "$GH_REPO" --clobber "$STAGE"/*

# remove old versions that are no longer in the repository
gh release view "$TAG" -R "$GH_REPO" --json assets --jq '.assets[].name' | while read -r asset; do
    [[ -e "$STAGE/$asset" ]] || gh release delete-asset "$TAG" "$asset" -R "$GH_REPO" -y
done

echo "Published. Check: curl -I https://packages.choutes.com/choutesos/x86_64/$NAME.db"
