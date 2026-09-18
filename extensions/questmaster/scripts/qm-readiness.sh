#!/bin/sh
# qm-readiness.sh — story readiness classifier (tasks.md T018).
#
# Applies data-model.md's Story Integrity Result classification rule (FR-012) deterministically:
#   1. unmet_critical_conditions non-empty -> NOT_READY, regardless of overall_score.
#   2. else overall_score >= readiness_threshold -> READY.
#   3. else -> NEEDS_CLARIFICATION.
#   4. READY_WITH_ACCEPTED_RISK is NEVER a direct output of scoring: it is applied only when the
#      caller supplies developer_choice=accept_risk AND a non-empty, non-whitespace justification
#      the developer actually typed (FR-014) — a menu selection, empty string, or missing
#      argument leaves the base classification unchanged.
#
# `no_developer_judgment_recorded` is the one critical condition this script computes itself
# (rather than trusting the LLM's judgment call) because it is a plain file fact, not an
# assessment of content: the Judgment Ledger either has entries or it doesn't (FR-012, FR-035).
# Every other critical condition (core_problem_unclear, primary_actor_unknown, ...) is judged by
# the calling command from the story's content and passed in.
#
# Usage:
#   qm-readiness.sh <story_file> <overall_score> <readiness_threshold> <llm_unmet_conditions.json> \
#                   [<developer_choice> [<justification>]]
#
#   <story_file>                path to story.md / pending-story.md (read only, to check the
#                                Judgment Ledger — never edited by this script)
#   <overall_score>              integer 0-100, from qm-score.sh
#   <readiness_threshold>        integer, from config (story_rubric.readiness_threshold)
#   <llm_unmet_conditions.json>  JSON array of critical-condition names the LLM judged unmet from
#                                the story's CONTENT — MUST NOT include no_developer_judgment_recorded,
#                                which this script adds itself when applicable
#   <developer_choice>           "none" (default) | "revise" | "accept_risk"
#   <justification>              the developer's own typed words; required (non-empty after
#                                 trimming) for accept_risk to take effect
#
# Output (stdout): JSON —
#   {
#     "unmet_critical_conditions": [...],
#     "overall_score": <int>, "readiness_threshold": <int>,
#     "status": "NOT_READY"|"NEEDS_CLARIFICATION"|"READY"|"READY_WITH_ACCEPTED_RISK",
#     "developer_choice": "revise"|"accept_risk"|null,
#     "acceptance_justification": "<verbatim>"|null
#   }

set -eu

STORY_FILE="${1:?usage: qm-readiness.sh <story_file> <overall_score> <threshold> <llm_unmet.json> [choice] [justification]}"
OVERALL_SCORE="${2:?usage: qm-readiness.sh <story_file> <overall_score> <threshold> <llm_unmet.json> [choice] [justification]}"
THRESHOLD="${3:?usage: qm-readiness.sh <story_file> <overall_score> <threshold> <llm_unmet.json> [choice] [justification]}"
LLM_UNMET_FILE="${4:?usage: qm-readiness.sh <story_file> <overall_score> <threshold> <llm_unmet.json> [choice] [justification]}"
CHOICE="${5:-none}"
JUSTIFICATION="${6:-}"

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
QM_RECORD="$SCRIPT_DIR/qm-record.sh"

if [ ! -f "$LLM_UNMET_FILE" ]; then
  echo "qm-readiness: llm_unmet_conditions file not found: $LLM_UNMET_FILE" >&2
  exit 1
fi

# --- Compute no_developer_judgment_recorded from the actual Judgment Ledger, not from judgment. ---
LEDGER_EMPTY="true"
if [ -f "$STORY_FILE" ]; then
  LEDGER_COUNT=$(sh "$QM_RECORD" list-ledger "$STORY_FILE" 2>/dev/null | jq 'length' || echo 0)
  if [ "$LEDGER_COUNT" -gt 0 ]; then
    LEDGER_EMPTY="false"
  fi
fi

UNMET=$(jq -n --slurpfile llm "$LLM_UNMET_FILE" --arg empty "$LEDGER_EMPTY" '
  ($llm[0] // []) as $base |
  if $empty == "true" then ($base + ["no_developer_judgment_recorded"] | unique) else $base end
')

UNMET_COUNT=$(echo "$UNMET" | jq 'length')

# --- Base classification (steps 1-3) ---
if [ "$UNMET_COUNT" -gt 0 ]; then
  BASE_STATUS="NOT_READY"
elif [ "$OVERALL_SCORE" -ge "$THRESHOLD" ]; then
  BASE_STATUS="READY"
else
  BASE_STATUS="NEEDS_CLARIFICATION"
fi

# --- Step 4: developer override, only with a genuine typed justification ---
STATUS="$BASE_STATUS"
FINAL_CHOICE="null"
FINAL_JUSTIFICATION="null"

TRIMMED_JUSTIFICATION=$(printf '%s' "$JUSTIFICATION" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

if [ "$BASE_STATUS" != "READY" ]; then
  case "$CHOICE" in
    accept_risk)
      if [ -n "$TRIMMED_JUSTIFICATION" ]; then
        STATUS="READY_WITH_ACCEPTED_RISK"
        FINAL_CHOICE="accept_risk"
        FINAL_JUSTIFICATION=$(printf '%s' "$JUSTIFICATION" | jq -R -s '.')
      fi
      # empty/whitespace-only justification: acceptance does NOT take effect, status unchanged
      ;;
    revise)
      FINAL_CHOICE="revise"
      ;;
    *)
      : # "none" or anything else: no override, status remains BASE_STATUS
      ;;
  esac
fi

jq -n \
  --argjson unmet "$UNMET" \
  --argjson score "$OVERALL_SCORE" \
  --argjson threshold "$THRESHOLD" \
  --arg status "$STATUS" \
  --argjson choice "$([ "$FINAL_CHOICE" = "null" ] && echo null || echo "\"$FINAL_CHOICE\"")" \
  --argjson justification "$FINAL_JUSTIFICATION" \
  '{
    unmet_critical_conditions: $unmet,
    overall_score: $score,
    readiness_threshold: $threshold,
    status: $status,
    developer_choice: $choice,
    acceptance_justification: $justification
  }'
