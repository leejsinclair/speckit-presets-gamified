#!/bin/sh
# Dependency-free test runner for the Questmaster extension.
#
# Runs all three tiers, governance first (research.md §11: a design whose own compliance claims
# are unverified is not worth testing further), then deterministic, then judgment. Exits non-zero
# if any tier fails. Requires nothing beyond sh/jq (already required by
# .specify/scripts/bash/common.sh) — no external test framework.
#
# Usage: tests/extensions/questmaster/run.sh [--skip-judgment]
#   --skip-judgment   skip the judgment tier (it spawns real assessments N times per fixture and
#                      is slow / costs tokens); governance and deterministic still run.

set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR" || exit 1

SKIP_JUDGMENT=0
for arg in "$@"; do
  case "$arg" in
    --skip-judgment) SKIP_JUDGMENT=1 ;;
  esac
done

TOTAL=0
FAILED=0
FAILED_NAMES=""

run_one() {
  script="$1"
  name=$(basename "$script")
  TOTAL=$((TOTAL + 1))
  printf '  %-45s' "$name"
  if sh "$script" >"/tmp/qm-test-$$.log" 2>&1; then
    echo "PASS"
  else
    echo "FAIL"
    FAILED=$((FAILED + 1))
    FAILED_NAMES="$FAILED_NAMES $name"
    sed 's/^/      /' "/tmp/qm-test-$$.log"
  fi
  rm -f "/tmp/qm-test-$$.log"
}

echo "== Governance tier (runs first) =="
if [ -d governance ]; then
  for f in governance/*.sh; do
    [ -e "$f" ] || continue
    run_one "$f"
  done
else
  echo "  (no governance/ directory)"
fi

echo ""
echo "== Deterministic tier =="
if [ -d deterministic ]; then
  for f in deterministic/*.sh; do
    [ -e "$f" ] || continue
    run_one "$f"
  done
else
  echo "  (no deterministic/ directory)"
fi

if [ "$SKIP_JUDGMENT" -eq 1 ]; then
  echo ""
  echo "== Judgment tier == (skipped: --skip-judgment)"
else
  echo ""
  echo "== Judgment tier =="
  if [ -x judgment/eval.sh ]; then
    run_one judgment/eval.sh
  else
    echo "  (no judgment/eval.sh, or not executable)"
  fi
fi

echo ""
echo "== Summary =="
echo "  $TOTAL run, $((TOTAL - FAILED)) passed, $FAILED failed"
if [ "$FAILED" -gt 0 ]; then
  echo "  Failed:$FAILED_NAMES"
  exit 1
fi
exit 0
