#!/usr/bin/env bash
#
# sync-schemas.sh — copy each canonical shared file over its mirrors.
#
# cmdlabs-api is canonical: it owns the Alembic migrations, so its models.py is
# the copy that must match the real database schema. Edit the cmdlabs-api copy,
# then run this, then commit both.
#
# Run ./check-schemas.sh to verify without writing.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

RAW_SYNC_GROUPS=(
  "cmdlabs-api/src/db/models.py cmdlabs-agent-api/src/db/models.py"
  "cmdlabs-api/src/db/service_name.py cmdlabs-agent-api/src/db/service_name.py"
  "cmdlabs-api/src/db/space_models.py cmdlabs-agent-api/src/db/space_models.py"
  "cmdlabs-api/src/services/access.py cmdlabs-agent-api/src/services/access.py"
  "cmdlabs-api/src/services/org_scope.py cmdlabs-agent-api/src/services/org_scope.py"
  "cmdlabs-api/src/services/agent_access.py cmdlabs-agent-api/src/services/agent_access.py"
  "cmdlabs-api/src/services/credential_access.py cmdlabs-agent-api/src/services/credential_access.py"
  "cmdlabs-api/src/services/vector_store_credentials.py cmdlabs-agent-api/src/services/vector_store_credentials.py"
)

changed=0
for group in "${RAW_SYNC_GROUPS[@]}"; do
  # shellcheck disable=SC2206  # paths contain no spaces; intentional word-split
  files=($group)
  canonical="${files[0]}"

  if [[ ! -f "$canonical" ]]; then
    echo "✗ canonical missing: $canonical" >&2
    exit 1
  fi

  for mirror in "${files[@]:1}"; do
    if cmp -s "$canonical" "$mirror" 2>/dev/null; then
      echo "= unchanged: $mirror"
    else
      mkdir -p "$(dirname "$mirror")"
      cp "$canonical" "$mirror"
      echo "→ synced:    $mirror"
      changed=1
    fi
  done
done

if [[ "$changed" -eq 0 ]]; then
  echo "Nothing to do — all mirrors already match."
else
  echo
  echo "Mirrors updated. Review with 'git diff' and commit both services together."
fi
