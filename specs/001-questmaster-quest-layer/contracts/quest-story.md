# Command Contract: `/speckit-questmaster-story`

## Purpose

The Storyteller stage (FR-001–FR-014, FR-029, FR-033–FR-036). Runs before any other Spec Kit
feature artifact exists for a given request.

## Input

Free-text feature description typed after `/speckit-questmaster-story`, which may be a single vague sentence,
and which may already contain a proposed solution.

## Preconditions

None required. May be the very first command run for a brand-new feature. Does **not** require a
feature directory, a branch, or `.specify/feature.json` to exist (FR-029 — revised 2026-09-13a:
this command no longer allocates any of those itself).

## Behavior

1. **Resolve state**:
   - If the active feature directory (per `.specify/feature.json`) already contains a `story.md`,
     treat this as **revising** that story: warn that any existing `spec-integrity.md`/
     `plan-integrity.md` may now be stale (confirmed later by digest mismatch, FR-040), and
     proceed with the interview using the existing story — including its existing Questmaster
     Record, which MUST be preserved, not reset — as a starting point.
   - Otherwise, if `.specify/extensions/questmaster/pending-story.md` already exists, **do not
     overwrite it and do not begin a new interview** (FR-029). State that an unclaimed pending
     story exists, name its Quest Title and the date it was written, and require an explicit
     choice:
     - **revise it** — continue the interview against that story, preserving its Questmaster
       Record;
     - **consume it** — stop here and tell the developer to run `/speckit-specify`, which takes the
       pending story as primary input;
     - **discard it** — only on an explicit instruction, delete it and start the new interview.
     Silence, an ambiguous reply, or a request that simply looks different from the pending story
     MUST NOT be read as a discard. Never merge an unrelated request into an existing pending
     story.
   - Otherwise, this is a new story with no feature directory yet. **Do not** allocate one, a
     branch, or a number — the pending-story mechanism (step 7) defers that entirely to
     `/speckit-specify`.
2. **Size the quest** (FR-033): from the request's apparent scope, choose **Short Quest** (core
   sections only; extended sections only where material; target ~6 questions, under 5 minutes) or
   **Full Quest** (all sections; target ~12 questions, under 15 minutes). The budget covers the
   whole developer-facing stage, step 6's Dragon Pass challenges included. State the choice and a
   one-line reason. The developer may override this choice at any point; the Storyteller may
   escalate Short → Full mid-interview, stating why. These are design budgets, not hard cutoffs.
3. **Interview** (FR-001): cover the core sections always; cover the extended sections on a Full
   Quest, or on a Short Quest only where the developer's answers make one materially relevant.
   Keep Problem/Need/Outcome/Requirement/Solution distinct throughout (FR-004); if a solution is
   named, record it and continue probing for the underlying problem rather than adopting the
   proposal as-is (FR-005). Stop once there is sufficient evidence (FR-002), not a fixed question
   count.
4. **Surface contradictions**: if answers conflict, ask for clarification rather than silently
   picking one; the resolution becomes a Judgment Ledger entry (`kind: correction` or
   `asserted_fact`, whichever fits).
5. **Solution-Neutrality Assessment** (FR-005): if a proposed solution was supplied, classify each
   part as a genuine requirement, proposed implementation detail, an assumption, or an unnecessary
   constraint. If the developer resists separating problem from solution, record the proposal
   anyway, note that neutrality could not be fully assessed and why, and continue — never block.
6. **Dragon Pass** (FR-034): before scoring, raise **two to three** adversarial challenges on a
   Short Quest, **three to five** on a Full Quest — counted inside step 2's interview budget, not
   added to it — specific to this story's content — what can fail, which assumption is unsafe, behavior under
   unexpected input, dependency/partial failure, migration, changing requirements. Record the
   developer's response to each verbatim, including explicit dismissals, as a Dragon's Questions
   entry and as a Judgment Ledger entry (`kind: dragon_response`). Never rewrite the story to
   reflect an unanswered challenge.
7. **Write the story**:
   - If a feature directory already exists (this is a revision, or one was created by an earlier
     `/speckit-specify` run in this session): write/update `<feature-dir>/story.md`.
   - Otherwise: write `.specify/extensions/questmaster/pending-story.md` (FR-029). Allocate nothing else.
   All 9 core sections MUST be present; extended sections present per step 2's path; any
   genuinely inapplicable section marked N/A with a one-line reason (FR-003) — never omitted or
   padded.
8. **Score**: band the story against `story_rubric` from `.specify/extensions/questmaster/questmaster-config.yml`
   (falling back to documented defaults if missing/malformed) across all ten dimensions (FR-010),
   each `ABSENT`/`WEAK`/`ADEQUATE`/`STRONG` with cited evidence (FR-011, FR-036); compute the
   0-100 score deterministically from the bands. `developer_judgment` MUST be banded from the
   Judgment Ledger alone, never from AI-authored content quality.
9. **Classify readiness**: `NOT_READY` / `NEEDS_CLARIFICATION` / `READY` /
   `READY_WITH_ACCEPTED_RISK` per data-model.md's Story Integrity Result classification rule
   (FR-012) — any unmet critical condition, including an empty Judgment Ledger
   (`no_developer_judgment_recorded`), forces `NOT_READY` regardless of score.
10. **If not `READY`**: state specifically what's unmet/missing/weak and require an explicit
    developer choice — revise, or accept the risk. Accepting REQUIRES the developer to type a
    justification in their own words; a menu selection, empty string, or silence does not count
    and leaves the status unchanged (FR-014). A valid acceptance is recorded as a Decision (status
    `outstanding`) in the story's Questmaster Record and the status becomes
    `READY_WITH_ACCEPTED_RISK`.
11. **If `READY`**: state the story is ready for `/speckit-specify`.

## Output

- `<feature-dir>/story.md` (created or revised) **or** `.specify/extensions/questmaster/pending-story.md`
  when no feature directory exists yet
- Response: quest-size decision, interview transcript, Dragon Pass results, Solution-Neutrality
  Assessment (if applicable), Story Integrity Assessment (bands + evidence + computed score),
  readiness classification, next-step guidance

## Postconditions

- A pending story is consumed by the next `/speckit-specify` run for this request via the
  Questmaster extension's `spec-template` addendum (see `contracts/extension.yml`'s
  `provides.templates` entry, `quest-check-spec.md`'s step 1, and data-model.md's Pending Story
  section) — this command itself never touches `speckit-specify`'s files or control flow
  (FR-042).
- Re-running `/speckit-questmaster-story` on an unchanged story SHOULD reproduce the same bands and a score
  within five points (FR-036) — a material drift on an unedited story is a defect.
