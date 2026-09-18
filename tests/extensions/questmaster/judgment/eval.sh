#!/bin/sh
# eval.sh — Judgment tier (tasks.md T051, Constitution XII, research.md §11).
#
# Runs REAL assessments — actual `claude -p` invocations against the actual rubric config — N
# times per fixture across both judgment corpora (story-fixtures/ and fixtures/), and reports:
#   - agreement rate against the human-assigned labels in judgment/expected/*.json
#   - run-to-run band/score variance (the FR-036/SC-009 reproducibility target: 90% of bands
#     stable across repeated runs, overall score within 5 points)
#
# This tier is NOT dependency-free (unlike deterministic/): it requires the `claude` CLI with API
# access and costs real tokens per run — that is inherent to evaluating judgment (Constitution
# XII's rationale: arithmetic/schema/control-flow tests say nothing about whether the assessment
# itself is correct or stable).
#
# Usage:
#   eval.sh [--n <runs>] [--limit <count>] [--story-only] [--cross-only] [--out <dir>]
#
#   --n <runs>       repeat each fixture this many times (default 3)
#   --limit <count>  only evaluate the first <count> fixtures per corpus (default: all)
#   --story-only     skip the cross-artifact corpus
#   --cross-only     skip the story-rubric corpus
#   --out <dir>      where to write the raw per-run JSON results (default: a mktemp -d)
#
# Exit code: non-zero if either corpus's agreement rate falls below the SC-016 target (80%) or
# reproducibility falls below the FR-036 target — see eval_impl.py's summary for the exact numbers.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if ! command -v claude >/dev/null 2>&1; then
  echo "eval.sh: 'claude' CLI not found on PATH — the judgment tier requires it to run real assessments" >&2
  exit 1
fi

exec python3 "$SCRIPT_DIR/eval_impl.py" "$@"
