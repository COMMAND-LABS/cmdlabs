#!/usr/bin/env bash
#
# check-schemas.sh — verify shared source files are byte-identical across
# services. Exit 0 = in sync; exit 1 = drift detected.
#
# WHY THIS EXISTS
# ---------------
# cmdlabs-api and cmdlabs-agent-api both map the same Postgres database with
# their own copy of src/db/models.py. SQLAlchemy only emits columns that are
# mapped, so when the copies drift:
#
#   - an INSERT from the service missing a NOT NULL column fails loudly (fine)
#   - a SELECT from the service missing a scoping column (e.g. org_id) silently
#     returns rows it should never see (a cross-tenant data leak)
#
# The second failure mode has no error, no test, and no symptom until someone
# reads another tenant's data. This script is the guardrail.
#
# It was ported from the previous repo generation (kalygo3.1/), where models.py
# was NOT in the sync list — which is exactly how the two copies drifted to
# 1108 vs 544 lines, with 11 model classes and two ServiceName enum members
# differing between them.
#
# Run locally before pushing, and in CI.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# Each entry: "<canonical> <mirror> [<mirror> ...]"
# The first path is the source of truth; the rest must be byte-identical.
#
# cmdlabs-api is canonical for all of these: it owns the Alembic migrations, so
# its models.py is the copy that must match the actual database schema.
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

# Deliberately NOT synced, so nobody "fixes" them later:
#   src/db/database.py        - per-service engine tuning (pool size, LIFO,
#                               application_name). Intentionally different.
#   src/utils/api_key_utils.py - agent-api verifies keys but never issues them,
#                               so it legitimately omits generate_api_key().

fail=0
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
      echo "✗ missing mirror:   $mirror"
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
  printf '\nShared-source drift detected. Re-sync mirrors from canonical with:\n  ./sync-schemas.sh\n'
  exit 1
fi

echo "All shared source files are in sync."
