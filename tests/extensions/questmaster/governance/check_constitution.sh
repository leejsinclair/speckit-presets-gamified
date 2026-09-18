#!/bin/sh
# check_constitution.sh — Governance tier (tasks.md T011).
#
# Spawns an INDEPENDENT agent — a fresh `claude -p` (headless print-mode) invocation, which by
# construction has no access to whatever conversation authored the artifact under check — given
# only .specify/memory/constitution.md and the artifact, and asks it to verify every Constitution
# Check row's claimed status against the actual principle text and cited evidence. Fails the
# suite (non-zero exit) if any row is unsupported or overstated (research.md §11, Constitution
# Principle XIII applied reflexively to Questmaster's own planning artifacts).
#
# This is the same independent-assessment mechanism FR-037 requires everywhere else, applied to
# Questmaster's own plan.md — the first thing the suite runs, since a design whose own compliance
# claims are unverified is not worth testing further.
#
# Usage:
#   check_constitution.sh [<artifact-file>]
#
# Default <artifact-file>: the first specs/*/plan.md found under the repository root (this is
# where a Constitution Check table lives per this project's Spec Kit convention).
#
# Requires: the `claude` CLI (Claude Code) on PATH, with API access — this is the one place in
# the test suite that is not dependency-free, because verifying judgment requires judgment
# (research.md §11's governance tier rationale). Costs real tokens per run.
#
# Env:
#   QUESTMASTER_SKIP_GOVERNANCE=1   skip this tier entirely (exit 0 with a warning) — for fast
#                                    local iteration only; run.sh does not set this itself.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../../.." && pwd)

if [ "${QUESTMASTER_SKIP_GOVERNANCE:-0}" = "1" ]; then
  echo "check_constitution: SKIPPED (QUESTMASTER_SKIP_GOVERNANCE=1)"
  exit 0
fi

CONSTITUTION="$REPO_ROOT/.specify/memory/constitution.md"
if [ ! -f "$CONSTITUTION" ]; then
  echo "check_constitution: constitution not found at $CONSTITUTION" >&2
  exit 1
fi

ARTIFACT="${1:-}"
if [ -z "$ARTIFACT" ]; then
  ARTIFACT=$(find "$REPO_ROOT/specs" -maxdepth 2 -name plan.md 2>/dev/null | sort | head -n1)
fi
if [ -z "$ARTIFACT" ] || [ ! -f "$ARTIFACT" ]; then
  echo "check_constitution: no artifact found to check (pass one explicitly)" >&2
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "check_constitution: 'claude' CLI not found on PATH — cannot spawn an independent agent" >&2
  exit 1
fi

CONSTITUTION_TEXT=$(cat "$CONSTITUTION")
ARTIFACT_TEXT=$(cat "$ARTIFACT")

PROMPT=$(cat <<PROMPT_EOF
You are an independent governance auditor. You have NOT seen any conversation that authored the
artifact below — you are being given only this constitution and this artifact, exactly as
Constitution Principle XIII (Independent Assessment) and the Governance section require.

Your job: verify every row of the artifact's "Constitution Check" table (there may be one under
"Constitution Check" and a second, possibly revised, under "Post-Design Constitution Check" — use
the most complete/final one) against the ACTUAL principle text in the constitution below and the
evidence the row cites. A row may claim PASS, CONDITIONAL PASS, or FAIL.

A PASS (or CONDITIONAL PASS) is CONFIRMED only if:
- the row names a SPECIFIC property of the artifact/design that satisfies the principle (not a
  restatement of the principle's own wording or a bare assertion of compliance), AND
- where the principle sets a budget, threshold, or requires a measured/tested result, the row
  either quotes the actual measured value or explicitly and honestly labels itself as a target /
  not-yet-measured (a CONDITIONAL PASS that HONESTLY says "not yet measured" is CONFIRMED as a
  CONDITIONAL PASS, not disputed for lacking a number it explicitly admits it doesn't have yet —
  only dispute a row that claims a clean, unconditional PASS while relying on an unmeasured
  number, or whose CONDITIONAL PASS status doesn't match what it actually supports).

A row is DISPUTED if it claims more certainty than its own cited evidence supports, cites evidence
that doesn't actually exist in the artifact, or contradicts the principle's actual requirement.

=== CONSTITUTION (constitution.md) ===
$CONSTITUTION_TEXT
=== END CONSTITUTION ===

=== ARTIFACT UNDER CHECK ($ARTIFACT) ===
$ARTIFACT_TEXT
=== END ARTIFACT ===

Respond with structured JSON only, one row per constitution principle found in the artifact's
table(s), each with your independent verdict and reasoning naming the specific evidence you
checked (or the specific gap you found).
PROMPT_EOF
)

SCHEMA='{"type":"object","properties":{"rows":{"type":"array","items":{"type":"object","properties":{"principle":{"type":"string"},"verdict":{"type":"string","enum":["CONFIRMED","DISPUTED"]},"reasoning":{"type":"string"}},"required":["principle","verdict","reasoning"]}},"overall":{"type":"string","enum":["PASS","FAIL"]}},"required":["rows","overall"]}'

RESULT_JSON=$(claude -p --output-format json --json-schema "$SCHEMA" "$PROMPT")

STRUCTURED=$(echo "$RESULT_JSON" | jq -c '.structured_output')
if [ "$STRUCTURED" = "null" ] || [ -z "$STRUCTURED" ]; then
  echo "check_constitution: agent did not return structured output" >&2
  echo "$RESULT_JSON" >&2
  exit 1
fi

echo "$STRUCTURED" | jq -r '.rows[] | "  [\(.verdict)] \(.principle) — \(.reasoning)"'

DISPUTED_COUNT=$(echo "$STRUCTURED" | jq '[.rows[] | select(.verdict == "DISPUTED")] | length')
OVERALL=$(echo "$STRUCTURED" | jq -r '.overall')

echo ""
echo "check_constitution: $(echo "$STRUCTURED" | jq '.rows | length') rows checked, $DISPUTED_COUNT disputed, agent overall=$OVERALL"

if [ "$DISPUTED_COUNT" -gt 0 ] || [ "$OVERALL" = "FAIL" ]; then
  echo "check_constitution: FAIL — at least one Constitution Check row is unsupported or overstated" >&2
  exit 1
fi

echo "check_constitution: PASS — all rows independently confirmed"
exit 0
