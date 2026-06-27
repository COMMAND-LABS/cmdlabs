#!/usr/bin/env bash
#
# check-schemas.sh — verify the shared JSON-Schema contract files are in sync
# across services. Exit 0 = all in sync; exit 1 = drift detected.
#
# Compares each canonical schema against its mirrors using a normalized
# (sorted-keys) JSON form, so formatting differences never cause false drift.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
# shellcheck source=schema-files.sh
source "$ROOT/schema-files.sh"

fail=0
for group in "${SCHEMA_GROUPS[@]}"; do
  # shellcheck disable=SC2206  # paths contain no spaces; intentional word-split
  files=($group)
  canonical="${files[0]}"

  if [[ ! -f "$canonical" ]]; then
    echo "✗ canonical missing: $canonical"
    fail=1
    continue
  fi

  canon_norm="$(schema_normalize "$canonical")"

  for mirror in "${files[@]:1}"; do
    if [[ ! -f "$mirror" ]]; then
      echo "✗ missing mirror: $mirror"
      fail=1
      continue
    fi
    if [[ "$(schema_normalize "$mirror")" == "$canon_norm" ]]; then
      echo "✓ in sync: $mirror"
    else
      echo "✗ DRIFT:   $mirror"
      echo "           (differs from canonical $canonical)"
      diff <(printf '%s\n' "$canon_norm") <(schema_normalize "$mirror") | sed 's/^/    /' | head -40 || true
      fail=1
    fi
  done
done

# Raw byte-identical shared files (e.g. shared Python source) — compared with
# cmp; no normalization, so any byte difference is drift.
for group in "${RAW_SYNC_GROUPS[@]}"; do
  # shellcheck disable=SC2206  # paths contain no spaces; intentional word-split
  files=($group)
  canonical="${files[0]}"

  if [[ ! -f "$canonical" ]]; then
    echo "✗ canonical missing: $canonical"
    fail=1
    continue
  fi

  for mirror in "${files[@]:1}"; do
    if [[ ! -f "$mirror" ]]; then
      echo "✗ missing mirror: $mirror"
      fail=1
      continue
    fi
    if cmp -s "$canonical" "$mirror"; then
      echo "✓ in sync: $mirror"
    else
      echo "✗ DRIFT:   $mirror"
      echo "           (differs from canonical $canonical)"
      diff "$canonical" "$mirror" | sed 's/^/    /' | head -40 || true
      fail=1
    fi
  done
done

if [[ "$fail" -ne 0 ]]; then
  printf '\nSchema drift detected. Re-sync mirrors from canonical with:\n  ./sync-schemas.sh\n'
  exit 1
fi

echo "All shared schemas are in sync."
