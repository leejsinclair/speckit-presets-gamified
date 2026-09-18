# Quickstart: Validating Questmaster End-to-End

## Prerequisites

- This Spec Kit project (`.specify/`, Claude integration, `1.0.2.dev0`) — unmodified (FR-042: no
  Questmaster component edits any existing Spec Kit file).
- Questmaster installed as a real extension: `specify extension add --dev ./extensions/questmaster`
  (or the published equivalent once catalogued), which materializes
  `.specify/extensions/questmaster/questmaster-config.yml` from `contracts/extension.yml`'s
  `provides.config` template (or leave it absent, to exercise the default-fallback path; band
  anchors and multipliers live here per FR-036), registers
  `.claude/skills/speckit-questmaster-{story,check-spec,check-plan}/`, and writes the
  `after_specify`/`after_plan` hook entries from `contracts/extension.yml`'s `hooks:` section into
  the project's `.specify/extensions.yml` (see `contracts/extensions.yml` for what that
  CLI-managed file looks like afterward — it is never hand-authored for Questmaster's sake).

## Scenario A — Faithful quest, Full path (happy path, exercises User Stories 1–3)

1. Run `/speckit-questmaster-story` with a deliberately vague request, e.g. "we need to let customers
   configure notification preferences."
   - **Expect**: Questmaster states a quest-size decision (Short or Full) with a one-line reason
     before any question is asked.
   - **Expect**: a bounded series of Socratic questions covering the 9 core sections (problem,
     affected actors, current state, meaningful use cases, desired outcome, scope boundaries,
     success criteria, known facts vs. assumptions/unknowns) plus, on a Full Quest, background,
     business rules, and constraints — within the stated budget (~12 questions / 15 minutes for
     Full, ~6/5 for Short) before any document is produced.
   - Answer with enough substance to band `ADEQUATE`/`STRONG` on most dimensions and leave no
     critical condition unmet.
   - **Expect**: after the interview, a **Dragon Pass** raises a small number of challenges
     specific to this story's content (not generic risk boilerplate). Answer or dismiss each.
   - **Expect**: `specs/<NNN>-.../story.md` created with all core sections present (any
     genuinely inapplicable extended section explicitly marked N/A with a reason), a Dragon's
     Questions section recording every challenge and response, a Judgment Ledger with at least
     one entry from your dismissals/answers, and a final response showing a Story Integrity
     Assessment: each of the ten dimensions banded `ABSENT`/`WEAK`/`ADEQUATE`/`STRONG` with a
     specific evidence line, a computed 0-100 score (never a bare number), and a `READY`
     classification with a "ready for `/speckit-specify`" statement.
2. Repeat with a request that already proposes a solution, e.g. "create a NotificationPreference
   table so customers can disable marketing emails."
   - **Expect**: the proposal is recorded separately under Proposed Solutions, the Problem/
     Desired-Outcome sections are phrased solution-neutrally, and the Solution-Neutrality
     Assessment classifies which parts of the proposal are requirements, implementation detail,
     assumptions, or unnecessary constraints — the proposal is never silently adopted or
     rejected.
3. Run `/speckit-specify` for the same request.
   - **Expect**: `speckit-specify` runs completely unmodified and allocates its feature directory
     exactly as it would with no Questmaster installed.
   - **Expect**: the `after_specify` hook fires, `/speckit-questmaster-check-spec` relocates the pending story
     (if `/speckit-questmaster-story` had not already created a feature directory) into `story.md`, runs the
     Specification Integrity assessment **in an independent context** (confirm the report is
     labelled `INDEPENDENT`, not `SELF-ASSESSED`), and writes `spec-integrity.md`.
   - **Expect** the report to open with a **Decision Worklist** (or "No decision required" for a
     faithful spec), then any Outstanding Accepted Risk, then bands across all 7 dimensions with
     evidence, then a Drift Classification **summary count** (not a full per-row table) showing
     every requirement `PRESERVED`, `REFINED`, or `CLARIFIED` — with the full per-element table
     still present in an appendix.
4. Run `/speckit-plan`.
   - **Expect**: before any assessment content appears, the **Comprehension Checkpoint** asks
     three questions the plan itself doesn't answer (most likely to be wrong / what you'd cut /
     what breaks first). Answer them.
   - **Expect**: the `after_plan` hook fires, `/speckit-questmaster-check-plan` records your answers verbatim
     in `plan.md`'s Questmaster Record and Judgment Ledger, then runs the Plan Integrity
     assessment independently, banded across all 8 dimensions (including `intent_preservation`
     and `constraint_preservation` scored separately from `proportionality`/`legibility`), with
     Drift Classification findings only where a technical decision isn't traceable to `story.md`/
     `spec.md`.
   - **Expect** the report to state explicitly where its own findings agree or disagree with your
     Comprehension Checkpoint predictions.
5. Confirm nothing was auto-modified, blocked, or rejected at any step — all Questmaster output
   is advisory (FR-022) — and confirm a `NOT_READY`/`NEEDS_CLARIFICATION` story earlier in the
   flow would still have offered an explicit revise/accept-risk choice, requiring you to type a
   reason, rather than a hard block or a one-click acceptance.

## Scenario A2 — Short Quest path (exercises FR-033)

1. Run `/speckit-questmaster-story` with a small, well-bounded request (e.g. "add a 'copy to clipboard' button
   next to the API key display").
   - **Expect**: Questmaster states it is taking the Short Quest path and why, asks roughly 6
     questions covering only the core sections (extended sections addressed only if genuinely
     material, otherwise explicitly marked N/A), and completes in well under the Full Quest's
     budget. The Dragon Pass raises 2-3 challenges and those count toward the ~6, rather than
     arriving as a second round of questions after the interview appeared to end (FR-034).
2. Mid-interview, give an answer that reveals unexpected scope (e.g. "actually this needs to work
   across three different key types with different copy formats").
   - **Expect**: the Storyteller may escalate to a Full Quest, stating why, and the extended
     sections are then asked.

## Scenario B — Drifting quest (exercises Drift Classification, decision-first reporting)

Using `tests/extensions/questmaster/fixtures/drifting-quest/` fixtures (a `story.md` describing one
narrow customer-preference need, paired with a `spec.md`/`plan.md` that introduce unrequested
scope):

1. Run `/speckit-questmaster-check-spec` and `/speckit-questmaster-check-plan` against the fixture pair directly.
   - **Expect**: the unsupported additions are classified `UNJUSTIFIED_DRIFT` (SC-005) and appear
     in the **Decision Worklist** (not buried in a full table) with a full finding (source/
     destination artifact, original intent, new behavior, evidence, severity, developer
     question); nothing is auto-simplified or rejected.
   - Add a matching Questmaster Decision — with a developer-written justification — to the
     fixture's `spec.md`/`plan.md` Questmaster Record accepting one of the additions, and re-run.
   - **Expect** that specific element reclassified `ACCEPTED_SCOPE_CHANGE` rather than
     `UNJUSTIFIED_DRIFT`, and that it now appears as an **Outstanding Accepted Risk** in any
     later-stage report rather than disappearing from view.
2. Compare against `tests/extensions/questmaster/fixtures/faithful-quest/`, where the spec/plan stay
   within the story's intent.
   - **Expect**: legitimate elaborations are classified `REFINED`, not `UNJUSTIFIED_DRIFT`, and
     the Decision Worklist for this pair says "No decision required."

## Scenario C — Non-adopting project (exercises FR-025/SC-006/FR-042)

In a feature directory with no `story.md` and no pending story (standard Spec Kit usage,
Questmaster never invoked):

1. Run `/speckit-specify` then `/speckit-plan` normally.
   - **Expect**: output is byte-for-byte identical to a project without Questmaster installed —
     no `spec-integrity.md`/`plan-integrity.md` files appear, no Questmaster-related messages,
     warnings, or errors, and no existing Spec Kit file behaves differently, because none was
     modified to install Questmaster in the first place.

## Scenario D — Missing/malformed rubric config (exercises the Edge Case)

1. Temporarily rename or corrupt `.specify/extensions/questmaster/questmaster-config.yml`.
2. Run `/speckit-questmaster-story`.
   - **Expect**: a one-line warning that the config is missing/malformed, followed by scoring
     that proceeds using the documented default weights/band anchors/threshold/critical-
     conditions — the assessment must not fail outright.

## Scenario E — High score, unmet critical condition (exercises FR-012/SC-007)

1. Run `/speckit-questmaster-story` and answer every question except never identify a primary affected actor,
   while otherwise giving strong, detailed answers everywhere else — and engage substantively
   with the Dragon Pass so the ledger is not empty.
   - **Expect**: the Story Integrity Score may be high (e.g. banding `STRONG`/`ADEQUATE` on most
     dimensions), but the readiness classification is `NOT_READY` (not `READY`), with
     `primary_actor_unknown` explicitly named as the unmet critical condition — confirming the
     score threshold alone never determines readiness.
2. Choose to proceed anyway, and try to accept with no justification typed.
   - **Expect**: the acceptance is rejected — status remains `NOT_READY` — until a written reason
     is supplied. Supply one.
   - **Expect**: a Questmaster Record → Decisions entry is appended to `story.md` recording the
     override and the developer's own reason, the status becomes `READY_WITH_ACCEPTED_RISK`, and
     it is marked `outstanding`.

## Scenario F — Empty Judgment Ledger (exercises FR-012's new critical condition, FR-035)

1. Run `/speckit-questmaster-story` and, for every question, accept whatever draft answer or suggestion
   Questmaster offers without challenging, cutting, or asserting anything yourself; at the Dragon
   Pass, respond "sure, that's fine" to every challenge without engaging with its substance.
   - **Expect**: the Judgment Ledger is empty (a bare "fine" carries no developer-originated
     content), `developer_judgment` bands `ABSENT`, `no_developer_judgment_recorded` is named as
     an unmet critical condition, and the story is `NOT_READY` regardless of how well the other
     nine dimensions band.

## Scenario G — Assessment independence (exercises FR-037, Constitution XIII)

1. In an environment where subagent spawning is available, run `/speckit-specify` and confirm the
   resulting `spec-integrity.md` is labelled `INDEPENDENT` and its source digests are recorded.
2. Simulate an environment with no subagent mechanism (or inspect the fallback path directly).
   - **Expect**: the assessment still runs and produces a full report, but every copy of it — in
     the response and in `spec-integrity.md` — is labelled `SELF-ASSESSED`, and there is no
     configuration flag that removes the label.

## Scenario H — Comprehension Checkpoint decline (exercises FR-041's non-blocking guarantee)

1. Run `/speckit-plan`, and when the Comprehension Checkpoint asks its three questions, decline.
   - **Expect**: the decline is recorded as `DECLINED` (not silently skipped or treated as an
     empty answer), the Plan Integrity assessment proceeds without the developer's predictions to
     cross-reference, and nothing is blocked.

## Scenario H2 — Comprehension Checkpoint on a re-run (exercises FR-041's round rule, added 2026-09-13d)

1. Run `/speckit-plan` and answer all three checkpoint questions.
2. Re-run `/speckit-questmaster-check-plan` on demand, without changing `plan.md`.
   - **Expect**: the three round-1 answers are restated rather than re-asked; exactly **one**
     further question is asked, and it is not one of the three already recorded; the answer lands
     under a `Round 2` heading in `plan.md`'s Questmaster Record → Comprehension and as a new
     `comprehension_answer` Judgment Ledger entry.
3. Check the report's source digests against the previous run's.
   - **Expect**: unchanged, even though step 2 just wrote into `plan.md` — the digest excludes the
     Questmaster Record (FR-040), so Questmaster's own bookkeeping never reports itself as an
     upstream change.

## Scenario K — Pending-story collision (exercises FR-029's no-overwrite rule, added 2026-09-13d)

1. Run `/speckit-questmaster-story` for a new request in a project with no feature directory, and
   complete it so a pending story is written.
2. Without running `/speckit-specify`, run `/speckit-questmaster-story` again for an entirely
   different request.
   - **Expect**: no interview starts and nothing is written. Questmaster names the pending story's
     Quest Title and the date it was written, and requires an explicit choice — revise, consume
     via `/speckit-specify`, or discard.
3. Reply ambiguously (e.g. "yeah, whatever's easiest").
   - **Expect**: still no overwrite and still no new interview; the choice is asked again. Silence
     or ambiguity is never read as a discard.
4. Explicitly discard, then complete the second interview and run `/speckit-specify`.
   - **Expect**: the second story is the one relocated into the new feature directory as
     `story.md`, and the Specification Integrity assessment compares `spec.md` against it.

## Scenario L — Accepted-risk resolution (exercises FR-039's two resolution paths, added 2026-09-13d)

1. Reach `READY_WITH_ACCEPTED_RISK` as in Scenario E, then run `/speckit-specify`.
   - **Expect**: the accepted risk is restated ahead of the assessment's own findings, with its
     acceptance date and the developer's own words.
2. Revise `story.md` so the gap behind that acceptance is genuinely closed, then re-run
   `/speckit-questmaster-check-spec`.
   - **Expect**: the risk may be auto-resolved — but only with the specific story content that
     closes it cited as evidence, marked `resolved_by: questmaster` rather than as the developer's
     own resolution, and reported in the run's output as reopenable. It does **not** appear as a
     Judgment Ledger entry.
3. Leave a different accepted risk untouched and re-run.
   - **Expect**: it stays `outstanding` and is restated again. A risk is never closed because
     nobody mentioned it.

## Scenario I — Story stage against fixtures (exercises the automated-coverage gap, added 2026-09-13c)

Every other scenario that touches the story stage (A, A2, D, E, F) runs it as a live interview —
useful for confirming the interview and Dragon Pass behave correctly, but none of it is
automatable, and until this scenario the *automated* suite had no coverage of the story rubric's
own scoring/readiness logic at all (research.md §11). This scenario is the fixture-based
counterpart to Scenario B, but for the story stage instead of check-spec/check-plan:

1. Take a completed `story.md` from `tests/extensions/questmaster/judgment/story-fixtures/` (a
   finished document, not a transcript) with a strong problem statement, clear actor, bounded
   scope, and a non-empty Judgment Ledger.
   - **Expect**: banding it reproduces the fixture's human-assigned bands and a `READY`
     classification.
2. Take a fixture identical in every respect except an empty Judgment Ledger.
   - **Expect**: `developer_judgment` bands `ABSENT`, `no_developer_judgment_recorded` is named,
     and the classification is `NOT_READY` regardless of every other dimension's band.
3. Take a fixture with a high-scoring story but no identified primary actor.
   - **Expect**: `NOT_READY` with `primary_actor_unknown` named, matching Scenario E's manual
     result but reproducible without a live interview.

This is exactly the fixture corpus `tests/extensions/questmaster/judgment/story-fixtures/`
automates (below) — running it here manually first is how you'd hand-verify the corpus before
trusting the automated eval's agreement-rate numbers.

## Scenario J — Automated Constitution self-check (exercises the Governance tier, added 2026-09-13c)

The first thing the automated suite runs, before either other tier (research.md §11): an
independent agent — no access to whatever conversation authored `plan.md` — is given only
`.specify/memory/constitution.md` and `plan.md`, and asked to verify every row of the
Constitution Check table against the actual principle text and cited evidence.

1. Run `tests/extensions/questmaster/governance/check_constitution.sh`.
   - **Expect**: a report naming each of the 15 principles as independently CONFIRMED or
     DISPUTED, with reasoning; the suite fails if any row is disputed.
2. Deliberately edit `plan.md` to claim PASS on a principle without corresponding evidence (e.g.
   remove a cited artifact/section while leaving the PASS status).
   - **Expect**: the independent check disputes that row and the script exits non-zero — this is
     the regression test for the failure mode the governance tier exists to catch (a plan
     grading its own compliance and being believed).

## Automated coverage

`tests/extensions/questmaster/run.sh` runs all three tiers (research.md §11), matching the
upstream convention for a bundled extension's own tests (`tests/extensions/<ext-id>/`):

- **Governance** (runs first): an independent-agent re-verification of this feature's own
  Constitution Check (Scenario J) — a design whose own compliance claims are unverified is not
  worth testing further.
- **Deterministic**: config parsing/fallback, band→score arithmetic, the readiness classification
  rule (including the critical-condition override and the empty-ledger case), the pending-story
  write/relocate/consume cycle **and its collision refusal** (Scenario K), digest scope — a
  Questmaster Record edit must not change a digest while a body edit must (Scenario H2 step 3),
  accepted-risk carry-forward and auto-resolution attribution (Scenario L), comprehension-round
  progression (Scenario H2), and decision-first report ordering/capping.
- **Judgment**: two fixture corpora, both run through the real assessment logic N times, both
  reporting agreement rate against human labels and run-to-run variance against the FR-036/SC-009
  reproducibility target (90% of bands stable, score within 5 points):
  - `tests/extensions/questmaster/judgment/story-fixtures/` (Scenario I) — the story rubric and
    readiness gate on their own, closing the gap where only manual scenarios exercised the story
    stage.
  - `tests/extensions/questmaster/judgment/fixtures/` (Scenario B), including the
    faithful/drifting pair — cross-artifact Drift Classification.

## Verification Log (tasks.md T057, 2026-09-13f)

Honest record of how each scenario was actually verified in the implementation pass that built
this feature, rather than a claim that every scenario was run as a live multi-turn interview:

- **A, A2** (full/short live Socratic interview + downstream hooks) — **not run live**: a full
  multi-turn interview requires a simulated developer persona answering in real time, and doing
  that inside the same session that authored the commands would blur the line between "verifying
  the design" and "scripting a transcript to match it." Instead, every mechanism these scenarios
  exercise was verified individually and for real (see below): band scoring, readiness
  classification, the Dragon Pass's Judgment Ledger requirement, decision-first report ordering,
  and the Comprehension Checkpoint round rule.
- **B** (drifting vs. faithful quest) — **live-verified**: a genuine independent subagent (no
  session context) assessed `examples/faithful-quest/spec.md` against `story.md` and correctly
  classified every element PRESERVED/REFINED/CLARIFIED with no false UNJUSTIFIED_DRIFT. The same
  faithful/drifting pair also runs as judgment-tier fixtures 14-15 (6/7 and 7/7 elements matched
  in the T052 eval run).
- **C** (non-adopting project, byte-identical no-op) — **live-verified by construction**: after
  `specify extension add --dev`, every pre-existing `.claude/skills/speckit-*` directory and every
  file under `.specify/templates/`, `.specify/scripts/` kept its pre-install mtime; only the new
  `speckit-questmaster-*`/`speckit-quest-*` skill directories were added.
- **D** (malformed config) — **live-verified**: ran `qm-config.sh` against a deliberately corrupt
  file; got a one-line stderr warning, exit 0, and full documented defaults (10 dimensions,
  threshold 70) on stdout.
- **E** (high score, unmet critical condition) — **live-verified**: ran `qm-readiness.sh` with
  score 92 and `primary_actor_unknown` unmet — result `NOT_READY` despite the score clearing
  threshold. The accept-risk-requires-justification half is covered by
  `test_readiness_gate.sh` (deterministic, passing).
- **F** (empty Judgment Ledger) — **live-verified**: `qm-readiness.sh` against a story stub with
  no Judgment Ledger correctly forced `no_developer_judgment_recorded` and `NOT_READY`; the same
  check against `examples/faithful-quest/story.md` (4 real ledger entries) correctly did not.
  This check also caught and fixed a real bug: `qm-record.sh`'s `list-ledger` regex lacked the
  `re.S` flag needed to parse a developer-words quote that wraps across physical lines, so it
  silently reported every real (word-wrapped) ledger as empty until fixed.
- **G** (assessment independence) — **live-verified**: dispatched a real fresh subagent via the
  Agent tool with only `story.md`/`spec.md` file paths and no conversation context, and it produced
  a correct, independent Specification Integrity assessment (this is the same run cited under B).
- **H, H2** (Comprehension Checkpoint decline / re-run round rule / digest exclusion) — covered by
  `test_comprehension_rounds.sh` and `test_digest_scope.sh` (deterministic, passing); not
  separately live-run as an interview.
- **I** (story fixtures reproduce human labels) — **live-run**: this scenario *is* the judgment
  tier's story-fixture corpus; T052's run measured 90% readiness-status agreement and 86% band
  stability across repeated runs (see plan.md row VI for the full numbers and the one dimension
  identified as the source of instability).
- **J** (governance self-check + regression) — **live-verified, both halves**: the real check
  passed 15/15 CONFIRMED against the actual `plan.md`; a deliberate tamper (replacing row XIV's
  evidence with a bare, uncited assertion) was then independently DISPUTED by the same script,
  which also correctly flagged row XII's "15/15 CONFIRMED" claim as contradicted by the tampered
  row still present in the same table — exit code 1, as required. `plan.md` was restored
  immediately afterward and reconfirmed against its correct, T053-updated content.
- **K** (pending-story collision) — **live-verified**: `qm-pending.sh write` on a stub project
  root refused a second write while the first was unclaimed (exit 2), left the original title
  intact, and only succeeded after an explicit `discard`.
- **L** (accepted-risk resolution) — covered by `test_accepted_risk.sh` (deterministic, passing),
  including the evidence-required guard on `resolved_by: questmaster` auto-resolution fixed
  earlier in this implementation pass; not separately live-run as a full story-then-revise cycle.
