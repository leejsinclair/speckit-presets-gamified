# Command Contract: `/speckit-questmaster-check-plan`

## Purpose

The Comprehension Checkpoint and Plan Integrity assessment (FR-016, FR-017–FR-021, FR-037–FR-041).
Invoked automatically by the `after_plan` hook (FR-030), and independently re-runnable on demand.

## Input

None required beyond the active feature context (`.specify/feature.json`).

## Preconditions

Must run in an **independent context** (FR-037): the conversation that authored `plan.md` MUST
NOT be in scope for the assessment portion (step 5 onward). The Comprehension Checkpoint (step 3)
is a direct developer interaction and is not subject to this constraint. Where the host
environment offers no independent-context mechanism for the assessment, it still runs but is
labelled `SELF-ASSESSED` throughout, not configurable away.

## Behavior

1. Resolve the active feature directory. If it has no `story.md`:
   - **Hook-triggered invocation**: exit immediately, write nothing, print nothing (FR-025).
   - **Explicit/manual invocation**: state plainly that the assessment could not be performed and
     explain how to run `/speckit-questmaster-story` first (FR-026).
2. Require both `story.md` and `spec.md` to exist alongside `plan.md`.
3. **Comprehension Checkpoint, before anything else is shown** (FR-041): read `plan.md`'s
   Questmaster Record → Comprehension first, then ask this round's questions — answers the plan
   itself cannot supply.
   - **No round recorded yet** (first checkpoint for this plan): ask exactly **three** — which
     part is most likely to be wrong, what they would cut, what breaks first (under load,
     failure, or changing requirements).
   - **One or more rounds already recorded** (a re-run): restate the recorded answers rather than
     re-asking them, and ask exactly **one** further question that differs from every question
     already recorded for this plan (data-model.md → Comprehension Checkpoint round rule). If no
     genuinely non-derivable question remains, say so and ask nothing rather than padding.
   Record answers verbatim in `plan.md`'s Questmaster Record → Comprehension under a new round
   heading, and add each as a Judgment Ledger entry (`kind: comprehension_answer`). The developer
   may decline; record the decline as a decline, not an absence. Do not block on this step, and do
   not let the AI answer on the developer's behalf.
4. Compute content digests of `story.md`, `spec.md`, and `plan.md` for the persisted report
   (FR-040), each over the artifact's content **excluding its `## Questmaster Record` section**
   (data-model.md → Source digest scope) — note this is what keeps step 3's own writes from
   marking this plan changed. Read both artifacts' Questmaster Records for Outstanding Accepted
   Risk (FR-039), applying the same still-holds / auto-resolve judgment as
   `quest-check-spec.md`'s step 5: auto-resolution requires cited evidence, is attributed to
   Questmaster rather than the developer, and is reported so it can be reopened.
5. **Independent assessment** (FR-037): band `plan.md` against **both** `story.md` and `spec.md`
   using `plan_integrity_rubric` from `.specify/extensions/questmaster/questmaster-config.yml` (fall back to documented
   defaults if missing/malformed), across all 8 dimensions named in FR-016, each with cited
   evidence (FR-036). Band `intent_preservation` independently of technical/architectural quality
   — a technically sound plan that abandons the story's desired outcome or constraints MUST NOT
   band well overall. Band `legibility` independently of technical correctness — whether a
   developer who did not author the plan could follow it.
6. For every component, service, or abstraction in `plan.md`, assign exactly one Drift
   Classification against `story.md`/`spec.md` (FR-017), consulting both artifacts' Decisions
   subsections before ever using `ACCEPTED_SCOPE_CHANGE` (FR-019).
7. Band `constraint_preservation` specifically: flag when a story-level constraint is dropped or
   contradicted by the plan, even if `spec.md` carried that constraint forward — distinct from
   `specification_coverage`, which covers the specification's own requirements.
8. **Never** flag or recommend simplifying a design solely for being complex (FR-021): a complex
   element traceable to a stated requirement, constraint, or risk bands under `proportionality` as
   `PRESERVED`/`REFINED`, not drift.
9. For every `DISCOVERED`/`ACCEPTED_SCOPE_CHANGE`/`UNJUSTIFIED_DRIFT` element, produce a full
   Drift Classification finding (FR-018).
10. **Cross-reference the Comprehension Checkpoint**: state explicitly where the assessment's own
    findings agree or disagree with the developer's recorded predictions from every round, not
    only this run's (e.g. "you predicted the
    retry path was most likely to be wrong; this assessment instead found the dropped retention
    constraint more significant").
11. **Assemble decision-first** (FR-038): a Decision Worklist of at most three items (highest
    severity first), then Outstanding Accepted Risk, then banded dimension summary (including the
    Comprehension cross-reference from step 10), then full findings with aggregate
    `PRESERVED`/`REFINED`/`CLARIFIED` counts and a per-element appendix.
12. Write/overwrite `<feature-dir>/plan-integrity.md` per the report structure in data-model.md,
    including digests and the context label.
13. Present the same content, in the same order, in the response — advisory only (FR-022), never
    blocking `/speckit-tasks`.

## Output

- `<feature-dir>/plan-integrity.md` (written only when a `story.md` exists)
- `plan.md`'s Questmaster Record updated with this round's Comprehension answers and Judgment
  Ledger entries (step 3), independent of whether the rest of the assessment can complete
- Response, in order: Comprehension Checkpoint for this round (three questions on the first run,
  one on each re-run, with earlier rounds restated), Decision Worklist, Outstanding Accepted Risk
  (including any auto-resolved this run, marked as such with their evidence), dimension bands +
  evidence (with Comprehension cross-reference), Drift Classification summary, full findings,
  advisory note

## Postconditions

None enforced. Any override recorded here is carried forward by any future downstream stage
(FR-039) — none exists in this release, so the carry-forward chain currently ends at Plan
Integrity.
