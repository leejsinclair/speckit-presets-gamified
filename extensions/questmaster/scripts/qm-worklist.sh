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
