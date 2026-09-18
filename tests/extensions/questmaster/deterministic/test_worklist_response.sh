#!/bin/sh
# test_worklist_response.sh — covers qm-worklist.sh + qm-record.sh's ledger writing (tasks.md
# T058/T059), FR-043 [US2].
#
# A non-empty worklist records a response, a deferral, or an explicit unanswered marker for its
# top item; an empty worklist elicits nothing and writes nothing; and no path prevents proceeding
# to the next stage (this script only tests the recording mechanics — never blocking is a
# property of the command's prose, verified here by absence of any "block" side effect: nothing
# these calls do can halt anything else).

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../../.." && pwd)
QM_WORKLIST="$REPO_ROOT/extensions/questmaster/scripts/qm-worklist.sh"
QM_RECORD="$REPO_ROOT/extensions/questmaster/scripts/qm-record.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

cat > "$TMP/spec.md" <<'MD'
# Spec
## Questmaster Record
### Judgment Ledger
### Comprehension
### Decisions
MD

# --- Case 1: empty worklist -> required=false, top=null, and NOTHING is written ---
echo '[]' > "$TMP/empty.json"
OUT_EMPTY=$(sh "$QM_WORKLIST" "$TMP/empty.json")
[ "$(echo "$OUT_EMPTY" | jq -r '.required')" = "false" ] || fail "empty worklist must report required=false"
[ "$(echo "$OUT_EMPTY" | jq -r '.top')" = "null" ] || fail "empty worklist must report top=null"
BEFORE=$(sh "$QM_RECORD" list-ledger "$TMP/spec.md")
[ "$(echo "$BEFORE" | jq 'length')" = "0" ] || fail "ledger should start empty"
# (the command is instructed to skip Step 8 entirely here — nothing to call; ledger stays empty)
AFTER_NOOP=$(sh "$QM_RECORD" list-ledger "$TMP/spec.md")
[ "$(echo "$AFTER_NOOP" | jq 'length')" = "0" ] || fail "empty worklist must not write anything to the ledger"

# --- Case 2: non-empty worklist -> a RESOLUTION is recorded as a ledger entry ---
echo '[{"summary":"spec.md adds admin bulk-resend tool","question":"was this intended?","classification":"UNJUSTIFIED_DRIFT","severity":"High"}]' > "$TMP/one.json"
OUT_ONE=$(sh "$QM_WORKLIST" "$TMP/one.json")
[ "$(echo "$OUT_ONE" | jq -r '.required')" = "true" ] || fail "non-empty worklist must report required=true"
[ "$(echo "$OUT_ONE" | jq -r '.top.summary')" = "spec.md adds admin bulk-resend tool" ] || fail "top item not surfaced"

sh "$QM_RECORD" add-ledger "$TMP/spec.md" "2026-09-14" spec asserted_fact \
  "Yes, support asked for this in the same thread, keep it." \
  "Resolved: admin bulk-resend tool confirmed in scope."
LEDGER_RESOLVE=$(sh "$QM_RECORD" list-ledger "$TMP/spec.md")
[ "$(echo "$LEDGER_RESOLVE" | jq 'length')" = "1" ] || fail "resolution must be recorded as exactly one ledger entry"
echo "$LEDGER_RESOLVE" | jq -e '.[0].developer_words | contains("support asked for this")' >/dev/null \
  || fail "developer's resolution words not recorded verbatim"

# --- Case 3: a DEFERRAL is recorded as a deferral (distinguishable kind/effect), not as silence ---
cat > "$TMP/spec2.md" <<'MD'
# Spec
## Questmaster Record
### Judgment Ledger
### Comprehension
### Decisions
MD
sh "$QM_RECORD" add-ledger "$TMP/spec2.md" "2026-09-14" spec risk_named \
  "Not dealing with this today, come back to it after the demo." \
  "Deferred; carried forward to the next stage."
LEDGER_DEFER=$(sh "$QM_RECORD" list-ledger "$TMP/spec2.md")
echo "$LEDGER_DEFER" | jq -e '.[0].effect | contains("Deferred")' >/dev/null \
  || fail "a deferral must be recorded distinctly as a deferral"

# --- Case 4: an unanswered item is recorded as unanswered, not silently dropped ---
cat > "$TMP/spec3.md" <<'MD'
# Spec
## Questmaster Record
### Judgment Ledger
### Comprehension
### Decisions
MD
sh "$QM_RECORD" add-ledger "$TMP/spec3.md" "2026-09-14" spec risk_named \
  "(no response given)" \
  "Unanswered; carried forward per FR-039."
LEDGER_UNANSWERED=$(sh "$QM_RECORD" list-ledger "$TMP/spec3.md")
echo "$LEDGER_UNANSWERED" | jq -e '.[0].effect | contains("Unanswered")' >/dev/null \
  || fail "an unanswered item must be recorded as unanswered, not omitted"

echo "OK: test_worklist_response.sh"
