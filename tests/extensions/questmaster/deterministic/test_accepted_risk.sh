#!/bin/sh
# test_accepted_risk.sh — covers qm-record.sh's decision lifecycle, FR-039 [US2].
#
# An `outstanding` Decision is restated at every later stage with its acceptance date and the
# developer's own reason; an auto-resolution without resolution_evidence is rejected; a recorded
# auto-resolution carries resolved_by: questmaster, never developer, and is NOT written as a
# Judgment Ledger entry.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../../.." && pwd)
QM_RECORD="$REPO_ROOT/extensions/questmaster/scripts/qm-record.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

cat > "$TMP/story.md" <<'MD'
# Story
## Questmaster Record
### Judgment Ledger
### Comprehension
### Decisions
MD

sh "$QM_RECORD" add-decision "$TMP/story.md" "2026-09-12" \
  "Story classified NEEDS_CLARIFICATION (62/100, threshold 70). Developer chose accept risk. Their reason: \"Support data is in a dashboard I can't export this week.\" -> READY_WITH_ACCEPTED_RISK." \
  outstanding

# --- Case 1: an outstanding decision is readable with its date and reason intact (restatable) ---
LIST1=$(sh "$QM_RECORD" list-decisions "$TMP/story.md")
[ "$(echo "$LIST1" | jq 'length')" = "1" ] || fail "expected exactly 1 decision"
[ "$(echo "$LIST1" | jq -r '.[0].status')" = "outstanding" ] || fail "decision should be outstanding"
[ "$(echo "$LIST1" | jq -r '.[0].date')" = "2026-09-12" ] || fail "acceptance date not preserved"
echo "$LIST1" | jq -r '.[0].narrative' | grep -q "can't export this week" || fail "developer's own reason not preserved verbatim"

# --- Case 2: auto-resolution WITHOUT cited evidence is rejected (not silently recorded) ---
if sh "$QM_RECORD" resolve-decision "$TMP/story.md" "can't export" questmaster "2026-09-16" "" 2>"$TMP/err1.txt"; then
  fail "auto-resolution with empty evidence must be rejected"
fi
grep -qi "evidence" "$TMP/err1.txt" || fail "rejection message should mention evidence"
STILL_OUTSTANDING=$(sh "$QM_RECORD" list-decisions "$TMP/story.md")
[ "$(echo "$STILL_OUTSTANDING" | jq -r '.[0].status')" = "outstanding" ] \
  || fail "decision must remain outstanding after a rejected auto-resolution attempt"

# --- Case 3: auto-resolution WITH cited evidence succeeds, attributed to questmaster (never developer) ---
sh "$QM_RECORD" resolve-decision "$TMP/story.md" "can't export" questmaster "2026-09-16" \
  "story.md §9 now records the exported ticket counts as a Known Fact rather than an assumption"
RESOLVED=$(sh "$QM_RECORD" list-decisions "$TMP/story.md")
[ "$(echo "$RESOLVED" | jq -r '.[0].status')" = "resolved" ] || fail "decision should now be resolved"
[ "$(echo "$RESOLVED" | jq -r '.[0].resolved_by')" = "questmaster" ] || fail "resolved_by must be questmaster, never developer"
echo "$RESOLVED" | jq -r '.[0].resolution_evidence' | grep -q "exported ticket counts" || fail "resolution_evidence not recorded"

# --- Case 4: an auto-resolution is NEVER written as a Judgment Ledger entry ---
LEDGER=$(sh "$QM_RECORD" list-ledger "$TMP/story.md")
[ "$(echo "$LEDGER" | jq 'length')" = "0" ] || fail "auto-resolution must not appear in the Judgment Ledger, found: $LEDGER"

# --- Case 5: a SEPARATE outstanding decision left untouched stays outstanding (never closed by silence) ---
cat > "$TMP/story2.md" <<'MD'
# Story
## Questmaster Record
### Judgment Ledger
### Comprehension
### Decisions
MD
sh "$QM_RECORD" add-decision "$TMP/story2.md" "2026-09-10" "Risk A accepted. Reason: \"time pressure\"." outstanding
sh "$QM_RECORD" add-decision "$TMP/story2.md" "2026-09-11" "Risk B accepted. Reason: \"low priority\"." outstanding
# Only resolve Risk A; Risk B must remain outstanding.
sh "$QM_RECORD" resolve-decision "$TMP/story2.md" "Risk A" questmaster "2026-09-16" "evidence for A"
LIST2=$(sh "$QM_RECORD" list-decisions "$TMP/story2.md")
[ "$(echo "$LIST2" | jq '[.[] | select(.narrative | contains("Risk B"))][0].status')" = '"outstanding"' ] \
  || fail "Risk B must remain outstanding when untouched"
[ "$(echo "$LIST2" | jq '[.[] | select(.narrative | contains("Risk A"))][0].status')" = '"resolved"' ] \
  || fail "Risk A should be resolved"

# --- Case 6: developer-resolution path (not auto) does not require the evidence guard ---
cat > "$TMP/story3.md" <<'MD'
# Story
## Questmaster Record
### Judgment Ledger
### Comprehension
### Decisions
MD
sh "$QM_RECORD" add-decision "$TMP/story3.md" "2026-09-10" "Risk C accepted. Reason: \"whatever\"." outstanding
sh "$QM_RECORD" resolve-decision "$TMP/story3.md" "Risk C" developer "2026-09-12" ""
LIST3=$(sh "$QM_RECORD" list-decisions "$TMP/story3.md")
[ "$(echo "$LIST3" | jq -r '.[0].resolved_by')" = "developer" ] || fail "developer resolution should be attributed to developer"
[ "$(echo "$LIST3" | jq -r '.[0].status')" = "resolved" ] || fail "developer resolution should mark resolved"

echo "OK: test_accepted_risk.sh"
