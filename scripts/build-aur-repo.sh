#!/usr/bin/env bash
# Builds the packages in packages/aur.txt (AUR packages and the prebuilt XanMod kernel) into
# repo/, a pacman repository named "choutesos". Run as a normal user: makepkg refuses root.
#
#   ./scripts/build-aur-repo.sh                    build everything
#   ./scripts/build-aur-repo.sh helium-browser-bin build only the named packages
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAME="choutesos"
BUILD="$REPO_DIR/aur-build"
OUT="$REPO_DIR/repo"
mkdir -p "$BUILD" "$OUT"

if (($#)); then
    packages=("$@")
else
    mapfile -t packages < <(sed 's/#.*//' "$REPO_DIR/packages/aur.txt" | awk 'NF {print $1}')
fi

export MAKEFLAGS="-j$(nproc)"
failed=()
for pkg in "${packages[@]}"; do
    echo "==> $pkg"
    rm -rf "${BUILD:?}/$pkg"
    if git clone --depth 1 "https://aur.archlinux.org/$pkg.git" "$BUILD/$pkg" \
        && (cd "$BUILD/$pkg" && makepkg -sf --noconfirm --needed); then
        for f in "$BUILD/$pkg"/*.pkg.tar.zst; do
            [[ $f == *-debug-* ]] || cp "$f" "$OUT/"
        done
    else
        failed+=("$pkg")
    fi
done

rm -f "$OUT"/choutesos-local.* "$OUT/$NAME".db* "$OUT/$NAME".files*
if ls "$OUT"/*.pkg.tar.zst >/dev/null 2>&1; then
    repo-add "$OUT/$NAME.db.tar.zst" "$OUT"/*.pkg.tar.zst
fi

echo
if ((${#failed[@]})); then
    echo "These packages failed to build:"
    printf '  - %s\n' "${failed[@]}"
    exit 1
fi
echo "Repository ready in $OUT"
