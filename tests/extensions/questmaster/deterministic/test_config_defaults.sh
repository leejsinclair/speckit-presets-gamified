#!/bin/sh
# test_config_defaults.sh — covers T006 (qm-config.sh).
#
# Missing file, malformed YAML, and a rubric whose weights do not sum to 100 each fall back to
# defaults for that rubric only, emit exactly one warning, and do not fail the run.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../../.." && pwd)
QM_CONFIG="$REPO_ROOT/extensions/questmaster/scripts/qm-config.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }

# --- Case 1: missing file falls back wholesale, exits 0, exactly one warning line ---
OUT=$(sh "$QM_CONFIG" "$TMP/does-not-exist.yml" "$TMP/no-local.yml" 2>"$TMP/warn1.txt")
[ "$?" -eq 0 ] 2>/dev/null || true
WARN_LINES=$(wc -l < "$TMP/warn1.txt" | tr -d ' ')
[ "$WARN_LINES" = "1" ] || fail "expected exactly 1 warning for missing file, got $WARN_LINES: $(cat "$TMP/warn1.txt")"
grep -q "falling back to documented defaults" "$TMP/warn1.txt" || fail "missing-file warning text unexpected"
echo "$OUT" | jq -e '.story_rubric.dimensions | length == 10' >/dev/null || fail "missing file: story_rubric not defaulted"
echo "$OUT" | jq -e '(.story_rubric.dimensions | map(.weight) | add) == 100' >/dev/null || fail "missing file: story_rubric weights don't sum to 100"

# --- Case 2: malformed YAML falls back wholesale ---
printf ':::not: [valid yaml\n  - broken\n' > "$TMP/malformed.yml"
OUT2=$(sh "$QM_CONFIG" "$TMP/malformed.yml" "$TMP/no-local.yml" 2>"$TMP/warn2.txt")
WARN2_LINES=$(wc -l < "$TMP/warn2.txt" | tr -d ' ')
[ "$WARN2_LINES" = "1" ] || fail "expected exactly 1 warning for malformed YAML, got $WARN2_LINES"
echo "$OUT2" | jq -e '.plan_integrity_rubric.dimensions | length == 8' >/dev/null || fail "malformed file: plan rubric not defaulted"

# --- Case 3: a rubric whose weights don't sum to 100 falls back FOR THAT RUBRIC ONLY ---
cat > "$TMP/bad-weights.yml" <<'YML'
band_multipliers: {ABSENT: 0.00, WEAK: 0.33, ADEQUATE: 0.67, STRONG: 1.00}
story_rubric:
  readiness_threshold: 70
  critical_conditions: [core_problem_unclear]
  dimensions:
    - {name: problem_definition, weight: 15}
    - {name: use_cases, weight: 15}
specification_integrity_rubric:
  dimensions:
    - {name: story_fidelity, weight: 20}
    - {name: requirement_completeness, weight: 15}
    - {name: requirement_testability, weight: 15}
    - {name: scope_discipline, weight: 20}
    - {name: traceability, weight: 10}
    - {name: handling_of_ambiguity, weight: 10}
    - {name: internal_consistency, weight: 10}
plan_integrity_rubric:
  dimensions:
    - {name: intent_preservation, weight: 20}
    - {name: specification_coverage, weight: 15}
    - {name: constraint_preservation, weight: 15}
    - {name: proportionality, weight: 15}
    - {name: legibility, weight: 15}
    - {name: risk_management, weight: 10}
    - {name: test_strategy, weight: 5}
    - {name: traceability, weight: 5}
YML
OUT3=$(sh "$QM_CONFIG" "$TMP/bad-weights.yml" "$TMP/no-local.yml" 2>"$TMP/warn3.txt")
WARN3_LINES=$(wc -l < "$TMP/warn3.txt" | tr -d ' ')
[ "$WARN3_LINES" = "1" ] || fail "expected exactly 1 warning for bad story_rubric weights, got $WARN3_LINES: $(cat "$TMP/warn3.txt")"
grep -q "story_rubric weights sum to 30" "$TMP/warn3.txt" || fail "warning didn't name story_rubric/30: $(cat "$TMP/warn3.txt")"
echo "$OUT3" | jq -e '.story_rubric.dimensions | length == 10' >/dev/null || fail "story_rubric not defaulted after bad weights"
echo "$OUT3" | jq -e '(.specification_integrity_rubric.dimensions | map(.weight) | add) == 100' >/dev/null \
  || fail "specification_integrity_rubric (which was VALID) was wrongly altered"
echo "$OUT3" | jq -e '(.plan_integrity_rubric.dimensions | map(.weight) | add) == 100' >/dev/null \
  || fail "plan_integrity_rubric (which was VALID) was wrongly altered"

# --- Case 4: never fails the run (exit 0) even in every failure case above ---
sh "$QM_CONFIG" "$TMP/does-not-exist.yml" "$TMP/no-local.yml" >/dev/null 2>/dev/null || fail "missing config must not fail the run"
sh "$QM_CONFIG" "$TMP/malformed.yml" "$TMP/no-local.yml" >/dev/null 2>/dev/null || fail "malformed config must not fail the run"
sh "$QM_CONFIG" "$TMP/bad-weights.yml" "$TMP/no-local.yml" >/dev/null 2>/dev/null || fail "bad weights must not fail the run"

echo "OK: test_config_defaults.sh (4 cases)"
