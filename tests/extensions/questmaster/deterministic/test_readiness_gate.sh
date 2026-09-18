#!/bin/sh
# test_readiness_gate.sh — covers T018 (qm-readiness.sh), FR-012 [US1].
#
# The FR-012 classification rule: any unmet critical condition forces NOT_READY regardless of
# score (including a 95/100 story with an unidentified primary actor), score >= threshold with no
# unmet condition gives READY, below threshold gives NEEDS_CLARIFICATION, READY_WITH_ACCEPTED_RISK
# is reachable only via a recorded non-empty developer justification, and an empty Judgment
# Ledger trips no_developer_judgment_recorded.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../../.." && pwd)
QM_READINESS="$REPO_ROOT/extensions/questmaster/scripts/qm-readiness.sh"
QM_RECORD="$REPO_ROOT/extensions/questmaster/scripts/qm-record.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

# A story with a non-empty Judgment Ledger, so no_developer_judgment_recorded is never the
# confound in cases that aren't specifically testing it.
cat > "$TMP/story_with_ledger.md" <<'MD'
# Story
## Questmaster Record
### Judgment Ledger
### Comprehension
### Decisions
MD
sh "$QM_RECORD" add-ledger "$TMP/story_with_ledger.md" "2026-09-13" "story" "cut" "Dropped X." "Narrowed scope."

# A story with an empty ledger.
cat > "$TMP/story_empty_ledger.md" <<'MD'
# Story
## Questmaster Record
### Judgment Ledger
### Comprehension
### Decisions
MD

echo '[]' > "$TMP/no_unmet.json"

# --- Case 1: 95/100 score, no LLM-judged unmet conditions, but primary_actor_unknown IS unmet ---
echo '["primary_actor_unknown"]' > "$TMP/actor_unmet.json"
OUT1=$(sh "$QM_READINESS" "$TMP/story_with_ledger.md" 95 70 "$TMP/actor_unmet.json")
[ "$(echo "$OUT1" | jq -r '.status')" = "NOT_READY" ] || fail "95/100 with unmet condition must be NOT_READY, got: $OUT1"
echo "$OUT1" | jq -e '.unmet_critical_conditions | index("primary_actor_unknown") != null' >/dev/null \
  || fail "primary_actor_unknown not named as unmet"

# --- Case 2: score >= threshold, no unmet conditions -> READY ---
OUT2=$(sh "$QM_READINESS" "$TMP/story_with_ledger.md" 75 70 "$TMP/no_unmet.json")
[ "$(echo "$OUT2" | jq -r '.status')" = "READY" ] || fail "75>=70 with no unmet must be READY, got: $OUT2"

# --- Case 3: score below threshold, no unmet conditions -> NEEDS_CLARIFICATION ---
OUT3=$(sh "$QM_READINESS" "$TMP/story_with_ledger.md" 62 70 "$TMP/no_unmet.json")
[ "$(echo "$OUT3" | jq -r '.status')" = "NEEDS_CLARIFICATION" ] || fail "62<70 with no unmet must be NEEDS_CLARIFICATION, got: $OUT3"

# --- Case 4: READY_WITH_ACCEPTED_RISK reachable ONLY via accept_risk + non-empty justification ---
OUT4_NO_CHOICE=$(sh "$QM_READINESS" "$TMP/story_with_ledger.md" 62 70 "$TMP/no_unmet.json")
[ "$(echo "$OUT4_NO_CHOICE" | jq -r '.status')" = "NEEDS_CLARIFICATION" ] || fail "no developer choice must not grant READY_WITH_ACCEPTED_RISK"

OUT4_EMPTY_JUST=$(sh "$QM_READINESS" "$TMP/story_with_ledger.md" 62 70 "$TMP/no_unmet.json" accept_risk "")
[ "$(echo "$OUT4_EMPTY_JUST" | jq -r '.status')" = "NEEDS_CLARIFICATION" ] || fail "empty justification must not grant READY_WITH_ACCEPTED_RISK"

OUT4_WS_JUST=$(sh "$QM_READINESS" "$TMP/story_with_ledger.md" 62 70 "$TMP/no_unmet.json" accept_risk "   ")
[ "$(echo "$OUT4_WS_JUST" | jq -r '.status')" = "NEEDS_CLARIFICATION" ] || fail "whitespace-only justification must not grant READY_WITH_ACCEPTED_RISK"

OUT4_REAL=$(sh "$QM_READINESS" "$TMP/story_with_ledger.md" 62 70 "$TMP/no_unmet.json" accept_risk "I need to ship this week and will revisit")
[ "$(echo "$OUT4_REAL" | jq -r '.status')" = "READY_WITH_ACCEPTED_RISK" ] || fail "non-empty justification must grant READY_WITH_ACCEPTED_RISK, got: $OUT4_REAL"
[ "$(echo "$OUT4_REAL" | jq -r '.acceptance_justification')" = "I need to ship this week and will revisit" ] \
  || fail "acceptance_justification not recorded verbatim"

# accept_risk on an ALREADY-READY story must not do anything (no override needed/possible)
OUT4_ALREADY_READY=$(sh "$QM_READINESS" "$TMP/story_with_ledger.md" 90 70 "$TMP/no_unmet.json" accept_risk "some reason")
[ "$(echo "$OUT4_ALREADY_READY" | jq -r '.status')" = "READY" ] || fail "accept_risk on an already-READY story must stay READY"

# --- Case 5: empty Judgment Ledger trips no_developer_judgment_recorded regardless of score ---
OUT5=$(sh "$QM_READINESS" "$TMP/story_empty_ledger.md" 100 70 "$TMP/no_unmet.json")
[ "$(echo "$OUT5" | jq -r '.status')" = "NOT_READY" ] || fail "empty ledger + 100/100 must still be NOT_READY, got: $OUT5"
echo "$OUT5" | jq -e '.unmet_critical_conditions | index("no_developer_judgment_recorded") != null' >/dev/null \
  || fail "no_developer_judgment_recorded not named for an empty ledger"

echo "OK: test_readiness_gate.sh"
