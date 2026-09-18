#!/bin/sh
# qm-score.sh — deterministic band -> score arithmetic (tasks.md T007).
#
# The LLM assigns bands (ABSENT/WEAK/ADEQUATE/STRONG) with cited evidence; this script does every
# sum. `dimension_score = round(weight * multiplier)`; `overall_score = sum(dimension_scores)`
# clamped to 0-100 (data-model.md § Band, FR-036). Never let the model add these up itself —
# free-integer/hand-summed scores are not reproducible run to run (Constitution VI).
#
# Usage:
#   qm-score.sh <config.json> <rubric_key> <bands.json>
#
#   <config.json>   the output of qm-config.sh (effective, validated configuration)
#   <rubric_key>    one of: story_rubric | specification_integrity_rubric | plan_integrity_rubric
#   <bands.json>    a JSON object mapping every dimension name in that rubric to exactly one of
#                   "ABSENT" | "WEAK" | "ADEQUATE" | "STRONG", e.g.:
#                   {"problem_definition": "STRONG", "use_cases": "ADEQUATE", ...}
#
# Output (stdout): JSON —
#   {
#     "dimension_scores": [{"name":..., "band":..., "weight":..., "multiplier":..., "score":...}],
#     "overall_score": <int 0-100>
#   }
#
# Exits non-zero (and prints nothing to stdout) if any dimension in the rubric has no band
# assigned, or an unrecognized band value is given — a missing band must never silently score 0
# without the caller knowing it was never judged.

set -eu

CONFIG_JSON_FILE="${1:?usage: qm-score.sh <config.json> <rubric_key> <bands.json>}"
RUBRIC_KEY="${2:?usage: qm-score.sh <config.json> <rubric_key> <bands.json>}"
BANDS_JSON_FILE="${3:?usage: qm-score.sh <config.json> <rubric_key> <bands.json>}"

if [ ! -f "$CONFIG_JSON_FILE" ]; then
  echo "qm-score: config file not found: $CONFIG_JSON_FILE" >&2
  exit 1
fi
if [ ! -f "$BANDS_JSON_FILE" ]; then
  echo "qm-score: bands file not found: $BANDS_JSON_FILE" >&2
  exit 1
fi

# Validate every rubric dimension has a recognized band assigned before computing anything.
MISSING=$(jq -n --slurpfile cfg "$CONFIG_JSON_FILE" --slurpfile bands "$BANDS_JSON_FILE" --arg rk "$RUBRIC_KEY" '
  ($cfg[0][$rk].dimensions // []) as $dims |
  $bands[0] as $b |
  [$dims[] | select(($b[.name] // null) == null) | .name]
')
if [ "$(echo "$MISSING" | jq 'length')" != "0" ]; then
  echo "qm-score: missing band for dimension(s): $(echo "$MISSING" | jq -r 'join(", ")')" >&2
  exit 1
fi

INVALID=$(jq -n --slurpfile bands "$BANDS_JSON_FILE" '
  ["ABSENT","WEAK","ADEQUATE","STRONG"] as $valid |
  $bands[0] | to_entries | [.[] | select(.value as $v | ($valid | index($v)) == null) | .key]
')
if [ "$(echo "$INVALID" | jq 'length')" != "0" ]; then
  echo "qm-score: invalid band value for dimension(s): $(echo "$INVALID" | jq -r 'join(", ")')" >&2
  exit 1
fi

jq -n --slurpfile cfg "$CONFIG_JSON_FILE" --slurpfile bands "$BANDS_JSON_FILE" --arg rk "$RUBRIC_KEY" '
  ($cfg[0].band_multipliers) as $mult |
  ($cfg[0][$rk].dimensions // []) as $dims |
  $bands[0] as $b |
  ($dims | map(
    . as $d |
    ($b[$d.name]) as $band |
    ($mult[$band]) as $m |
    {
      name: $d.name,
      band: $band,
      weight: $d.weight,
      multiplier: $m,
      score: (($d.weight * $m) | round)
    }
  )) as $scored |
  {
    dimension_scores: $scored,
    overall_score: ([$scored[].score] | add // 0 | if . < 0 then 0 elif . > 100 then 100 else . end)
  }
'
