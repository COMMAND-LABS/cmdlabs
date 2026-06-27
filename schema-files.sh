# Shared definitions for check-schemas.sh / sync-schemas.sh.
# This file is SOURCED, not executed.
#
# Background: several JSON-Schema "contract" files are duplicated across
# services (the UI generates TS types from its copy; the APIs validate against
# theirs). There is no codegen pipeline, so the copies must be kept in sync by
# hand. These scripts make that enforceable.
#
# Each entry is a space-separated list: "<canonical> <mirror> [<mirror> ...]".
# The first path is the source of truth; the rest are kept byte-identical to it
# (modulo JSON formatting / key order). Add more groups here as the shared
# contract grows (e.g. agent_config.v4.json).
SCHEMA_GROUPS=(
  "kalygo3-ai-api/src/schemas/chat_message.v2.json kalygo3-agent-api/src/schemas/chat_message.v2.json kalygo3-ui/src/schemas/chat-message.v2.json"
)

# Raw shared files that must be kept BYTE-IDENTICAL across services (no JSON
# normalization — compared with `cmp`). Same "<canonical> <mirror> ..." format.
# Used for shared Python source that lives in more than one service but cannot
# (yet) be a real shared package — e.g. the agent access-control rule, which the
# agent-api and ai-api must enforce identically. See that module's docstring.
RAW_SYNC_GROUPS=(
  "kalygo3-ai-api/src/services/agent_access.py kalygo3-agent-api/src/services/agent_access.py"
)

# Canonicalize a JSON file (sorted keys, fixed indent) so that whitespace and
# key-ordering differences do NOT register as drift — only semantic content.
schema_normalize() {
  python3 -c 'import json,sys; print(json.dumps(json.load(open(sys.argv[1])), sort_keys=True, indent=2))' "$1"
}
