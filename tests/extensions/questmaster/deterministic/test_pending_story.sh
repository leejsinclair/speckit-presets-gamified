#!/bin/sh
# test_pending_story.sh — covers the pending-story write/relocate/discard cycle (qm-pending.sh),
# data-model.md § Pending Story, FR-029 [US1]. Replaces the retired test_feature_reuse.sh.
#
# Exercises the write/relocate/consume cycle as pure file operations, PLUS the collision case:
# with an unclaimed pending story present, a new unrelated request never overwrites it, and
# silence or an ambiguous reply is not treated as a discard.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../../.." && pwd)
QM_PENDING="$REPO_ROOT/extensions/questmaster/scripts/qm-pending.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

PROJECT="$TMP/project"
mkdir -p "$PROJECT"

# --- Case 1: no feature directory, no pending story -> write succeeds ---
sh "$QM_PENDING" exists "$PROJECT" && fail "pending story should not exist yet" || true
cat > "$TMP/story_a.md" <<'MD'
# Quest Story: Notification Preferences

## Quest Title

Customer control over marketing email preferences

## Problem Statement
Customers can't opt out per category.
MD
sh "$QM_PENDING" write "$PROJECT" "$TMP/story_a.md"
sh "$QM_PENDING" exists "$PROJECT" || fail "pending story should exist after write"
[ "$(sh "$QM_PENDING" title "$PROJECT")" = "Customer control over marketing email preferences" ] \
  || fail "title extraction failed: $(sh "$QM_PENDING" title "$PROJECT")"

# --- Case 2: collision — a second unrelated write MUST be refused, not merged or overwritten ---
cat > "$TMP/story_b.md" <<'MD'
# Quest Story: Dark Mode

## Quest Title

Dark mode theme toggle

## Problem Statement
Users want a dark theme.
MD
if sh "$QM_PENDING" write "$PROJECT" "$TMP/story_b.md" 2>"$TMP/collision.err"; then
  fail "second write for an unrelated request must be REFUSED, not silently accepted"
fi
grep -qi "refused" "$TMP/collision.err" || fail "refusal message not clear: $(cat "$TMP/collision.err")"
# Confirm the ORIGINAL pending story is still intact and unmerged.
[ "$(sh "$QM_PENDING" title "$PROJECT")" = "Customer control over marketing email preferences" ] \
  || fail "pending story was overwritten/merged despite refusal"

# --- Case 3: silence / ambiguity is not a discard — the pending story must still be there,
#     and no operation other than an explicit "discard" removes it. ---
# (Modeled here as: nothing calls `discard`, so the file must persist untouched.)
sh "$QM_PENDING" exists "$PROJECT" || fail "pending story vanished with no explicit discard"

# --- Case 4: explicit discard removes it, and only then can a new unrelated story be written ---
sh "$QM_PENDING" discard "$PROJECT"
sh "$QM_PENDING" exists "$PROJECT" && fail "pending story should be gone after explicit discard" || true
sh "$QM_PENDING" write "$PROJECT" "$TMP/story_b.md"
[ "$(sh "$QM_PENDING" title "$PROJECT")" = "Dark mode theme toggle" ] \
  || fail "new story not written after discard"

# --- Case 5: relocate moves the pending story into the feature directory as story.md ---
FEATURE_DIR="$PROJECT/specs/001-dark-mode"
RELOCATED=$(sh "$QM_PENDING" relocate "$PROJECT" "$FEATURE_DIR")
[ "$RELOCATED" = "$FEATURE_DIR/story.md" ] || fail "relocate did not report the expected target path"
[ -f "$FEATURE_DIR/story.md" ] || fail "story.md not created at the feature directory"
sh "$QM_PENDING" exists "$PROJECT" && fail "pending story should no longer exist after relocation" || true
grep -q "Dark mode theme toggle" "$FEATURE_DIR/story.md" || fail "relocated story.md content is wrong"

# --- Case 6: relocate with nothing pending fails loudly rather than silently no-opping ---
if sh "$QM_PENDING" relocate "$PROJECT" "$TMP/project/specs/002-other" 2>/dev/null; then
  fail "relocate with no pending story should fail"
fi

# --- Case 7: discard with nothing pending fails loudly ---
if sh "$QM_PENDING" discard "$PROJECT" 2>/dev/null; then
  fail "discard with no pending story should fail"
fi

echo "OK: test_pending_story.sh"
