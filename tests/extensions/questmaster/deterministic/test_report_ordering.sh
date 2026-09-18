#!/bin/sh
# test_report_ordering.sh — covers qm-report.sh (tasks.md T010/T026), FR-038 [US2].
#
# The normative section order (decisions -> outstanding risk -> bands -> findings), the <=3-item
# worklist cap with the remainder counted and named, the explicit "No decision required." line
# when none qualify, and PRESERVED/REFINED/CLARIFIED aggregated in the presented output while the
# persisted report keeps every element (appendix is always the full table regardless).

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../../.." && pwd)
QM_REPORT="$REPO_ROOT/extensions/questmaster/scripts/qm-report.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

base_spec() {
  cat <<'JSON'
{
  "artifact_type": "Specification",
  "assessed_date": "2026-09-14",
  "against": "story.md",
  "context": "INDEPENDENT",
  "digests": [{"artifact":"story.md","digest":"sha256:aaa"},{"artifact":"spec.md","digest":"sha256:bbb"}],
  "decisions": [],
  "outstanding_risk": [],
  "dimension_bands": [{"name":"story_fidelity","band":"STRONG","score":20,"weight":20,"evidence":"e"}],
  "drift_counts": {"PRESERVED":21,"REFINED":4,"CLARIFIED":1,"DISCOVERED":0,"ACCEPTED_SCOPE_CHANGE":0,"UNJUSTIFIED_DRIFT":0},
  "findings": [],
  "appendix": [{"element":"REQ-001","classification":"PRESERVED","notes":"n"}]
}
JSON
}

# --- Case 1: >3 decisions -> capped at 3, remainder counted and named ---
base_spec | jq '.decisions = [
  {"summary":"A","question":"q","classification":"UNJUSTIFIED_DRIFT","severity":"High","finding_ref":1,"element_id":"REQ-011"},
  {"summary":"B","question":"q","classification":"UNJUSTIFIED_DRIFT","severity":"Medium","finding_ref":2,"element_id":"REQ-012"},
  {"summary":"C","question":"q","classification":"DISCOVERED","severity":"Medium","finding_ref":3,"element_id":"REQ-013"},
  {"summary":"D","question":"q","classification":"UNJUSTIFIED_DRIFT","severity":"Low","finding_ref":4,"element_id":"REQ-014"},
  {"summary":"E","question":"q","classification":"DISCOVERED","severity":"Low","finding_ref":5,"element_id":"REQ-019"}
]' > "$TMP/many.json"
OUT1=$(sh "$QM_REPORT" "$TMP/many.json")
[ "$(echo "$OUT1" | grep -c '^[0-9]\. \*\*')" = "3" ] || fail "expected exactly 3 numbered decision items shown"
echo "$OUT1" | grep -q "2 further items require a decision (REQ-014, REQ-019)" \
  || fail "remainder not counted and named correctly"

# --- Case 2: 0 decisions -> "No decision required." ---
base_spec > "$TMP/none.json"
OUT2=$(sh "$QM_REPORT" "$TMP/none.json")
echo "$OUT2" | grep -q "^No decision required\.$" || fail "empty decisions must say 'No decision required.'"

# --- Case 3: section order is Decisions -> Outstanding risk -> Integrity -> Drift summary -> Findings -> Appendix -> Advisory ---
base_spec | jq '.outstanding_risk = [{"accepted_date":"2026-09-12","stage":"story","score":62,"unmet_summary":"weak evidence","reason":"time pressure","note":"Still unresolved."}]' > "$TMP/ordered.json"
OUT3=$(sh "$QM_REPORT" "$TMP/ordered.json")
DEC_LINE=$(echo "$OUT3" | grep -n "^## Decisions for you" | head -1 | cut -d: -f1)
RISK_LINE=$(echo "$OUT3" | grep -n "^## Outstanding accepted risk" | head -1 | cut -d: -f1)
INTEGRITY_LINE=$(echo "$OUT3" | grep -n "^## Integrity" | head -1 | cut -d: -f1)
DRIFT_LINE=$(echo "$OUT3" | grep -n "^## Drift Classification summary" | head -1 | cut -d: -f1)
APPENDIX_LINE=$(echo "$OUT3" | grep -n "^## Appendix" | head -1 | cut -d: -f1)
ADVISORY_LINE=$(echo "$OUT3" | grep -n "^## Advisory note" | head -1 | cut -d: -f1)
[ "$DEC_LINE" -lt "$RISK_LINE" ] || fail "Decisions must come before Outstanding accepted risk"
[ "$RISK_LINE" -lt "$INTEGRITY_LINE" ] || fail "Outstanding accepted risk must come before Integrity"
[ "$INTEGRITY_LINE" -lt "$DRIFT_LINE" ] || fail "Integrity must come before Drift Classification summary"
[ "$DRIFT_LINE" -lt "$APPENDIX_LINE" ] || fail "Drift Classification summary must come before Appendix"
[ "$APPENDIX_LINE" -lt "$ADVISORY_LINE" ] || fail "Appendix must come before Advisory note"

# --- Case 4: aggregate counts in the Drift Classification summary, full table in the appendix ---
OUT4=$(sh "$QM_REPORT" "$TMP/none.json")
echo "$OUT4" | grep -q "26 elements compared: \*\*21 PRESERVED\*\*, \*\*4 REFINED\*\*, \*\*1 CLARIFIED\*\*\." \
  || fail "drift summary must aggregate PRESERVED/REFINED/CLARIFIED counts"
echo "$OUT4" | grep -q "^| REQ-001 | PRESERVED | n |$" || fail "appendix must retain the full per-element table"

echo "OK: test_report_ordering.sh"
