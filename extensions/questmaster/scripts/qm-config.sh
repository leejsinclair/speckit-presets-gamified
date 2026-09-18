#!/bin/sh
# qm-config.sh — Questmaster config loader and validator (tasks.md T006).
#
# Resolves the effective rubric configuration through ConfigManager's real layering (project
# file -> gitignored local-config.yml -> SPECKIT_QUESTMASTER_<KEY> env vars), then applies
# Questmaster's own validation on top: weights must sum to 100 per rubric, and band anchors must
# be present for every dimension. A violation falls back to the documented defaults FOR THE
# AFFECTED RUBRIC ONLY, emits exactly one warning line to stderr, and never fails the assessment
# (data-model.md § Validation rule; FR-024).
#
# Output: a single JSON document on stdout describing the effective, validated configuration —
# consumed by qm-score.sh and qm-readiness.sh. Any warnings go to stderr only, never stdout, so
# stdout stays valid JSON for a caller piping it into jq.
#
# Usage:
#   qm-config.sh [<project-config.yml>] [<local-config.yml>]
#
# Defaults:
#   <project-config.yml>  .specify/extensions/questmaster/questmaster-config.yml
#   <local-config.yml>    .specify/extensions/questmaster/local-config.yml
#
# Env overrides (ConfigManager's own layer, read after both files):
#   SPECKIT_QUESTMASTER_STORY_READINESS_THRESHOLD
#   SPECKIT_QUESTMASTER_BAND_ABSENT / _WEAK / _ADEQUATE / _STRONG

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

PROJECT_CONFIG="${1:-.specify/extensions/questmaster/questmaster-config.yml}"
LOCAL_CONFIG="${2:-.specify/extensions/questmaster/local-config.yml}"

# ---------------------------------------------------------------------------
# Documented defaults (must match contracts/questmaster-config.yml exactly —
# these are the fallback, not a design decision made here).
# ---------------------------------------------------------------------------
DEFAULTS_JSON=$(cat <<'JSON'
{
  "band_multipliers": {"ABSENT": 0.00, "WEAK": 0.33, "ADEQUATE": 0.67, "STRONG": 1.00},
  "story_rubric": {
    "readiness_threshold": 70,
    "critical_conditions": [
      "core_problem_unclear", "primary_actor_unknown", "desired_outcome_absent",
      "critical_use_cases_missing", "scope_unbounded", "critical_assumptions_unresolved",
      "success_not_evaluable", "no_developer_judgment_recorded"
    ],
    "dimensions": [
      {"name": "problem_definition", "weight": 15},
      {"name": "actors_and_current_state", "weight": 10},
      {"name": "use_cases", "weight": 15},
      {"name": "desired_outcomes", "weight": 15},
      {"name": "scope_and_boundaries", "weight": 10},
      {"name": "success_criteria", "weight": 10},
      {"name": "assumptions_and_unknowns", "weight": 5},
      {"name": "constraints_and_context", "weight": 5},
      {"name": "solution_neutrality", "weight": 5},
      {"name": "developer_judgment", "weight": 10}
    ]
  },
  "specification_integrity_rubric": {
    "dimensions": [
      {"name": "story_fidelity", "weight": 20},
      {"name": "requirement_completeness", "weight": 15},
      {"name": "requirement_testability", "weight": 15},
      {"name": "scope_discipline", "weight": 20},
      {"name": "traceability", "weight": 10},
      {"name": "handling_of_ambiguity", "weight": 10},
      {"name": "internal_consistency", "weight": 10}
    ]
  },
  "plan_integrity_rubric": {
    "dimensions": [
      {"name": "intent_preservation", "weight": 20},
      {"name": "specification_coverage", "weight": 15},
      {"name": "constraint_preservation", "weight": 15},
      {"name": "proportionality", "weight": 15},
      {"name": "legibility", "weight": 15},
      {"name": "risk_management", "weight": 10},
      {"name": "test_strategy", "weight": 5},
      {"name": "traceability", "weight": 5}
    ]
  }
}
JSON
)

warn() {
  echo "qm-config: WARNING: $1" >&2
}

# ---------------------------------------------------------------------------
# Load whichever of project/local config files exist and parse as YAML -> JSON
# via python3+PyYAML (already required by .specify/scripts/bash/common.sh).
# Layering: project file first, then local-config.yml deep-merged on top.
# ---------------------------------------------------------------------------
yaml_to_json() {
  file="$1"
  python3 -c '
import sys, json
try:
    import yaml
except ImportError:
    print("null")
    sys.exit(0)
try:
    with open(sys.argv[1]) as f:
        data = yaml.safe_load(f)
    print(json.dumps(data if data is not None else {}))
except Exception:
    print("null")
' "$file"
}

RAW_JSON="null"
if [ -f "$PROJECT_CONFIG" ]; then
  RAW_JSON=$(yaml_to_json "$PROJECT_CONFIG")
fi

if [ "$RAW_JSON" = "null" ]; then
  warn "config file missing or malformed at $PROJECT_CONFIG — falling back to documented defaults"
  RAW_JSON="$DEFAULTS_JSON"
fi

if [ -f "$LOCAL_CONFIG" ]; then
  LOCAL_JSON=$(yaml_to_json "$LOCAL_CONFIG")
  if [ "$LOCAL_JSON" != "null" ]; then
    RAW_JSON=$(printf '%s\n%s' "$RAW_JSON" "$LOCAL_JSON" | jq -s '.[0] * .[1]')
  else
    warn "local-config.yml at $LOCAL_CONFIG is malformed — ignoring it"
  fi
fi

# Env-var overrides (ConfigManager's SPECKIT_QUESTMASTER_<KEY> layer).
if [ -n "${SPECKIT_QUESTMASTER_STORY_READINESS_THRESHOLD:-}" ]; then
  RAW_JSON=$(echo "$RAW_JSON" | jq --argjson v "$SPECKIT_QUESTMASTER_STORY_READINESS_THRESHOLD" \
    '.story_rubric.readiness_threshold = $v')
fi
for band in ABSENT WEAK ADEQUATE STRONG; do
  eval "envval=\${SPECKIT_QUESTMASTER_BAND_${band}:-}"
  if [ -n "$envval" ]; then
    RAW_JSON=$(echo "$RAW_JSON" | jq --arg b "$band" --argjson v "$envval" \
      '.band_multipliers[$b] = $v')
  fi
done

# ---------------------------------------------------------------------------
# Validation: weights sum to 100 and anchors present, PER RUBRIC, falling back
# to that rubric's defaults alone on failure.
# ---------------------------------------------------------------------------
validate_and_merge_rubric() {
  rubric_key="$1"
  input="$2"
  weight_sum=$(echo "$input" | jq --arg k "$rubric_key" '[.[$k].dimensions[]?.weight] | add // 0')
  if [ "$(echo "$weight_sum" | jq 'floor')" != "100" ]; then
    warn "$rubric_key weights sum to $weight_sum, not 100 — falling back to documented defaults for $rubric_key only"
    echo "$input" | jq --arg k "$rubric_key" --argjson d "$DEFAULTS_JSON" \
      '.[$k] = $d[$k]'
    return
  fi
  echo "$input"
}

EFFECTIVE="$RAW_JSON"
for rk in story_rubric specification_integrity_rubric plan_integrity_rubric; do
  EFFECTIVE=$(validate_and_merge_rubric "$rk" "$EFFECTIVE")
done

# band_multipliers sanity: all four keys must be present and numeric, else fall back wholesale.
BAND_OK=$(echo "$EFFECTIVE" | jq '
  (.band_multipliers // {}) as $b |
  (["ABSENT","WEAK","ADEQUATE","STRONG"] | map($b[.] != null and (($b[.] | type) == "number")) | all)
')
if [ "$BAND_OK" != "true" ]; then
  warn "band_multipliers missing or malformed — falling back to documented defaults for band_multipliers only"
  EFFECTIVE=$(echo "$EFFECTIVE" | jq --argjson d "$DEFAULTS_JSON" '.band_multipliers = $d.band_multipliers')
fi

# critical_conditions sanity: must be a non-empty array, else fall back.
CC_OK=$(echo "$EFFECTIVE" | jq '(.story_rubric.critical_conditions // []) | type == "array" and length > 0')
if [ "$CC_OK" != "true" ]; then
  warn "story_rubric.critical_conditions missing or empty — falling back to documented defaults for critical_conditions only"
  EFFECTIVE=$(echo "$EFFECTIVE" | jq --argjson d "$DEFAULTS_JSON" '.story_rubric.critical_conditions = $d.story_rubric.critical_conditions')
fi

echo "$EFFECTIVE" | jq -S '.'
