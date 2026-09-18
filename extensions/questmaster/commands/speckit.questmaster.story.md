---
name: "speckit-questmaster-story"
description: "Storyteller: Socratic interview + Dragon Pass, produces story.md with a banded Story Integrity Assessment and readiness classification."
argument-hint: "Describe the feature or problem you want to frame as a quest"
compatibility: "Requires spec-kit project structure with .specify/ directory; installed via the questmaster extension (specify extension add --dev ./extensions/questmaster)"
metadata:
  author: "questmaster contributors"
  source: "extensions/questmaster/commands/speckit.questmaster.story.md"
aliases: ["speckit-quest-story"]
user-invocable: true
disable-model-invocation: false
---


## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). The text the user typed
after `/speckit-questmaster-story` **is** the feature/problem description — assume you always
have it available even if `$ARGUMENTS` appears literally below. If it is genuinely empty, ask the
developer what they want to frame as a quest before doing anything else.

## Purpose

The Storyteller stage (FR-001–FR-014, FR-029, FR-033–FR-036, contracts/quest-story.md). Runs
Socratic-interviews the developer, sizes the quest, raises a Dragon Pass, and produces a banded,
readiness-classified `story.md` — **before** any other Spec Kit feature artifact exists for this
request. No feature directory, branch, or `.specify/feature.json` write is required or performed
by this command (FR-029): the pending-story mechanism defers directory allocation entirely to the
next `/speckit-specify` run.

## Helper scripts (inlined per extensions/questmaster/README.md § Helper script delivery)

`ExtensionManager`'s `provides:` schema has no `scripts` entry (research.md §12), so these
deterministic helpers are inlined here rather than declared as an installed artifact. Before the
step that needs one, write its content below to a temp file exactly as shown, `chmod +x` it, and
invoke it as instructed — never re-derive the arithmetic, classification, or record format by
reasoning about it directly; that is precisely what these scripts exist to make reproducible
(Constitution VI, plan.md Technical Context).

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
<summary>qm-pending.sh — verbatim copy of <code>extensions/questmaster/scripts/qm-pending.sh</code> (README.md § Helper script delivery: this copy MUST stay byte-identical to the tested source; if it ever needs to change, change the source first)</summary>

```sh
#!/bin/sh
# qm-pending.sh — pending-story file mechanics (data-model.md § Pending Story, FR-029).
#
# Pure file operations backing the pending-story write/relocate/discard cycle used by
# /speckit-questmaster-story (commands/speckit.questmaster.story.md) and
# /speckit-questmaster-check-spec (commands/speckit.questmaster.check-spec.md). At most one
# pending story exists at a time, at a single fixed path — enforced here by REFUSAL, never by
# overwrite: `write` fails closed if one already exists, so a second unrelated interview can never
# silently clobber (or, worse, merge into) a completed one.
#
# Usage:
#   qm-pending.sh path <project-root>                       # prints the canonical path
#   qm-pending.sh exists <project-root>                      # exit 0 if a pending story exists
#   qm-pending.sh title <project-root>                       # prints its "Quest Title" section content
#   qm-pending.sh write <project-root> <content-file>        # writes iff none exists; exit 2 = collision
#   qm-pending.sh relocate <project-root> <feature-dir>      # moves it to <feature-dir>/story.md
#   qm-pending.sh discard <project-root>                     # removes it; exit 1 if none exists

set -eu

CMD="${1:?usage: qm-pending.sh <path|exists|title|write|relocate|discard> <project-root> [...]}"
PROJECT_ROOT="${2:?project-root required}"
shift 2 || true

PENDING_PATH="$PROJECT_ROOT/.specify/extensions/questmaster/pending-story.md"

cmd_path() {
  echo "$PENDING_PATH"
}

cmd_exists() {
  [ -f "$PENDING_PATH" ]
}

cmd_title() {
  if [ ! -f "$PENDING_PATH" ]; then
    echo "qm-pending: no pending story at $PENDING_PATH" >&2
    exit 1
  fi
  python3 - "$PENDING_PATH" <<'PY'
import sys, re
with open(sys.argv[1]) as f:
    text = f.read()
m = re.search(r'^##\s*(?:\d+\.\s*)?Quest Title\s*\n+(.*?)(?=\n#{1,2} |\Z)', text, re.S | re.M)
print(m.group(1).strip() if m else "(untitled)")
PY
}

cmd_write() {
  content_file="${1:?content-file required}"
  if [ -f "$PENDING_PATH" ]; then
    echo "qm-pending: REFUSED — an unclaimed pending story already exists at $PENDING_PATH" >&2
    exit 2
  fi
  mkdir -p "$(dirname "$PENDING_PATH")"
  cp "$content_file" "$PENDING_PATH"
}

cmd_relocate() {
  feature_dir="${1:?feature-dir required}"
  if [ ! -f "$PENDING_PATH" ]; then
    echo "qm-pending: no pending story to relocate at $PENDING_PATH" >&2
    exit 1
  fi
  mkdir -p "$feature_dir"
  target="$feature_dir/story.md"
  if [ -f "$target" ]; then
    echo "qm-pending: refusing to relocate — $target already exists" >&2
    exit 3
  fi
  mv "$PENDING_PATH" "$target"
  echo "$target"
}

cmd_discard() {
  if [ ! -f "$PENDING_PATH" ]; then
    echo "qm-pending: no pending story to discard at $PENDING_PATH" >&2
    exit 1
  fi
  rm -f "$PENDING_PATH"
}

case "$CMD" in
  path) cmd_path "$@" ;;
  exists) cmd_exists "$@" ;;
  title) cmd_title "$@" ;;
  write) cmd_write "$@" ;;
  relocate) cmd_relocate "$@" ;;
  discard) cmd_discard "$@" ;;
  *)
    echo "qm-pending: unknown subcommand: $CMD" >&2
    exit 1
    ;;
esac
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
<summary>qm-readiness.sh — verbatim copy of <code>extensions/questmaster/scripts/qm-readiness.sh</code> (README.md § Helper script delivery: this copy MUST stay byte-identical to the tested source; if it ever needs to change, change the source first)</summary>

```sh
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


## Outline

### Step 1 — Resolve state (contracts/quest-story.md Behavior 1)

1. Determine the active feature directory, if any, from `.specify/feature.json`.
2. **If that feature directory already contains a `story.md`**: this is a **revision**.
   - Warn the developer that any existing `spec-integrity.md`/`plan-integrity.md` may now be
     stale (this will be confirmed later by digest mismatch, FR-040 — do not compute a digest
     here, just state the possibility).
   - Load the existing `story.md`, including its existing `## Questmaster Record`, as the
     starting point for the interview. **Never reset or discard the existing Questmaster
     Record** — new Judgment Ledger entries, Comprehension entries, and Decisions are appended
     to it, never replacing what's there.
3. **Else if `.specify/extensions/questmaster/pending-story.md` exists** (check with
   `qm-pending.sh exists <project-root>`): an **unclaimed pending story** — do **not** start a
   new interview and do **not** touch that file yet.
   - Read its Quest Title with `qm-pending.sh title <project-root>` and its file modification
     date, and state to the developer: *"A pending story already exists ('<title>', written
     <date>). What would you like to do?"*
   - Offer exactly three choices, and require an **explicit** answer before proceeding:
     - **revise it** — continue this interview against that story (go to Step 2, loading the
       pending story as the starting point, preserving its Questmaster Record);
     - **consume it** — stop here; tell the developer to run `/speckit-specify`, which will pick
       up the pending story as its primary input;
     - **discard it** — only on an explicit instruction (e.g. "discard it", "throw it away",
       "start fresh"), run `qm-pending.sh discard <project-root>` and then begin a brand-new
       interview for the current request (go to Step 2 with no prior story content).
   - **Silence, an ambiguous reply ("whatever's easiest", "sure"), or a request that simply looks
     different from the pending story MUST NOT be read as a discard.** Re-ask the choice rather
     than guessing. Never merge the new request into the existing pending story's content.
4. **Else**: this is a brand-new story with no feature directory yet. Do **not** allocate one, a
   branch, or a number of any kind — proceed straight to Step 2.

### Step 2 — Size the quest (FR-033)

From the request's apparent scope, choose:
- **Short Quest**: core sections only (extended sections only where the developer's own answers
  make one materially relevant); target **~6 questions, under 5 minutes**.
- **Full Quest**: all sections; target **~12 questions, under 15 minutes**.

These budgets cover the **whole** developer-facing stage, **including Step 6's Dragon Pass
challenges** — the Dragon Pass is never "extra" time on top. State the chosen path and a one-line
reason before asking the first question. The developer may override the choice at any point; you
(the Storyteller) may escalate Short → Full mid-interview, stating why (e.g. an answer reveals
materially larger scope than assumed). These are design budgets, not hard cutoffs — never
truncate a genuinely productive exchange just to hit the number.

### Step 3 — Interview (FR-001, FR-002, data-model.md § Quest Story Structure)

Cover the 9 core sections always (Quest Title, Problem Statement, Who Is Affected/Actors, Current
Behaviour, Use Cases, Desired Outcomes, Scope Boundaries, Success Criteria, Assumptions & Known
Unknowns — see `templates/story-template.md` for the per-section "complete when" bar and example
Storyteller questions). Cover the 4 extended sections (Background/Context, Business Rules,
Constraints, Proposed Solutions & Solution-Neutrality Assessment) on a Full Quest, or on a Short
Quest only where the developer's own answers make one materially relevant — otherwise it will be
marked N/A with a one-line reason in Step 7, never silently omitted.

Keep **Problem / Need / Outcome / Requirement / Solution** distinct throughout (FR-004): a
proposed implementation is never evidence that the underlying problem is understood. If the
developer names a solution, record it (for Step 5) and keep probing for the underlying problem
rather than adopting the proposal as the story's requirement.

**Stop once there is sufficient evidence to produce a useful story (FR-002) — not at a fixed
question count.** A Short Quest stopping at 4 questions because the answers were unusually clear
is correct; a Full Quest that needs 15 because the domain is genuinely complex is also correct.

### Step 4 — Surface contradictions

If two answers conflict, **ask for clarification rather than silently picking one**. Record the
resolution as a Judgment Ledger entry (`kind: correction` if it corrects something already said,
`kind: asserted_fact` if it resolves genuine ambiguity by stating a new fact) — use
`qm-record.sh add-ledger` (see Step 8 for the full ledger-writing convention; do this inline as
contradictions arise, don't wait until scoring).

### Step 5 — Solution-Neutrality Assessment (FR-005)

If a proposed solution was supplied at any point in the interview, classify **every part of it**
into exactly one of: genuine requirement, proposed implementation detail, assumption, or
unnecessary constraint. Write this as story-template.md §13's structured breakdown. If the
developer resists separating problem from solution (e.g. insists "just build the table"), record
the proposal anyway, note in §13 that neutrality could not be fully assessed and *why*, and
**continue — never block** on this.

If no solution was supplied, write "None supplied" in §13 rather than leaving it blank.

### Step 6 — Dragon Pass (FR-034, data-model.md § Dragon's Questions)

Before scoring, raise:
- **2–3 challenges** on a Short Quest, **3–5** on a Full Quest — counted **inside** Step 2's
  interview budget, never added to it.

Each challenge MUST be **specific to this story's own content** (cite the section or claim it
challenges), not generic risk boilerplate, and MUST be tagged with exactly one category:
`failure`, `unsafe_assumption`, `unexpected_input`, `dependency_failure`, `partial_failure`,
`migration`, or `changing_requirements`.

Record the developer's response to **each** challenge **verbatim**, including an explicit
dismissal, as:
1. A §14 Dragon's Questions entry with `{challenge, category, response, disposition}` —
   `disposition` is exactly one of `answered`, `accepted_as_risk`, `dismissed`,
   `changed_the_story`.
2. A Judgment Ledger entry via `qm-record.sh add-ledger <file> <today> dragon dragon_response
   "<verbatim response>" "<what changed as a result, or 'nothing; dismissed'>"`.

**Never rewrite the story to reflect an unanswered challenge**, and never add an unanswered
challenge to the story as though it were the developer's own content.

### Step 7 — Write the story (FR-003, FR-029)

- If a feature directory exists (Step 1 case 2, or one already existed): write/update
  `<feature-dir>/story.md` in place, using `templates/story-template.md`'s section structure and
  order, preserving the existing Questmaster Record (Step 1).
- Otherwise: write a **new** file at the location `qm-pending.sh path <project-root>` prints
  (`.specify/extensions/questmaster/pending-story.md`) via `qm-pending.sh write <project-root>
  <content-file>`. **Allocate nothing else** — no directory, no branch, no number. If this call
  exits 2 (collision), that means Step 1 was not followed correctly — go back and resolve the
  collision choice first; never force an overwrite.

All 9 core sections MUST be present with real content. Extended sections present per Step 2's
path; any genuinely inapplicable extended section is written as **"N/A — `<one-line reason>`"**,
never omitted, never padded with filler to look complete.

### Step 8 — Score (FR-010, FR-011, FR-036)

Band **all ten** `story_rubric` dimensions against the anchors in
`.specify/extensions/questmaster/questmaster-config.yml` (resolve the effective config first via
`qm-config.sh`, which falls back to documented defaults if the file is missing/malformed) —
`ABSENT` / `WEAK` / `ADEQUATE` / `STRONG` — each with a **specific, cited** evidence line (FR-011:
a section's mere presence MUST NOT earn a band above `ABSENT`; vague or self-contradictory
content bands poorly regardless of length).

**`developer_judgment` MUST be banded from the Judgment Ledger alone** — read it back with
`qm-record.sh list-ledger <file>` and band strictly from what it contains, never from the quality
or completeness of AI-authored story content:
- `ABSENT`: ledger is empty.
- `WEAK`: only Dragon Pass dismissals, no other developer-originated content.
- `ADEQUATE`: at least one substantive entry beyond a Dragon dismissal.
- `STRONG`: multiple entries where the developer challenged, cut, corrected, or asserted a fact/
  constraint the AI could not have known, or engaged substantively with the Dragon Pass.

Write your ten bands to a JSON file (e.g. `{"problem_definition": "STRONG", ...}` — dimension
names exactly as in the config) and compute the score with:

```sh
CONFIG_JSON=$(mktemp); sh qm-config.sh > "$CONFIG_JSON"
sh qm-score.sh "$CONFIG_JSON" story_rubric <your-bands.json>
```

This prints `{"dimension_scores": [...], "overall_score": <0-100>}`. **Never add the weighted
contributions up yourself** — present exactly what this script returns. Write §17 Story Integrity
Assessment with every dimension's band, score, and evidence line, plus the computed
`overall_score`.

### Step 9 — Classify readiness (FR-012, data-model.md § Story Integrity Result)

Gather the critical conditions **you judged unmet from the story's content** (everything except
`no_developer_judgment_recorded`, which the script computes itself from the ledger) into a JSON
array, e.g. `["primary_actor_unknown"]` or `[]`, and run:

```sh
sh qm-readiness.sh <story-or-pending-file> <overall_score> <readiness_threshold> <your-unmet.json>
```

(`readiness_threshold` comes from the resolved config, `story_rubric.readiness_threshold`.) This
returns the classification per the FR-012 rule: any unmet critical condition forces `NOT_READY`
regardless of score; otherwise `READY` if `overall_score >= threshold`, else
`NEEDS_CLARIFICATION`. Write §16 Story Readiness Assessment stating the classification, the
score, the threshold, and every named unmet condition (or "none" if `READY`).

### Step 10 — If not `READY` (FR-014, FR-022)

State specifically what is missing/weak/unmet (name the unmet critical conditions and/or the
weak dimensions). Require an **explicit** developer choice:
- **revise** — go back to Step 3 (or a later step, as appropriate) and continue the interview;
- **accept the risk** — the developer must **type a justification in their own words**. A menu
  selection, a generated justification you offer them, an empty string, or silence **does not
  count** — re-run Step 9's script with `accept_risk` and their exact typed text as the last two
  arguments; if they gave nothing, its output leaves the status unchanged and you must say so
  plainly and ask again (never silently proceed as if accepted).

On a **valid** acceptance (the script returns `READY_WITH_ACCEPTED_RISK`), record it as a Decision
in the Questmaster Record:

```sh
sh qm-record.sh add-decision <file> <today> "Story classified <prior status> (<score>/100, threshold <threshold>; unmet: <conditions or 'none'>). Developer chose accept risk. Their reason: \"<verbatim justification>\". -> READY_WITH_ACCEPTED_RISK." outstanding
```

This is also, itself, a Judgment Ledger entry (the acceptance justification is developer-original
content) — add it with `qm-record.sh add-ledger <file> <today> story asserted_fact "<verbatim
justification>" "Accepted risk; reclassified READY_WITH_ACCEPTED_RISK."` (only once — don't
double-count the same words as two separate ledger entries if you've already logged this
exchange another way).

### Step 11 — If `READY`

State plainly that the story is ready, and that the developer can now run `/speckit-specify`.

## Output

- `<feature-dir>/story.md` (created or revised) **or**
  `.specify/extensions/questmaster/pending-story.md` when no feature directory exists yet.
- Response, in this order: quest-size decision + reason, interview transcript (as it naturally
  occurs), Dragon Pass results, Solution-Neutrality Assessment (if applicable), Story Integrity
  Assessment (bands + evidence + computed score), readiness classification, next-step guidance.

## Postconditions

- A pending story is consumed by the next `/speckit-specify` run for this request via the
  Questmaster extension's `spec-template` addendum — this command itself never touches
  `speckit-specify`'s files or control flow (FR-042).
- Re-running this command on an unchanged story SHOULD reproduce the same bands and a score
  within five points (FR-036) — a material drift on an unedited story is a defect worth
  investigating, not something to paper over by rounding toward the previous number.

## Done When

- [ ] Pending-story state (Step 1) was resolved explicitly — no interview started over an
      unclaimed pending story without an explicit revise/consume/discard choice
- [ ] `story.md` or `pending-story.md` written with all 9 core sections present and every
      inapplicable extended section marked N/A with a reason
- [ ] Dragon Pass ran with the correct challenge count for the chosen path, every response
      recorded verbatim with a disposition
- [ ] All ten dimensions banded with cited evidence; `overall_score` computed by `qm-score.sh`,
      never hand-summed
- [ ] Readiness classified by `qm-readiness.sh`; if not `READY`, an explicit revise/accept-risk
      choice was required and a valid acceptance recorded as a Decision + Judgment Ledger entry
- [ ] Completion reported to the developer with the story's location, the Story Integrity
      Assessment, the readiness classification, and next-step guidance
