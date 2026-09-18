<!--
QUESTMASTER SPEC-TEMPLATE ADDENDUM (tasks.md T028; FR-029, FR-042).

CORRECTED 2026-09-13e (research.md §14): the byte-identical, actually-SHIPPED copy of this file
now lives at `templates/spec-template.md` (the repo-root `questmaster-pending-story` preset,
formerly `presets/questmaster-pending-story/templates/spec-template.md` before the preset moved
to the repo root) — an extension's
`provides.templates` entries only ever use 'replace' semantics (verified by actually running
`specify extension add --dev`, which rejects `strategy: prepend` on an extension-provided
template), so the prepend strategy this addendum requires had to move to a companion PRESET,
which is the only manifest kind that supports it. This copy is kept here as the design-intent
record tasks.md T028 produced; if you are changing the addendum's content, change the preset's
copy first (it is what actually ships) and copy the change back here.

This addendum is resolved by Spec Kit's own template-resolution stack ABOVE the core
spec-template's content — it substitutes template CONTENT only and requires no change to
`/speckit-specify`'s control flow (the command itself is never touched). It is pure authoring
guidance for whoever fills in the template that follows (developer + agent running
`/speckit-specify`) and, being an HTML comment, contributes NOTHING to the literal text of the
written spec.md whether or not a pending story exists — the difference below is in what the
agent DOES while drafting, not in any visible boilerplate this addendum would otherwise inject.

Before filling in the spec-template sections that follow this comment, check whether
`.specify/extensions/questmaster/pending-story.md` exists in this repository.

- **If it exists**: read it in full. It is a Quest Story produced by
  `/speckit-questmaster-story` (data-model.md § Quest Story Structure) and MUST be treated as the
  PRIMARY input for this specification — take its Problem Statement, Who Is Affected/Actors,
  Current Behaviour, Use Cases, Desired Outcomes, Scope Boundaries, Success Criteria, and
  Assumptions & Known Unknowns as the authoritative source for the corresponding sections below,
  in preference to any looser interpretation of whatever feature description you were otherwise
  given. If the pending story's §13 Proposed Solutions & Solution-Neutrality Assessment is
  present, use its requirement/implementation-detail/assumption/unnecessary-constraint split to
  decide which parts of any developer-proposed solution belong in this spec's Functional
  Requirements versus which belong to a later `/speckit-plan` — do not silently re-adopt a
  proposal the story already separated out.
  **Do NOT move, rename, or delete the pending story file yourself.** The `after_specify` hook
  (`/speckit-questmaster-check-spec`) relocates it into this feature directory as `story.md`
  once this command finishes allocating the feature directory — reading it here, while drafting,
  is read-only.
- **If it does not exist**: this addendum contributes nothing. Proceed exactly as you would with
  no Questmaster extension installed (FR-025) — no Questmaster-related behavior, output, or
  section appears anywhere in the resulting spec.md.

This entire comment block is authoring guidance only and MUST NOT appear, in any form, in the
written spec.md.
-->
