#!/usr/bin/env bash
# Verifies that every package listed in packages/*.txt (except aur.txt) exists in the enabled pacman repositories.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
missing=()

while read -r pkg; do
    if ! pacman -Si "$pkg" >/dev/null 2>&1; then
        missing+=("$pkg")
    fi
done < <(find "$REPO_DIR/packages" -name '*.txt' ! -name 'aur.txt' -exec cat {} + | sed 's/#.*//' | awk 'NF {print $1}' | sort -u)

if ((${#missing[@]})); then
    echo "These packages were not found in your enabled repositories:" >&2
    printf '  - %s\n' "${missing[@]}" >&2
    echo >&2
    echo "Tip: lib32-* packages and steam need the [multilib] repository enabled in /etc/pacman.conf." >&2
    exit 1
fi

echo "All packages found."
