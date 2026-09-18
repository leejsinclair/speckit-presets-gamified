#!/bin/sh
# test_comprehension_rounds.sh — covers qm-record.sh's comprehension-round mechanics, FR-041 [US3].
#
# Round 1 records exactly three questions; each subsequent run appends exactly one round holding
# exactly one question that differs from every question already recorded for that plan; a decline
# is recorded as DECLINED with outcome: declined rather than as an absence; and an exhausted
# question supply asks nothing rather than padding (tested here as: the calling command MUST
# consult used-comprehension-labels before adding a round, which this script makes possible —
# the "ask nothing" decision itself is the command's judgment call, not something this script
# performs, so this test verifies the mechanism that judgment call depends on).

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../../.." && pwd)
QM_RECORD="$REPO_ROOT/extensions/questmaster/scripts/qm-record.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

cat > "$TMP/plan.md" <<'MD'
# Plan
## Questmaster Record
### Judgment Ledger
### Comprehension
### Decisions
MD

# --- Case 1: Round 1 records exactly three questions ---
cat > "$TMP/round1.json" <<'JSON'
[{"label":"Most likely wrong","answer":"the sync assumption"},{"label":"Would cut","answer":"per-campaign granularity"},{"label":"Breaks first","answer":"the send path"}]
JSON
sh "$QM_RECORD" add-comprehension-round "$TMP/plan.md" 1 "2026-09-14" "asked before Plan Integrity assessment." "$TMP/round1.json"
ROUNDS1=$(sh "$QM_RECORD" list-comprehension "$TMP/plan.md")
[ "$(echo "$ROUNDS1" | jq 'length')" = "1" ] || fail "expected exactly 1 round after first checkpoint"
[ "$(echo "$ROUNDS1" | jq '.[0].questions | length')" = "3" ] || fail "round 1 must hold exactly 3 questions"

# --- Case 2: a subsequent run appends exactly ONE round holding exactly ONE question, and that
#     question's label differs from every question already recorded ---
USED=$(sh "$QM_RECORD" used-comprehension-labels "$TMP/plan.md")
[ "$(echo "$USED" | jq 'length')" = "3" ] || fail "expected 3 used labels after round 1"
NEW_LABEL="Hardest to reverse once built"
echo "$USED" | jq -e --arg l "$NEW_LABEL" '. as $u | ($u | index($l)) == null' >/dev/null \
  || fail "test setup error: candidate label already used"
cat > "$TMP/round2.json" <<JSON
[{"label":"$NEW_LABEL","answer":"the preference schema"}]
JSON
sh "$QM_RECORD" add-comprehension-round "$TMP/plan.md" 2 "2026-09-16" "asked on re-run; round 1 answers restated, not re-asked." "$TMP/round2.json"
ROUNDS2=$(sh "$QM_RECORD" list-comprehension "$TMP/plan.md")
[ "$(echo "$ROUNDS2" | jq 'length')" = "2" ] || fail "expected exactly 2 rounds after the re-run"
[ "$(echo "$ROUNDS2" | jq '.[1].questions | length')" = "1" ] || fail "round 2 must hold exactly 1 question"
[ "$(echo "$ROUNDS2" | jq -r '.[1].questions[0].label')" = "$NEW_LABEL" ] || fail "round 2's question label wrong"

# Round 1's answers are still present (restated, not re-asked / not lost).
[ "$(echo "$ROUNDS2" | jq '.[0].questions | length')" = "3" ] || fail "round 1's 3 questions must still be present after round 2"

USED2=$(sh "$QM_RECORD" used-comprehension-labels "$TMP/plan.md")
[ "$(echo "$USED2" | jq 'length')" = "4" ] || fail "expected 4 cumulative used labels after round 2"

# --- Case 3: a decline is recorded as DECLINED with outcome: declined, never as an absence ---
cat > "$TMP/plan_declined.md" <<'MD'
# Plan
## Questmaster Record
### Judgment Ledger
### Comprehension
### Decisions
MD
cat > "$TMP/declined.json" <<'JSON'
[{"label":"Most likely wrong","answer":"DECLINED"},{"label":"Would cut","answer":"DECLINED"},{"label":"Breaks first","answer":"DECLINED"}]
JSON
sh "$QM_RECORD" add-comprehension-round "$TMP/plan_declined.md" 1 "2026-09-14" "asked before Plan Integrity assessment." "$TMP/declined.json"
DECLINED_ROUNDS=$(sh "$QM_RECORD" list-comprehension "$TMP/plan_declined.md")
[ "$(echo "$DECLINED_ROUNDS" | jq -r '.[0].outcome')" = "declined" ] || fail "a fully declined round must report outcome: declined"
[ "$(echo "$DECLINED_ROUNDS" | jq -r '.[0].questions[0].answer')" = "DECLINED" ] || fail "declined answer must be recorded as the literal DECLINED, not blank"
[ "$(echo "$DECLINED_ROUNDS" | jq '.[0].questions | length')" = "3" ] || fail "a decline must still occupy all 3 question slots, not be recorded as an absence (empty array)"

echo "OK: test_comprehension_rounds.sh"
