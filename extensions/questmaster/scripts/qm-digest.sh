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
