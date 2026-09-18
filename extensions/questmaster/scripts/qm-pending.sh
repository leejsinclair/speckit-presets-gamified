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
