#!/usr/bin/env bash
# Raises the build number in VERSION. Scheme: YEAR.MONTH.RELEASE (2026.10.01, 2026.10.02, ...).
# The release number restarts at 01 in a new month.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
current="$(<"$REPO_DIR/VERSION")"
year="$(date +%Y)"
month="$(date +%-m)"

IFS=. read -r cur_year cur_month cur_release <<< "$current"
if [[ "$cur_year" == "$year" && "$cur_month" == "$month" ]]; then
    release=$((10#$cur_release + 1))
else
    release=1
fi

next="$(printf '%s.%s.%02d' "$year" "$month" "$release")"
echo "$next" > "$REPO_DIR/VERSION"
echo "Version: $current -> $next"
