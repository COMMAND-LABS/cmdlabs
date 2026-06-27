#!/usr/bin/env bash
#
# sync-schemas.sh — copy each canonical shared schema over its mirrors so every
# service shares one source of truth. Run this after editing a canonical file,
# then review and commit the updated mirrors.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
# shellcheck source=schema-files.sh
source "$ROOT/schema-files.sh"

for group in "${SCHEMA_GROUPS[@]}"; do
  # shellcheck disable=SC2206  # paths contain no spaces; intentional word-split
  files=($group)
  canonical="${files[0]}"

  if [[ ! -f "$canonical" ]]; then
    echo "✗ canonical missing: $canonical"
    exit 1
  fi

  for mirror in "${files[@]:1}"; do
    cp "$canonical" "$mirror"
    echo "→ synced: $mirror  (from $canonical)"
  done
done

# Raw byte-identical shared files (e.g. shared Python source).
for group in "${RAW_SYNC_GROUPS[@]}"; do
  # shellcheck disable=SC2206  # paths contain no spaces; intentional word-split
  files=($group)
  canonical="${files[0]}"

  if [[ ! -f "$canonical" ]]; then
    echo "✗ canonical missing: $canonical"
    exit 1
  fi

  for mirror in "${files[@]:1}"; do
    cp "$canonical" "$mirror"
    echo "→ synced: $mirror  (from $canonical)"
  done
done

echo "Done. Mirrors now match canonical — review & commit the changes."
