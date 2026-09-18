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
