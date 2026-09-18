#!/bin/sh
# test_digest_scope.sh — covers T008 (qm-digest.sh), FR-040.
#
# Editing an artifact's `## Questmaster Record` does NOT change its digest, editing the body DOES,
# and an artifact with no Questmaster Record digests identically before and after one is appended.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../../.." && pwd)
QM_DIGEST="$REPO_ROOT/extensions/questmaster/scripts/qm-digest.sh"
QM_RECORD="$REPO_ROOT/extensions/questmaster/scripts/qm-record.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

# --- Case 1: editing the Questmaster Record does NOT change the digest ---
cat > "$TMP/story.md" <<'MD'
# Quest Story: Test

## Problem Statement

Customers can't do X.

## Questmaster Record

### Judgment Ledger

### Comprehension

### Decisions
MD
D1=$(sh "$QM_DIGEST" "$TMP/story.md")
sh "$QM_RECORD" add-decision "$TMP/story.md" "2026-09-13" "Some narrative about an override." outstanding
sh "$QM_RECORD" add-ledger "$TMP/story.md" "2026-09-13" "story" "cut" "Dropped X." "Narrowed scope."
D2=$(sh "$QM_DIGEST" "$TMP/story.md")
[ "$D1" = "$D2" ] || fail "digest changed after editing only the Questmaster Record ($D1 vs $D2)"

# --- Case 2: editing the body DOES change the digest ---
sed -i.bak "s/Customers can't do X\./Customers cannot do X at all, ever./" "$TMP/story.md"
D3=$(sh "$QM_DIGEST" "$TMP/story.md")
[ "$D1" != "$D3" ] || fail "digest did NOT change after editing the artifact body"

# --- Case 3: an artifact with no Questmaster Record digests identically before/after one is appended ---
cat > "$TMP/plain.md" <<'MD'
# Quest Story: Plain

## Problem Statement

Something happens.
MD
D4=$(sh "$QM_DIGEST" "$TMP/plain.md")
sh "$QM_RECORD" ensure-sections "$TMP/plain.md"
D5=$(sh "$QM_DIGEST" "$TMP/plain.md")
[ "$D4" = "$D5" ] || fail "digest changed after appending an EMPTY Questmaster Record ($D4 vs $D5)"

# same, but this time also populate the freshly-appended sections
sh "$QM_RECORD" add-ledger "$TMP/plain.md" "2026-09-13" "story" "cut" "Dropped Y." "Narrowed scope."
D6=$(sh "$QM_DIGEST" "$TMP/plain.md")
[ "$D4" = "$D6" ] || fail "digest changed after populating the appended Questmaster Record ($D4 vs $D6)"

# --- Case 4: digest format is well-formed ---
echo "$D1" | grep -qE '^sha256:[0-9a-f]{64}$' || fail "digest output not in expected sha256:<64 hex> format: $D1"

echo "OK: test_digest_scope.sh"
