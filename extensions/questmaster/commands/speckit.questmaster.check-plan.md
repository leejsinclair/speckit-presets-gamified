---
name: "speckit-questmaster-check-plan"
description: "Comprehension Checkpoint + Plan Integrity assessment: plan.md against story.md and spec.md, independently assessed."
argument-hint: "(no arguments needed — assesses the active feature's plan.md against its story.md and spec.md)"
compatibility: "Requires spec-kit project structure with .specify/ directory; installed via the questmaster extension (specify extension add --dev ./extensions/questmaster)"
metadata:
  author: "questmaster contributors"
  source: "extensions/questmaster/commands/speckit.questmaster.check-plan.md"
aliases: ["speckit-quest-check-plan"]
user-invocable: true
disable-model-invocation: false
---


## User Input

```text
$ARGUMENTS
```

This command needs no arguments beyond the active feature context (`.specify/feature.json`).
If `$ARGUMENTS` contains something anyway, read it for extra context but do not require it.

## Purpose

The Comprehension Checkpoint and Plan Integrity assessment (FR-016, FR-017–FR-021, FR-037–FR-041,
contracts/quest-check-plan.md). Invoked automatically by the `after_plan` hook, and independently
re-runnable on demand. Runs the Comprehension Checkpoint **before showing anything else**, then
bands `plan.md` against **both** `story.md` and `spec.md` across 8 dimensions in an **independent
context**, cross-referencing its own findings against the developer's recorded predictions.

**Trigger awareness**: determine whether this invocation is hook-triggered (fired automatically
right after `/speckit-plan` completed) or explicit/manual. This matters for Step 1's silent-exit
behavior.

## Helper scripts (inlined per extensions/questmaster/README.md § Helper script delivery)

<details>
<summary>qm-config.sh — verbatim copy of <code>extensions/questmaster/scripts/qm-config.sh</code> (README.md § Helper script delivery: this copy MUST stay byte-identical to the tested source; if it ever needs to change, change the source first)</summary>

```sh
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
```

</details>

<details>
<summary>qm-record.sh — verbatim copy of <code>extensions/questmaster/scripts/qm-record.sh</code> (README.md § Helper script delivery: this copy MUST stay byte-identical to the tested source; if it ever needs to change, change the source first)</summary>

```sh
#!/bin/sh
# qm-record.sh — Questmaster Record reader/writer (tasks.md T009).
#
# Reads and appends the three subsections of an artifact's `## Questmaster Record` — Judgment
# Ledger (FR-035), Comprehension (FR-041), Decisions (FR-027) — in place in story.md/spec.md/
# plan.md. All parsing/writing is mechanical (regex over a fixed, documented markdown shape);
# no judgment is applied here — the calling command skill decides *what* to record, this script
# only records it reproducibly and reads it back.
#
# Canonical shapes this script writes and reads (data-model.md § Questmaster Record):
#
#   ### Judgment Ledger
#   - **<date>** · <stage> · <kind> — "<developer_words>"
#     *Effect*: <effect>
#
#   ### Comprehension
#   **Round <n> · <date>** — <note>
#
#   - *<label>*: "<answer-or-DECLINED>"
#   - *<label>*: "<answer-or-DECLINED>"
#
#   ### Decisions
#   - **<date>** — <narrative prose, written by the calling command>
#     <!-- qm-record:decision status=<outstanding|resolved> resolved_by=<developer|questmaster|-> resolved_date=<date|-> -->
#     <!-- qm-record:evidence <resolution_evidence, only present when resolved_by=questmaster> -->
#
# The HTML-comment trailers are the machine-readable half of a Decision entry; the visible prose
# above them is what a developer reads (FR-027/FR-039's restated-in-full requirement). Never
# strip these comments when hand-editing a Decision — list-decisions/resolve-decision rely on them.
#
# Usage:
#   qm-record.sh ensure-sections <file>
#   qm-record.sh add-ledger <file> <date> <stage> <kind> <developer_words> <effect>
#   qm-record.sh list-ledger <file>                      # -> JSON array on stdout
#   qm-record.sh add-comprehension-round <file> <round> <date> <note> <questions.json>
#                                                          # questions.json: [{"label":..,"answer":..}]
#   qm-record.sh list-comprehension <file>               # -> JSON array of rounds on stdout
#   qm-record.sh add-decision <file> <date> <narrative> <status> [resolved_by] [resolved_date] [evidence]
#   qm-record.sh list-decisions <file>                   # -> JSON array on stdout
#   qm-record.sh resolve-decision <file> <match> <resolved_by> <resolved_date> <evidence>
#                                                          # finds first outstanding decision whose
#                                                          # narrative contains <match>, marks it resolved

set -eu

CMD="${1:?usage: qm-record.sh <subcommand> ...}"
shift

ensure_sections() {
  file="$1"
  if [ ! -f "$file" ]; then
    echo "qm-record: file not found: $file" >&2
    exit 1
  fi
  if ! grep -q '^## Questmaster Record$' "$file"; then
    {
      echo ""
      echo "## Questmaster Record"
      echo ""
      echo "### Judgment Ledger"
      echo ""
      echo "### Comprehension"
      echo ""
      echo "### Decisions"
    } >> "$file"
  else
    for sub in "### Judgment Ledger" "### Comprehension" "### Decisions"; do
      grep -qF "$sub" "$file" || echo "qm-record: WARNING: $file has a Questmaster Record but is missing '$sub'" >&2
    done
  fi
}

# Append a line/block right after a given subsection heading (before the next heading of level
# <= that heading's level), i.e. at the end of that subsection's existing content.
append_under_heading() {
  file="$1"
  heading="$2"     # exact line to match, e.g. "### Judgment Ledger"
  block_file="$3"  # file containing the lines to append

  python3 - "$file" "$heading" "$block_file" <<'PY'
import sys

file_path, heading, block_path = sys.argv[1], sys.argv[2], sys.argv[3]
with open(file_path) as f:
    lines = f.readlines()
with open(block_path) as f:
    block = f.read()

heading_level = len(heading) - len(heading.lstrip('#'))

start = None
for i, line in enumerate(lines):
    if line.rstrip('\n') == heading:
        start = i
        break
if start is None:
    print(f"qm-record: heading not found: {heading}", file=sys.stderr)
    sys.exit(1)

end = len(lines)
for i in range(start + 1, len(lines)):
    stripped = lines[i].rstrip('\n')
    if stripped.startswith('#'):
        lvl = len(stripped) - len(stripped.lstrip('#'))
        if lvl <= heading_level:
            end = i
            break

# Trim trailing blank lines within the section so we append tightly, then add one blank line
# before the new block for readability.
while end > start + 1 and lines[end - 1].strip() == "":
    end -= 1

insertion = []
if end > start + 1:
    insertion.append("\n")
insertion.append(block if block.endswith("\n") else block + "\n")

new_lines = lines[:end] + insertion + lines[end:]
with open(file_path, "w") as f:
    f.writelines(new_lines)
PY
}

cmd_add_ledger() {
  file="$1"; date="$2"; stage="$3"; kind="$4"; words="$5"; effect="$6"
  ensure_sections "$file"
  tmp=$(mktemp)
  {
    printf -- '- **%s** · %s · %s — "%s"\n' "$date" "$stage" "$kind" "$words"
    printf '  *Effect*: %s\n' "$effect"
  } > "$tmp"
  append_under_heading "$file" "### Judgment Ledger" "$tmp"
  rm -f "$tmp"
}

cmd_list_ledger() {
  file="$1"
  python3 - "$file" <<'PY'
import sys, re, json

path = sys.argv[1]
with open(path) as f:
    text = f.read()

m = re.search(r'^### Judgment Ledger\s*\n(.*?)(?=\n#{1,3} |\Z)', text, re.S | re.M)
body = m.group(1) if m else ""

entries = []
pattern = re.compile(
    r'^- \*\*(?P<date>[^*]+)\*\* · (?P<stage>[^ ]+) · (?P<kind>[^ ]+) — "(?P<words>.*?)"\s*\n'
    r'  \*Effect\*: (?P<effect>.*?)\s*$',
    re.M | re.S
)
for mm in pattern.finditer(body):
    entries.append({
        "date": mm.group("date").strip(),
        "stage": mm.group("stage").strip(),
        "kind": mm.group("kind").strip(),
        "developer_words": mm.group("words"),
        "effect": mm.group("effect"),
    })
print(json.dumps(entries))
PY
}

cmd_add_comprehension_round() {
  file="$1"; round="$2"; date="$3"; note="$4"; questions_json="$5"
  ensure_sections "$file"
  tmp=$(mktemp)
  {
    printf '**Round %s · %s** — %s\n\n' "$round" "$date" "$note"
    jq -r '.[] | "- *\(.label)*: \"\(.answer)\""' "$questions_json"
  } > "$tmp"
  append_under_heading "$file" "### Comprehension" "$tmp"
  rm -f "$tmp"
}

cmd_list_comprehension() {
  file="$1"
  python3 - "$file" <<'PY'
import sys, re, json

path = sys.argv[1]
with open(path) as f:
    text = f.read()

m = re.search(r'^### Comprehension\s*\n(.*?)(?=\n#{1,3} |\Z)', text, re.S | re.M)
body = m.group(1) if m else ""

rounds = []
round_pattern = re.compile(r'^\*\*Round (?P<round>\d+) · (?P<date>[^*]+)\*\* — (?P<note>.*)$', re.M)
matches = list(round_pattern.finditer(body))
for idx, mm in enumerate(matches):
    section_end = matches[idx + 1].start() if idx + 1 < len(matches) else len(body)
    section = body[mm.end():section_end]
    questions = []
    for qm in re.finditer(r'^- \*(?P<label>[^*]+)\*: "(?P<answer>.*?)"\s*$', section, re.M):
        answer = qm.group("answer")
        questions.append({
            "label": qm.group("label"),
            "answer": answer,
            "outcome": "declined" if answer == "DECLINED" else "answered",
        })
    rounds.append({
        "round": int(mm.group("round")),
        "date": mm.group("date").strip(),
        "note": mm.group("note").strip(),
        "questions": questions,
        "outcome": "declined" if questions and all(q["outcome"] == "declined" for q in questions) else "answered",
    })
print(json.dumps(rounds))
PY
}

cmd_used_comprehension_labels() {
  file="$1"
  sh "$0" list-comprehension "$file" | jq '[.[].questions[].label]'
}

cmd_add_decision() {
  file="$1"; date="$2"; narrative="$3"; status="$4"
  resolved_by="${5:--}"; resolved_date="${6:--}"; evidence="${7:-}"
  ensure_sections "$file"
  tmp=$(mktemp)
  {
    printf -- '- **%s** — %s\n' "$date" "$narrative"
    printf '  <!-- qm-record:decision status=%s resolved_by=%s resolved_date=%s -->\n' \
      "$status" "$resolved_by" "$resolved_date"
    if [ "$resolved_by" = "questmaster" ] && [ -n "$evidence" ]; then
      printf '  <!-- qm-record:evidence %s -->\n' "$evidence"
    fi
  } > "$tmp"
  append_under_heading "$file" "### Decisions" "$tmp"
  rm -f "$tmp"
}

cmd_list_decisions() {
  file="$1"
  python3 - "$file" <<'PY'
import sys, re, json

path = sys.argv[1]
with open(path) as f:
    text = f.read()

m = re.search(r'^### Decisions\s*\n(.*?)(?=\n#{1,3} |\Z)', text, re.S | re.M)
body = m.group(1) if m else ""

entries = []
entry_pattern = re.compile(
    r'^- \*\*(?P<date>[^*]+)\*\* — (?P<narrative>.*?)\n'
    r'  <!-- qm-record:decision status=(?P<status>\S+) resolved_by=(?P<resolved_by>\S+) resolved_date=(?P<resolved_date>\S+) -->\n'
    r'(?:  <!-- qm-record:evidence (?P<evidence>.*?) -->\n)?',
    re.M | re.S
)
for mm in entry_pattern.finditer(body):
    entries.append({
        "date": mm.group("date").strip(),
        "narrative": mm.group("narrative").strip(),
        "status": mm.group("status"),
        "resolved_by": None if mm.group("resolved_by") == "-" else mm.group("resolved_by"),
        "resolved_date": None if mm.group("resolved_date") == "-" else mm.group("resolved_date"),
        "resolution_evidence": mm.group("evidence"),
    })
print(json.dumps(entries))
PY
}

cmd_resolve_decision() {
  file="$1"; match="$2"; resolved_by="$3"; resolved_date="$4"; evidence="$5"
  # FR-039: an auto-resolution (resolved_by=questmaster) MUST NOT be recorded without cited
  # evidence — absence of an objection is never evidence. Refuse rather than silently record.
  if [ "$resolved_by" = "questmaster" ] && [ -z "$evidence" ]; then
    echo "qm-record: refusing to auto-resolve — resolved_by=questmaster requires non-empty resolution_evidence (FR-039)" >&2
    exit 1
  fi
  python3 - "$file" "$match" "$resolved_by" "$resolved_date" "$evidence" <<'PY'
import sys, re

path, match, resolved_by, resolved_date, evidence = sys.argv[1:6]
with open(path) as f:
    text = f.read()

pattern = re.compile(
    r'(^- \*\*[^*]+\*\* — (?P<narrative>.*?)\n'
    r'  <!-- qm-record:decision status=)(?P<status>outstanding)( resolved_by=)\S+( resolved_date=)\S+( -->\n)',
    re.M | re.S
)

replaced = {"done": False}

def repl(m):
    if replaced["done"] or match not in m.group("narrative"):
        return m.group(0)
    replaced["done"] = True
    new = (
        m.group(1) + "resolved" + m.group(4) + resolved_by + m.group(5) + resolved_date + m.group(6)
    )
    if resolved_by == "questmaster" and evidence:
        new += f"  <!-- qm-record:evidence {evidence} -->\n"
    return new

new_text = pattern.sub(repl, text, count=0)
if not replaced["done"]:
    print(f"qm-record: no outstanding decision found matching: {match}", file=sys.stderr)
    sys.exit(1)

with open(path, "w") as f:
    f.write(new_text)
PY
}

case "$CMD" in
  ensure-sections) ensure_sections "$@" ;;
  add-ledger) cmd_add_ledger "$@" ;;
  list-ledger) cmd_list_ledger "$@" ;;
  add-comprehension-round) cmd_add_comprehension_round "$@" ;;
  list-comprehension) cmd_list_comprehension "$@" ;;
  used-comprehension-labels) cmd_used_comprehension_labels "$@" ;;
  add-decision) cmd_add_decision "$@" ;;
  list-decisions) cmd_list_decisions "$@" ;;
  resolve-decision) cmd_resolve_decision "$@" ;;
  *)
    echo "qm-record: unknown subcommand: $CMD" >&2
    exit 1
    ;;
esac
```

</details>

<details>
<summary>qm-digest.sh — verbatim copy of <code>extensions/questmaster/scripts/qm-digest.sh</code> (README.md § Helper script delivery: this copy MUST stay byte-identical to the tested source; if it ever needs to change, change the source first)</summary>

```sh
#!/bin/sh
# qm-digest.sh — source-digest helper (tasks.md T008).
#
# sha256 over an artifact's content with its `## Questmaster Record` section removed — from that
# heading up to the next same-level (`## `) heading or end of file — normalized only by stripping
# a trailing newline (FR-040, data-model.md § Source digest scope). Excluded content is still
# READ by every assessment; it is simply not part of what "this artifact changed" means, since
# Questmaster writes the Questmaster Record into the very artifacts it digests (FR-027) and a
# whole-file digest would report staleness on Questmaster's own bookkeeping.
#
# Usage:
#   qm-digest.sh <file>
#
# Output (stdout): "sha256:<hex>"
# An artifact with no "## Questmaster Record" section digests identically before and after one is
# appended is NOT guaranteed by this alone — appending the section changes file content, which is
# exactly why the section is stripped before hashing rather than merely excluded from a diff.

set -eu

FILE="${1:?usage: qm-digest.sh <file>}"

if [ ! -f "$FILE" ]; then
  echo "qm-digest: file not found: $FILE" >&2
  exit 1
fi

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    echo "qm-digest: no sha256sum or shasum available" >&2
    return 1
  fi
}

STRIPPED=$(awk '
  BEGIN { skip = 0 }
  {
    if (skip) {
      if ($0 ~ /^## ([^#].*)?$/) {
        skip = 0
      } else {
        next
      }
    }
    if ($0 ~ /^## Questmaster Record[ \t]*$/) {
      skip = 1
      next
    }
    print
  }
' "$FILE")

HASH=$(printf '%s' "$STRIPPED" | sha256)
echo "sha256:$HASH"
```

</details>

<details>
<summary>qm-score.sh — verbatim copy of <code>extensions/questmaster/scripts/qm-score.sh</code> (README.md § Helper script delivery: this copy MUST stay byte-identical to the tested source; if it ever needs to change, change the source first)</summary>

```sh
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
```

</details>

<details>
<summary>qm-report.sh — verbatim copy of <code>extensions/questmaster/scripts/qm-report.sh</code> (README.md § Helper script delivery: this copy MUST stay byte-identical to the tested source; if it ever needs to change, change the source first)</summary>

```sh
#!/bin/sh
# qm-report.sh — decision-first Integrity report renderer (FR-038, data-model.md § Integrity
# Assessment Report, tasks.md T010/T026's presentational contract).
#
# Takes ONE JSON "report spec" (judgment content: bands, drift classifications, findings — all
# supplied by the calling command, which is where that judgment belongs) and renders it into the
# exact normative section order, deterministically: header -> Decisions for you (>=3 capped, with
# remainder counted+named, or "No decision required.") -> Outstanding accepted risk -> Integrity
# (banded summary) -> Drift Classification summary (aggregate counts) -> Findings -> Appendix
# (full per-element table) -> Advisory note. This script owns ORDERING, CAPPING, and
# AGGREGATION — never the judgment calls (which band, which classification) that fill the JSON.
#
# Usage:
#   qm-report.sh <report-spec.json>
#
# Report spec schema (all judgment-derived fields; see the schema literal at the top of the
# embedded Python for the authoritative field list):
#   {
#     "artifact_type": "Specification"|"Plan", "assessed_date": "...", "against": "...",
#     "context": "INDEPENDENT"|"SELF-ASSESSED",
#     "digests": [{"artifact":..., "digest":...}], "digest_mismatch_notes": [...],
#     "decisions": [{"summary":..., "question":..., "classification":..., "severity":...,
#                     "finding_ref": <int, matches a findings[].id>}],
#     "outstanding_risk": [{"accepted_date":..., "stage":..., "score":.., "unmet_summary":...,
#                            "reason":..., "note":...}],
#     "dimension_bands": [{"name":..., "band":..., "score":.., "weight":.., "evidence":...}],
#     "drift_counts": {"PRESERVED":.., "REFINED":.., "CLARIFIED":.., "DISCOVERED":..,
#                       "ACCEPTED_SCOPE_CHANGE":.., "UNJUSTIFIED_DRIFT":..},
#     "findings": [{"id":.., "short_name":..., "source_artifact":..., "destination_artifact":...,
#                    "original_intent":..., "new_behaviour":..., "classification":...,
#                    "severity":..., "evidence":..., "question":...}],
#     "appendix": [{"element":..., "classification":..., "notes":...}],
#     "comprehension_cross_reference": "..."   (optional, Plan Integrity only),
#     "advisory_note": "..."   (optional; a documented default is used if absent)
#   }
#
# Output (stdout): the rendered Markdown report, ready to write verbatim to spec-integrity.md /
# plan-integrity.md and to present in the response (FR-038 requires both to match).

set -eu

SPEC_FILE="${1:?usage: qm-report.sh <report-spec.json>}"
if [ ! -f "$SPEC_FILE" ]; then
  echo "qm-report: report spec not found: $SPEC_FILE" >&2
  exit 1
fi

python3 - "$SPEC_FILE" <<'PY'
import sys, json

with open(sys.argv[1]) as f:
    spec = json.load(f)

def g(key, default):
    return spec.get(key, default)

lines = []
add = lines.append

artifact_type = g("artifact_type", "Specification")
add(f"# {artifact_type} Integrity Assessment")
add("")
add(f"**Assessed**: {g('assessed_date', '')} · **Against**: {g('against', '')}")
add(f"**Assessment context**: {g('context', 'SELF-ASSESSED')}")
digests = g("digests", [])
digest_str = ", ".join(f"{d['artifact']} `{d['digest']}`" for d in digests)
add(f"**Source digests**: {digest_str}")
for note in g("digest_mismatch_notes", []):
    add(f"> {note}")
add("")

# --- Decisions for you (cap 3, count+name remainder, or "No decision required.") ---
decisions = g("decisions", [])
add(f"## Decisions for you ({min(len(decisions), 3)})")
add("")
if not decisions:
    add("No decision required.")
else:
    shown = decisions[:3]
    remainder = decisions[3:]
    for idx, d in enumerate(shown, start=1):
        ref = d.get("finding_ref")
        finding_note = f" · see Finding {ref}" if ref is not None else ""
        add(
            f"{idx}. **{d.get('summary','')}** → *{d.get('question','')}* "
            f"`{d.get('classification','')}` · {d.get('severity','')}{finding_note}"
        )
    if remainder:
        names = ", ".join(str(r.get("element_id", r.get("summary", "?"))) for r in remainder)
        add("")
        add(f"{len(shown)} shown; {len(remainder)} further items require a decision ({names}) — see the full table below.")
add("")

# --- Outstanding accepted risk ---
risks = g("outstanding_risk", [])
add(f"## Outstanding accepted risk ({len(risks)})")
add("")
if not risks:
    add("No outstanding accepted risk.")
else:
    for r in risks:
        add(
            f"- **Accepted {r.get('accepted_date','')}, {r.get('stage','')} stage** — "
            f"proceeded at {r.get('score','?')}/100 with {r.get('unmet_summary','')}. "
            f"Developer's reason: *\"{r.get('reason','')}\"*. {r.get('note','Still unresolved.')}"
        )
add("")

# --- Integrity (banded dimension summary) ---
add("## Integrity")
add("")
bands = g("dimension_bands", [])
overall = sum(b.get("score", 0) for b in bands)
inline = " · ".join(f"{b['name']} **{b['band']}** {b['score']}/{b['weight']}" for b in bands)
add(f"{inline} → **{overall}/100**")
add("")
add("| Dimension | Band | Score | Evidence |")
add("|---|---|---|---|")
for b in bands:
    add(f"| {b['name']} | {b['band']} | {b['score']}/{b['weight']} | {b.get('evidence','')} |")
add("")

# --- Drift Classification summary (aggregate PRESERVED/REFINED/CLARIFIED; full table in appendix) ---
counts = g("drift_counts", {})
total = sum(counts.values())
order = ["PRESERVED", "REFINED", "CLARIFIED", "DISCOVERED", "ACCEPTED_SCOPE_CHANGE", "UNJUSTIFIED_DRIFT"]
count_str = ", ".join(f"**{counts.get(k,0)} {k}**" for k in order if counts.get(k, 0) or k in ("PRESERVED","REFINED","CLARIFIED"))
add("## Drift Classification summary")
add("")
add(f"{total} elements compared: {count_str}.")
add("Per-element table: appendix below.")
if g("comprehension_cross_reference", None):
    add("")
    add(g("comprehension_cross_reference", ""))
add("")

# --- Findings ---
for finding in g("findings", []):
    add(f"### Finding {finding['id']}: {finding.get('short_name','')}")
    add(f"- **Source artifact**: {finding.get('source_artifact','')}")
    add(f"- **Destination artifact**: {finding.get('destination_artifact','')}")
    add(f"- **Original intent**: {finding.get('original_intent','')}")
    add(f"- **New behaviour**: {finding.get('new_behaviour','')}")
    add(f"- **Classification**: {finding.get('classification','')} · **Severity**: {finding.get('severity','')}")
    add(f"- **Evidence**: {finding.get('evidence','')}")
    add(f"- **Question for the developer**: {finding.get('question','')}")
    add("")

# --- Appendix: full per-element classification ---
add("## Appendix — full per-element classification")
add("")
add("| Element | Classification | Notes |")
add("|---|---|---|")
for row in g("appendix", []):
    add(f"| {row.get('element','')} | {row.get('classification','')} | {row.get('notes','')} |")
add("")

# --- Advisory note ---
add("## Advisory note")
add("")
add(g("advisory_note", "This assessment does not block, modify, or reject the artifact (FR-022). All findings require developer judgment."))

print("\n".join(lines))
PY
```

</details>

<details>
<summary>qm-worklist.sh — verbatim copy of <code>extensions/questmaster/scripts/qm-worklist.sh</code> (README.md § Helper script delivery: this copy MUST stay byte-identical to the tested source; if it ever needs to change, change the source first)</summary>

```sh
#!/bin/sh
# qm-worklist.sh — Decision Worklist top-item selector (FR-043, tasks.md T058/T059).
#
# A thin, deterministic wrapper so "elicit a response only when the worklist is non-empty, and
# never invent a subject when it's empty" is a checkable file-in/file-out fact, not something
# left to be reasoned about correctly every time. Takes the SAME `decisions` array shape
# qm-report.sh's report spec uses (already ordered highest severity first by the caller) and
# reports whether Step 8 (check-spec) / the equivalent Plan Integrity step applies, and to what.
#
# Usage:
#   qm-worklist.sh <decisions.json>
#
# Output (stdout): {"required": true|false, "top": <first element>|null}

set -eu

DECISIONS_FILE="${1:?usage: qm-worklist.sh <decisions.json>}"
if [ ! -f "$DECISIONS_FILE" ]; then
  echo "qm-worklist: file not found: $DECISIONS_FILE" >&2
  exit 1
fi

jq -n --slurpfile d "$DECISIONS_FILE" '
  ($d[0] // []) as $decisions |
  {
    required: ($decisions | length) > 0,
    top: ($decisions[0] // null)
  }
'
```

</details>


## Outline

### Step 1 — Resolve the active feature directory (FR-025, FR-026)

If it has **no `story.md`**:
- **Hook-triggered invocation**: exit immediately. Write nothing, print nothing.
- **Explicit/manual invocation**: state plainly that the assessment could not be performed, and
  explain that running `/speckit-questmaster-story` first will produce the `story.md` this
  assessment needs.

### Step 2 — Require both story.md and spec.md

Require `story.md` and `spec.md` to exist in the feature directory alongside `plan.md` (they
always will when hook-triggered, since `/speckit-questmaster-check-spec` already ran after
`/speckit-specify`).

### Step 3 — Comprehension Checkpoint, before anything else is shown (FR-041, Constitution XV)

**This step is direct developer interaction and is explicitly NOT subject to the independence
requirement in Step 5.**

Read what's already recorded:

```sh
sh qm-record.sh list-comprehension <feature-dir>/plan.md
```

- **No round recorded yet** (empty array — first checkpoint for this plan): ask **exactly
  three** questions, in this order: *"Which part of this plan is most likely to be wrong?"*,
  *"What would you cut if you had to cut one thing?"*, *"What breaks first — under load, failure,
  or a change of requirements?"*
- **One or more rounds already recorded** (a re-run): **restate** the previously recorded
  answers (do not re-ask them), then check which labels are already used:
  ```sh
  sh qm-record.sh used-comprehension-labels <feature-dir>/plan.md
  ```
  Ask **exactly one** further question whose label is **not** in that list, drawn from the
  non-derivable-question family (data-model.md § Comprehension Checkpoint — e.g. what would have
  to be true for this plan to be the wrong shape entirely; which part would be hardest to reverse
  once built; what a reviewer unfamiliar with the feature would misread first). **If every
  genuinely non-derivable question you can think of is already used, say so explicitly and ask
  nothing this round** — do not pad with a question the plan already answers.

Record whatever was asked as a new round:

```sh
sh qm-record.sh add-comprehension-round <feature-dir>/plan.md <round-number> <today> "<one-line context>" <questions.json>
```

`<questions.json>` is `[{"label":..., "answer":...}]` — `answer` is the developer's verbatim
text, or the literal string `"DECLINED"` if they decline (permitted; record the decline as a
decline, never as an absence — never leave a question out of the JSON array to represent a
decline). Also add each answered (non-declined) question as a Judgment Ledger entry:

```sh
sh qm-record.sh add-ledger <feature-dir>/plan.md <today> comprehension comprehension_answer "<verbatim answer>" "Recorded as a Round <n> comprehension prediction."
```

**Never answer on the developer's behalf, and never block** on this step — proceed to Step 4
regardless of how many questions were answered vs. declined.

### Step 4 — Compute digests and outstanding risk (FR-039, FR-040)

```sh
sh qm-digest.sh <feature-dir>/story.md
sh qm-digest.sh <feature-dir>/spec.md
sh qm-digest.sh <feature-dir>/plan.md
```

Note: because the Questmaster Record is excluded from what these digests cover, Step 3's own
writes (just above) never make `plan.md` appear to have "changed" for staleness purposes — this
is precisely why FR-040 excludes that section.

Read both `story.md`'s and `spec.md`'s Questmaster Records for outstanding accepted risk:

```sh
sh qm-record.sh list-decisions <feature-dir>/story.md
sh qm-record.sh list-decisions <feature-dir>/spec.md
```

Apply the same still-holds / auto-resolve judgment as `/speckit-questmaster-check-spec` Step 5 —
carried out as part of Step 5's independent assessment below, not from this authoring context.
Auto-resolution (if warranted) uses the same `qm-record.sh resolve-decision` call with cited
evidence, attributed to `questmaster`, never a Judgment Ledger entry.

### Step 5 — Independent assessment (FR-037)

**This step, and only this step (Step 3 is explicitly exempt), MUST run with no access to
whatever conversation authored `plan.md`.** Invoke Claude Code's **Agent tool** (a fresh,
independent agent, not a `fork`) with a prompt containing **only**:
- the full content of `story.md`, `spec.md`, and `plan.md`,
- the resolved `plan_integrity_rubric` (from `qm-config.sh`) with its 8 dimensions and anchors,
- both artifacts' Decisions subsections (for Step 4's still-holds/auto-resolve judgment), and
- this plan's full recorded Comprehension history (all rounds, from Step 3),

asking it to:
1. Band all 8 dimensions (`intent_preservation`, `specification_coverage`,
   `constraint_preservation`, `proportionality`, `legibility`, `risk_management`, `test_strategy`,
   `traceability`) against **both** `story.md` and `spec.md`, each with cited evidence (FR-036).
   - `intent_preservation` MUST be banded independently of technical/architectural quality — a
     technically sound plan that abandons the story's desired outcome or constraints must NOT
     band well overall.
   - `legibility` MUST be banded independently of technical correctness — could a developer who
     did not author the plan follow it (decisions explained, terms defined, order of work
     stated)?
   - `constraint_preservation` is distinct from `specification_coverage`: flag a story-level
     constraint dropped during technical design even where `spec.md` itself carried it forward.
2. For every component, service, or abstraction in `plan.md`, assign exactly one Drift
   Classification against `story.md`/`spec.md` (FR-017), consulting BOTH artifacts' Decisions
   before ever using `ACCEPTED_SCOPE_CHANGE` (FR-019).
3. **Never** flag or recommend simplifying an element solely for being complex (FR-021): a
   complex element traceable to a stated requirement, constraint, or risk bands under
   `proportionality` as `PRESERVED`/`REFINED`, not drift.
4. For every `DISCOVERED`/`ACCEPTED_SCOPE_CHANGE`/`UNJUSTIFIED_DRIFT` element, produce a full
   finding (FR-018).
5. Judge Step 4's outstanding-risk still-holds/no-longer-holds question, citing specific evidence
   for any "no longer holds" verdict.
6. State explicitly where its own findings **agree or disagree** with the developer's recorded
   Comprehension predictions from **every** round, not only this run's (e.g. "you predicted the
   retry path was most likely to be wrong; this assessment instead found the dropped retention
   constraint more significant").

Ask for the result as structured JSON matching `qm-report.sh`'s report-spec schema
(`dimension_bands`, `drift_counts`, `findings`, `appendix`, `comprehension_cross_reference`) plus
the outstanding-risk verdicts.

**Determine the assessment context label**: `INDEPENDENT` if the Agent tool was actually used;
`SELF-ASSESSED` — not suppressible by configuration — if no such mechanism was available and the
assessment ran inline instead.

### Step 6 — Assemble and write the report (FR-022, FR-031, FR-038)

Build a report-spec JSON (`artifact_type: "Plan"`, `against: "story.md, spec.md"`) from Step 5's
output plus Step 4's digests and outstanding-risk data, then render it:

```sh
sh qm-report.sh <report-spec.json>
```

Write the result to `<feature-dir>/plan-integrity.md` (overwriting any previous version), and
present the same content, in the same order, in your response — **after** Step 3's Comprehension
Checkpoint content, which always comes first in the actual response even though it isn't part of
this report-spec schema. Never auto-modify, block, or reject `plan.md`, and never block
`/speckit-tasks` on any finding here.

### Step 7 — Elicit a response to the top decision, if any (consistency with FR-043's pattern)

Same mechanism as `/speckit-questmaster-check-spec` Step 8:

```sh
sh qm-worklist.sh <decisions.json>
```

If `.required` is `false`, skip entirely. Otherwise put the top item to the developer (resolve /
accept with a typed justification / defer), record the outcome as a Judgment Ledger entry on
`plan.md`, and — for an acceptance — as a Decision. Never block on the answer.

## Output

- `<feature-dir>/plan-integrity.md` (written only when `story.md` exists)
- `plan.md`'s Questmaster Record updated with this round's Comprehension answers and Judgment
  Ledger entries (Step 3), independent of whether the rest of the assessment can complete
- Response, in order: Comprehension Checkpoint for this round, Decision Worklist, Outstanding
  Accepted Risk (including any auto-resolved this run), dimension bands + evidence (with
  Comprehension cross-reference), Drift Classification summary, full findings, advisory note

## Postconditions

None enforced. Any override recorded here is carried forward by any future downstream stage
(FR-039) — none exists in this release, so the carry-forward chain currently ends at Plan
Integrity.

## Done When

- [ ] Comprehension Checkpoint ran and was shown BEFORE any assessment content, with the correct
      question count for round 1 vs. a re-run, and any decline recorded as a decline
- [ ] Digests computed for all three artifacts; outstanding risk from both `story.md` and
      `spec.md` restated or auto-resolved with evidence
- [ ] All 8 dimensions banded against both `story.md` and `spec.md` via an independent Agent tool
      invocation (or explicitly labelled SELF-ASSESSED), with `intent_preservation` and
      `legibility` banded independently as required
- [ ] Every component/service/abstraction given exactly one Drift Classification; no element
      flagged solely for complexity traceable to a stated requirement/constraint/risk
- [ ] The report states where its findings agree/disagree with every recorded Comprehension round
- [ ] `plan-integrity.md` written in the normative decision-first order; the same content
      presented in the response, after the Comprehension Checkpoint
- [ ] The top Decision Worklist item (if any) was put to the developer without blocking
      `/speckit-tasks`
