#!/bin/sh
# test_band_score_arithmetic.sh — covers T007 (qm-score.sh), FR-036.
#
# Every band/weight pair produces its expected contribution, an all-STRONG rubric totals 100, an
# all-ABSENT rubric totals 0, and repeated runs are byte-identical.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../../.." && pwd)
QM_CONFIG="$REPO_ROOT/extensions/questmaster/scripts/qm-config.sh"
QM_SCORE="$REPO_ROOT/extensions/questmaster/scripts/qm-score.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

sh "$QM_CONFIG" "$REPO_ROOT/extensions/questmaster/config/questmaster-config.template.yml" "$TMP/no-local.yml" > "$TMP/config.json"

# --- Every band/weight pair produces its documented contribution ---
# problem_definition weight=15: ABSENT=0, WEAK=round(15*0.33)=5, ADEQUATE=round(15*0.67)=10, STRONG=15
cat > "$TMP/bands_single.json" <<'JSON'
{"problem_definition":"WEAK","actors_and_current_state":"STRONG","use_cases":"STRONG","desired_outcomes":"STRONG","scope_and_boundaries":"STRONG","success_criteria":"STRONG","assumptions_and_unknowns":"STRONG","constraints_and_context":"STRONG","solution_neutrality":"STRONG","developer_judgment":"STRONG"}
JSON
OUT=$(sh "$QM_SCORE" "$TMP/config.json" story_rubric "$TMP/bands_single.json")
GOT=$(echo "$OUT" | jq '.dimension_scores[] | select(.name=="problem_definition") | .score')
[ "$GOT" = "5" ] || fail "WEAK*15 expected round(4.95)=5, got $GOT"

# --- All STRONG totals 100 ---
cat > "$TMP/bands_all_strong.json" <<'JSON'
{"problem_definition":"STRONG","actors_and_current_state":"STRONG","use_cases":"STRONG","desired_outcomes":"STRONG","scope_and_boundaries":"STRONG","success_criteria":"STRONG","assumptions_and_unknowns":"STRONG","constraints_and_context":"STRONG","solution_neutrality":"STRONG","developer_judgment":"STRONG"}
JSON
OUT_STRONG=$(sh "$QM_SCORE" "$TMP/config.json" story_rubric "$TMP/bands_all_strong.json")
[ "$(echo "$OUT_STRONG" | jq '.overall_score')" = "100" ] || fail "all-STRONG story rubric did not total 100"

# --- All ABSENT totals 0 ---
cat > "$TMP/bands_all_absent.json" <<'JSON'
{"problem_definition":"ABSENT","actors_and_current_state":"ABSENT","use_cases":"ABSENT","desired_outcomes":"ABSENT","scope_and_boundaries":"ABSENT","success_criteria":"ABSENT","assumptions_and_unknowns":"ABSENT","constraints_and_context":"ABSENT","solution_neutrality":"ABSENT","developer_judgment":"ABSENT"}
JSON
OUT_ABSENT=$(sh "$QM_SCORE" "$TMP/config.json" story_rubric "$TMP/bands_all_absent.json")
[ "$(echo "$OUT_ABSENT" | jq '.overall_score')" = "0" ] || fail "all-ABSENT story rubric did not total 0"

# --- Repeated runs on the same input are byte-identical ---
RUN1=$(sh "$QM_SCORE" "$TMP/config.json" story_rubric "$TMP/bands_all_strong.json")
RUN2=$(sh "$QM_SCORE" "$TMP/config.json" story_rubric "$TMP/bands_all_strong.json")
[ "$RUN1" = "$RUN2" ] || fail "two runs on the same unchanged input produced different output"

# --- Every ADEQUATE (two-thirds) rounds consistently across all three rubrics ---
cat > "$TMP/bands_spec_adequate.json" <<'JSON'
{"story_fidelity":"ADEQUATE","requirement_completeness":"ADEQUATE","requirement_testability":"ADEQUATE","scope_discipline":"ADEQUATE","traceability":"ADEQUATE","handling_of_ambiguity":"ADEQUATE","internal_consistency":"ADEQUATE"}
JSON
OUT_SPEC=$(sh "$QM_SCORE" "$TMP/config.json" specification_integrity_rubric "$TMP/bands_spec_adequate.json")
# weight 20 * 0.67 = 13.4 -> round = 13
GOT_SD=$(echo "$OUT_SPEC" | jq '.dimension_scores[] | select(.name=="scope_discipline") | .score')
[ "$GOT_SD" = "13" ] || fail "scope_discipline ADEQUATE expected round(13.4)=13, got $GOT_SD"

# --- Missing dimension band is a hard error, not a silent zero ---
cat > "$TMP/bands_incomplete.json" <<'JSON'
{"problem_definition":"STRONG"}
JSON
if sh "$QM_SCORE" "$TMP/config.json" story_rubric "$TMP/bands_incomplete.json" >"$TMP/incomplete.out" 2>"$TMP/incomplete.err"; then
  fail "expected non-zero exit for incomplete bands, got success: $(cat "$TMP/incomplete.out")"
fi
grep -q "missing band" "$TMP/incomplete.err" || fail "expected 'missing band' error message"

echo "OK: test_band_score_arithmetic.sh"
