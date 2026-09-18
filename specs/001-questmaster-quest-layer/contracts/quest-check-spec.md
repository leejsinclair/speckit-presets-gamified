# Command Contract: `/speckit-questmaster-check-spec`

## Purpose

The Specification Integrity assessment (FR-015, FR-017–FR-021, FR-037–FR-040). Invoked
automatically by the `after_specify` hook (FR-030), and independently re-runnable on demand.

## Input

None required beyond the active feature context (`.specify/feature.json`).

## Preconditions

Must run in an **independent context** (FR-037): the conversation that authored `spec.md` MUST
NOT be in scope. Only `story.md`, `spec.md`, the rubric configuration, and both artifacts'
Questmaster Records are provided as input. Where the host environment offers no mechanism to
start such a context, the command still runs but every output is labelled `SELF-ASSESSED` (see
step 6) — this label is not configurable away.

## Behavior

1. **Relocate a pending story, if any**: if `.specify/extensions/questmaster/pending-story.md` exists and
   this feature directory has no `story.md` yet, move the pending story into this feature
   directory as `story.md` before continuing (FR-029). This is the one place the pending-story
   mechanism resolves; it does not require touching `speckit-specify` itself.
2. Resolve the active feature directory. If it has no `story.md` (and no pending story to
   relocate):
   - **Hook-triggered invocation**: exit immediately, write nothing, print nothing (FR-025).
   - **Explicit/manual invocation**: state plainly that the assessment could not be performed and
     explain how to run `/speckit-questmaster-story` first (FR-026).
3. Require `spec.md` to exist in the same feature directory (it always will when hook-triggered).
4. Compute content digests of `story.md` and `spec.md` for the persisted report (FR-040), each
   over the artifact's content **excluding its `## Questmaster Record` section** (data-model.md →
   Source digest scope). A Decision, Judgment Ledger entry, or Comprehension answer written by
   Questmaster itself MUST NOT change a digest; only a change to the artifact body may.
5. Read `story.md`'s Questmaster Record: gather every Outstanding Accepted Risk (Decision entries
   with status `outstanding`) for carry-forward (FR-039). For each, judge whether the condition
   that prompted the acceptance still holds:
   - still holds → restate it in the report, with its acceptance date and the developer's own
     reason, before this assessment's own findings;
   - no longer holds → it MAY be auto-resolved, but only with the specific artifact content that
     shows this cited as `resolution_evidence`, recorded as `resolved_by: questmaster` (never as
     the developer's own resolution, and never as a Judgment Ledger entry), and reported in this
     run's output as an auto-resolution the developer can reopen.
   Absence of an objection is never evidence. When in doubt, leave it outstanding — an
   over-carried risk costs two lines of report, a wrongly-closed one costs the record.
6. Band `spec.md` against `story.md` using `specification_integrity_rubric` from
   `.specify/extensions/questmaster/questmaster-config.yml` (fall back to documented defaults if missing/malformed),
   across all 7 dimensions named in FR-015, each band with cited evidence (FR-036). Determine and
   record the assessment context as `INDEPENDENT` or `SELF-ASSESSED` per the Preconditions.
7. For every requirement, scope item, and assumption in `spec.md`, assign exactly one Drift
   Classification against `story.md` — `PRESERVED`, `REFINED`, `CLARIFIED`, `DISCOVERED`,
   `ACCEPTED_SCOPE_CHANGE`, or `UNJUSTIFIED_DRIFT` (FR-017). Read `story.md`'s Decisions
   subsection first: only classify an element `ACCEPTED_SCOPE_CHANGE` when a matching recorded
   acceptance exists there; otherwise an out-of-story-scope element is `UNJUSTIFIED_DRIFT`
   (FR-019). Never classify content `UNJUSTIFIED_DRIFT` solely for not being verbatim in the story
   — reasonable elaboration is `REFINED`/`CLARIFIED` (FR-020). Compare by underlying intent, not
   by matching section titles or literal wording (Edge Case).
8. For every `DISCOVERED`/`ACCEPTED_SCOPE_CHANGE`/`UNJUSTIFIED_DRIFT` element, produce a full
   finding (source artifact, destination artifact, original intent, new behavior, classification,
   evidence, severity, developer question) (FR-018).
9. **Assemble decision-first** (FR-038): a Decision Worklist of at most three items — the
   highest-severity `DISCOVERED`/`UNJUSTIFIED_DRIFT` findings — each with its question. If more
   than three qualify, name and count the remainder. If none qualify, state "No decision
   required." Then list Outstanding Accepted Risk from step 5. Then the banded dimension summary.
   Then the full per-element classification (aggregate count for `PRESERVED`/`REFINED`/
   `CLARIFIED`, full table in an appendix).
10. Write/overwrite `<feature-dir>/spec-integrity.md` per the report structure in data-model.md,
    including the digests from step 4 and the context label from step 6.
11. Present the same content, in the same order, in the response. Findings and scores are
    advisory only — never auto-modify, block, or reject `spec.md` (FR-022).
12. **Elicit a response to the top decision** (FR-043): where the Decision Worklist from step 9
    is non-empty, ask the developer to resolve, accept, or explicitly defer its highest-severity
    item. Record the response verbatim as a Judgment Ledger entry; an acceptance additionally
    requires a justification in the developer's own words and is recorded as a Decision
    (FR-014/FR-027). Record a deferral as a deferral and an unanswered item as unanswered,
    carried forward per FR-039. Where step 9 stated that no decision is required, ask nothing —
    this step is skipped entirely, not asked with an empty subject. Never block on the answer.

## Output

- `<feature-dir>/spec-integrity.md` (written only when a `story.md` exists or is relocated)
- `spec.md`'s Questmaster Record updated with the developer's response to the top Decision
  Worklist item, or with a recorded deferral/non-response (step 12) — absent entirely when the
  worklist was empty
- Response, in order: Decision Worklist, Outstanding Accepted Risk (including any auto-resolved
  this run, marked as such with their evidence), dimension bands + evidence, Drift Classification
  summary, full findings, advisory note

## Postconditions

None enforced — the developer may proceed to `/speckit-plan` regardless of findings. Every
Decision Worklist item the developer resolves with an override MUST be recorded per FR-014/FR-027
and will be carried forward by `/speckit-questmaster-check-plan` (FR-039).
