---

description: "Task list for Questmaster — Quest Layer for the Spec Kit Lifecycle"
---

# Tasks: Questmaster — Quest Layer for the Spec Kit Lifecycle

**Input**: Design documents from `/specs/001-questmaster-quest-layer/`

**Prerequisites**: plan.md (revised 2026-09-13d), spec.md (revised 2026-09-13 clarification pass), research.md, data-model.md, contracts/

**Tests**: Included. Tests are not optional for this feature — Constitution Principle XII ("Test the Methodology") explicitly rejects deterministic-only testing as sufficient for judgment logic, plan.md's Technical Context commits to three named test tiers, and Constitution Check rows VI and XII are recorded as **CONDITIONAL PASS** that convert to a clean PASS only by running them and quoting real numbers.

**Organization**: Tasks are grouped by user story. Each story's phase is independently implementable and testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: `[US1]` / `[US2]` / `[US3]`, mapping to spec.md's user stories
- Exact file paths are given in every task

## Path Conventions

Two distinct trees, per plan.md § Project Structure:

- **Extension source** (what this feature builds): `extensions/questmaster/`
- **Tests**: `tests/extensions/questmaster/`
- **Installed runtime state** (`.claude/skills/…`, `.specify/extensions/questmaster/…`) is produced by `specify extension add --dev`, never hand-authored. No task writes into those paths directly.

Neither `extensions/` nor `tests/` exists in this repository yet; this feature creates both.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the two new trees and the manifest everything else is declared in.

- [X] T001 Create the extension source and test tree skeletons: `extensions/questmaster/{commands,config,templates,scripts,examples/faithful-quest,examples/drifting-quest}/` and `tests/extensions/questmaster/{governance,deterministic,judgment/{story-fixtures,fixtures,expected}}/`
- [X] T002 Create `extensions/questmaster/extension.yml` as the live manifest, from `specs/001-questmaster-quest-layer/contracts/extension.yml` (schema_version, extension block, `requires.speckit_version: ">=1.0.0"`, three `provides.commands` entries with their aliases, `provides.config`, two `provides.templates` entries — leave the `hooks:` block for T036/T045)
- [X] T003 [P] Create the dependency-free test runner `tests/extensions/questmaster/run.sh` that runs all three tiers with **governance first** (research.md §11), exits non-zero on any tier failure, and requires no framework beyond `sh`/`jq`
- [X] T004 Resolve where the deterministic helper scripts (T006–T009) install to, and record the decision in `extensions/questmaster/README.md`: check whether `ExtensionManager` supports a `provides.scripts`-style entry; if it does, declare the `scripts/` directory in `extensions/questmaster/extension.yml`; if it does not, inline each helper as a heredoc inside the command skill that uses it and keep `extensions/questmaster/scripts/` as the tested source of truth. **This is an open gap in plan.md** — its Project Structure tree has no home for the `sh`/`jq` helpers its Technical Context requires, and `contracts/extension.yml` declares no scripts entry. Do not start T006 before this is decided

**Checkpoint**: Both trees exist, the manifest parses, and the helper-script delivery path is decided.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The config, the deterministic arithmetic, and the shared record/report machinery every user story depends on. Governance runs first because a design whose own compliance claims are unverified is not worth testing further (research.md §11).

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T005 Create `extensions/questmaster/config/questmaster-config.template.yml` from `specs/001-questmaster-quest-layer/contracts/questmaster-config.yml`: `band_multipliers` (0.00/0.33/0.67/1.00), `story_rubric` (10 dimensions summing to 100, `readiness_threshold: 70`, the eight `critical_conditions` including `no_developer_judgment_recorded`), `specification_integrity_rubric` (7 dimensions), `plan_integrity_rubric` (8 dimensions), and per-dimension anchored band definitions for all 25 dimensions (FR-024, FR-036)
- [X] T006 Implement the config loader and validator in `extensions/questmaster/scripts/qm-config.sh`: read through `ConfigManager`'s layering (project file, gitignored `local-config.yml`, `SPECKIT_QUESTMASTER_<KEY>` env vars), then apply Questmaster's own validation — weights sum to 100 and band anchors present for every dimension — falling back to documented defaults **for the affected rubric only** with a one-line warning, never failing the assessment (data-model.md § Validation rule)
- [X] T007 Implement deterministic band→score arithmetic in `extensions/questmaster/scripts/qm-score.sh`: `dimension_score = round(weight × multiplier)`, `overall_score = sum(dimension_scores)` clamped to 0–100. The LLM assigns bands; this script does every sum (plan.md Technical Context — arithmetic MUST NOT be left to the model)
- [X] T008 Implement the source-digest helper in `extensions/questmaster/scripts/qm-digest.sh`: `sha256` over an artifact's content with the `## Questmaster Record` section removed — from that heading to the next same-level heading or EOF — normalized only by stripping a trailing newline (FR-040, data-model.md § Source digest scope)
- [X] T009 Implement the Questmaster Record reader/writer in `extensions/questmaster/scripts/qm-record.sh`: read and append the three subsections (Judgment Ledger, Comprehension, Decisions) in place in `story.md`/`spec.md`/`plan.md`, with the Decision entry fields `status`/`resolved_by`/`resolved_date`/`resolution_evidence` and the Judgment Ledger fields `date`/`stage`/`kind`/`developer_words`/`effect` (FR-027, FR-035, FR-039)
- [X] T010 Create the shared decision-first report skeleton `extensions/questmaster/templates/integrity-report-template.md` in the normative section order from data-model.md § Integrity Assessment Report: header with assessment context label and source digests, Decisions for you (≤3), Outstanding accepted risk, Integrity bands, Drift Classification summary, Findings, Appendix, Advisory note (FR-038)
- [X] T011 Implement the governance tier in `tests/extensions/questmaster/governance/check_constitution.sh`: spawn an independent agent with no access to the authoring session, given only `.specify/memory/constitution.md` and the artifact under check, verify every Constitution Check row's claimed status against the principle text and cited evidence, and fail the suite on any unsupported or overstated row (research.md §11, Constitution XIII applied reflexively)
- [X] T012 [P] Write `tests/extensions/questmaster/deterministic/test_config_defaults.sh` — missing file, malformed YAML, and a rubric whose weights do not sum to 100 each fall back to defaults for that rubric only, emit exactly one warning, and do not fail the run (covers T006)
- [X] T013 [P] Write `tests/extensions/questmaster/deterministic/test_band_score_arithmetic.sh` — every band/weight pair produces its expected contribution, an all-`STRONG` rubric totals 100, an all-`ABSENT` rubric totals 0, and repeated runs are byte-identical (covers T007, FR-036)
- [X] T014 [P] Write `tests/extensions/questmaster/deterministic/test_digest_scope.sh` — editing an artifact's `## Questmaster Record` does **not** change its digest, editing the body **does**, and an artifact with no Questmaster Record digests identically before and after one is appended (covers T008, FR-040)

**Checkpoint**: Config resolves with fallback, all arithmetic is deterministic and tested, the record and report shapes exist, and the governance tier can fail a build. User stories can now begin in parallel.

---

## Phase 3: User Story 1 - Turn a vague request into a bounded, challenged, scored Quest Story (Priority: P1) 🎯 MVP

**Goal**: `/speckit-questmaster-story` sizes a quest, interviews Socratically, runs a Dragon Pass, writes a structured `story.md` (or a pending story), bands it against the ten-dimension rubric, and classifies readiness by named critical conditions rather than score alone.

**Independent Test**: Run `/speckit-questmaster-story` against a deliberately vague one-sentence request in a repository with no feature directory. Confirm (a) a Short or Full path is chosen and stated with a reason, (b) clarifying questions come before any document, (c) the interview stops within the stated budget, (d) 2–3 (Short) or 3–5 (Full) story-specific Dragon challenges are raised and every response recorded, (e) `.specify/extensions/questmaster/pending-story.md` is written with all 9 core sections and every inapplicable extended section marked N/A with a reason, (f) any supplied solution is recorded separately with a Solution-Neutrality Assessment, and (g) a banded Story Integrity Assessment with per-dimension evidence and a named readiness classification is shown. Delivers value with no other phase built: a better-interrogated, solution-neutral problem statement.

### Tests for User Story 1 ⚠️

> Write these first and confirm they fail before implementing T017–T025.

- [X] T015 [P] [US1] Write `tests/extensions/questmaster/deterministic/test_readiness_gate.sh` — the FR-012 classification rule: any unmet critical condition forces `NOT_READY` regardless of score (including a 95/100 story with an unidentified primary actor), score ≥ threshold with no unmet condition gives `READY`, below threshold gives `NEEDS_CLARIFICATION`, `READY_WITH_ACCEPTED_RISK` is reachable only via a recorded non-empty developer justification, and an empty Judgment Ledger trips `no_developer_judgment_recorded`
- [X] T016 [P] [US1] Write `tests/extensions/questmaster/deterministic/test_pending_story.sh` — the write/relocate/consume cycle as pure file operations, **plus the collision case**: with an unclaimed pending story present, a new unrelated request never overwrites it, and silence or an ambiguous reply is not treated as a discard (FR-029, replaces the retired `test_feature_reuse.sh`)

### Implementation for User Story 1

- [X] T017 [P] [US1] Create `extensions/questmaster/templates/story-template.md` — the 17-section skeleton from data-model.md § Quest Story Structure: 9 core, 4 extended, 4 recorded (Dragon's Questions, Questmaster Record, Story Readiness Assessment, Story Integrity Assessment), each carrying its "complete when" guidance as a comment (FR-003)
- [X] T018 [US1] Implement the readiness classifier in `extensions/questmaster/scripts/qm-readiness.sh` — data-model.md's four-step classification rule over `unmet_critical_conditions`, `overall_score`, and `readiness_threshold`, with `READY_WITH_ACCEPTED_RISK` never a direct output of scoring (FR-012, FR-013); makes T015 pass
- [X] T019 [US1] Create `extensions/questmaster/commands/speckit.questmaster.story.md` with its skill frontmatter and step 1 state resolution per `contracts/quest-story.md`: revise an existing `<feature-dir>/story.md` in place preserving its Questmaster Record; on an unclaimed pending story **refuse to overwrite**, name its Quest Title and write date, and require an explicit revise / consume / discard choice; otherwise start a new story and allocate no directory, branch, or number (FR-029, FR-042); makes T016 pass
- [X] T020 [US1] Add step 2 quest sizing to `extensions/questmaster/commands/speckit.questmaster.story.md`: choose Short (~6 questions, <5 min) or Full (~12 questions, <15 min), state the choice and a one-line reason, honour a developer override at any point, allow Short→Full escalation mid-interview with a stated reason, and state that the budget covers the whole developer-facing stage including step 6's Dragon Pass (FR-033)
- [X] T021 [US1] Add steps 3–5 to `extensions/questmaster/commands/speckit.questmaster.story.md`: the Socratic interview over core sections (extended per path), keeping Problem/Need/Outcome/Requirement/Solution distinct, stopping on sufficient evidence rather than a fixed count; surfacing contradictions for the developer to resolve rather than silently picking one; and the Solution-Neutrality Assessment classifying every part of a supplied proposal as requirement / implementation detail / assumption / unnecessary constraint, never blocking when the developer resists the separation (FR-001, FR-002, FR-004–FR-009)
- [X] T022 [US1] Add step 6 Dragon Pass to `extensions/questmaster/commands/speckit.questmaster.story.md`: 2–3 challenges on a Short Quest and 3–5 on a Full Quest, counted inside the FR-033 budget, each specific to this story's own content and tagged with a data-model.md category, each response recorded verbatim with its `disposition` — a dismissal recorded as dismissed, never dropped — and never rewriting the story to reflect an unanswered challenge (FR-034, SC-011)
- [X] T023 [US1] Add step 7 story writing to `extensions/questmaster/commands/speckit.questmaster.story.md`: write `<feature-dir>/story.md` when a feature directory exists, otherwise `.specify/extensions/questmaster/pending-story.md`; all 9 core sections present, extended sections per the chosen path, any genuinely inapplicable section marked N/A with a one-line reason rather than omitted or padded (FR-003, FR-029)
- [X] T024 [US1] Add step 8 scoring to `extensions/questmaster/commands/speckit.questmaster.story.md`: band all ten dimensions with cited evidence, compute the score via `qm-score.sh` rather than by the model, refuse a band above `ABSENT` for a section that merely exists, and band `developer_judgment` from the Judgment Ledger alone; write each Dragon response and every developer-originated contribution as a Judgment Ledger entry via `qm-record.sh`, applying its exclusion rule — approving AI-authored content is not an entry (FR-010, FR-011, FR-035, FR-036)
- [X] T025 [US1] Add steps 9–11 to `extensions/questmaster/commands/speckit.questmaster.story.md`: classify readiness via `qm-readiness.sh`; when not `READY`, state specifically what is unmet and require an explicit revise-or-accept choice where accepting demands a justification the developer types themselves — a menu selection, generated text, empty string, or silence leaves the status unchanged — recording a valid acceptance as a Decision with `status: outstanding` and reclassifying to `READY_WITH_ACCEPTED_RISK`; when `READY`, state the story is ready for `/speckit-specify` (FR-012, FR-014, FR-022)

**Checkpoint**: User Story 1 is fully functional and independently testable. `/speckit-questmaster-story` delivers value with no assessment command built.

---

## Phase 4: User Story 2 - Assess Specification Integrity between Story and Specification (Priority: P2)

**Goal**: `/speckit-questmaster-check-spec` relocates any pending story, bands `spec.md` against `story.md` across seven dimensions in an independent context, applies the six-way Drift Classification to every element, and reports decision-first with carried-forward accepted risk.

**Independent Test**: Take a `story.md`/`spec.md` pair where the spec is faithful — confirm a high banded result, every requirement `PRESERVED`/`REFINED`/`CLARIFIED`, and a worklist that explicitly states no decision is required. Then take a pair where the spec adds unsupported scope — confirm those are classified `DISCOVERED`/`ACCEPTED_SCOPE_CHANGE`/`UNJUSTIFIED_DRIFT` as appropriate, at most three surface up front with the remainder counted and named in one line, each carries a specific developer question, and `spec-integrity.md` holds the complete per-element table. Requires US1's `story.md` as input but is otherwise independent of US3.

### Tests for User Story 2 ⚠️

- [X] T026 [P] [US2] Write `tests/extensions/questmaster/deterministic/test_report_ordering.sh` — the normative section order (decisions → outstanding risk → bands → findings), the ≤3-item worklist cap with the remainder counted and named, the explicit "No decision required." line when none qualify, and `PRESERVED`/`REFINED`/`CLARIFIED` aggregated in the presented output while the persisted report keeps every element (FR-038)
- [X] T027 [P] [US2] Write `tests/extensions/questmaster/deterministic/test_accepted_risk.sh` — an `outstanding` Decision is restated at every later stage with its acceptance date and the developer's own reason; an auto-resolution without `resolution_evidence` is rejected; a recorded auto-resolution carries `resolved_by: questmaster`, never `developer`, and is **not** written as a Judgment Ledger entry (FR-039)

### Implementation for User Story 2

- [X] T028 [P] [US2] Create `extensions/questmaster/templates/spec-template-pending-story-addendum.md` — the `strategy: prepend` addendum that directs `/speckit-specify` to take `.specify/extensions/questmaster/pending-story.md` as primary input when one exists, and renders as nothing when none does; template content only, no control-flow change to any Spec Kit file (FR-029, FR-042)
- [X] T029 [US2] Create `extensions/questmaster/commands/speckit.questmaster.check-spec.md` with its frontmatter and the FR-037 independence wrapper: invoke the assessment portion via Claude Code's Agent tool so the authoring conversation is out of scope, and where no such mechanism is available still run but label every output `SELF-ASSESSED` in both the response and the persisted report, with that label not suppressible by configuration
- [X] T030 [US2] Add steps 1–3 to `extensions/questmaster/commands/speckit.questmaster.check-spec.md`: relocate a pending story into the new feature directory as `story.md` when the directory has none; on a hook-triggered invocation with no story, exit immediately writing and printing nothing; on an explicit invocation with no story, state plainly that assessment could not be performed and how to run `/speckit-questmaster-story` (FR-025, FR-026, FR-029)
- [X] T031 [US2] Add step 4 to `extensions/questmaster/commands/speckit.questmaster.check-spec.md`: compute `story.md` and `spec.md` digests via `qm-digest.sh` for the persisted report, and on a mismatch with the previous report state which upstream artifact changed and that previous findings were based on a different version (FR-040)
- [X] T032 [US2] Add step 5 to `extensions/questmaster/commands/speckit.questmaster.check-spec.md`: read `story.md`'s Decisions for every `outstanding` entry; where the condition still holds, restate it with its date and the developer's reason ahead of this run's own findings; where it no longer holds, auto-resolve only with the specific artifact content cited as `resolution_evidence`, attributed `resolved_by: questmaster`, never as a Judgment Ledger entry, and reported as reopenable — absence of an objection is never evidence, and when in doubt it stays outstanding (FR-039); makes T027 pass
- [X] T033 [US2] Add step 6 to `extensions/questmaster/commands/speckit.questmaster.check-spec.md`: band all seven `specification_integrity_rubric` dimensions with cited evidence per band, compute the score via `qm-score.sh`, and record the assessment context as `INDEPENDENT` or `SELF-ASSESSED` (FR-015, FR-036, FR-037)
- [X] T034 [US2] Add steps 7–8 to `extensions/questmaster/commands/speckit.questmaster.check-spec.md`: assign exactly one Drift Classification to every requirement, scope item, and assumption; consult `story.md`'s Decisions before ever using `ACCEPTED_SCOPE_CHANGE` and otherwise classify out-of-scope elements `UNJUSTIFIED_DRIFT`; never classify content as drift merely for not being verbatim in the story; compare by underlying intent rather than section titles or wording; and produce the full eight-field finding for every `DISCOVERED`/`ACCEPTED_SCOPE_CHANGE`/`UNJUSTIFIED_DRIFT` element (FR-017–FR-020)
- [X] T035 [US2] Add steps 9–11 to `extensions/questmaster/commands/speckit.questmaster.check-spec.md`: assemble decision-first from `integrity-report-template.md`, write/overwrite `<feature-dir>/spec-integrity.md` with the digests and context label, present the same content in the same order in the response, and never auto-modify, block, or reject `spec.md` (FR-022, FR-031, FR-038); makes T026 pass
- [X] T036 [US2] Register the `after_specify` hook in `extensions/questmaster/extension.yml` — `command: speckit.questmaster.check-spec`, `optional: false`, no `condition:` field (research.md §4: a conditioned hook never fires from an interactive agent session in this Spec Kit version) (FR-030)
- [X] T058 [US2] Add step 12 to `extensions/questmaster/commands/speckit.questmaster.check-spec.md`: where the Decision Worklist is non-empty, elicit a response to its highest-severity item — resolve, accept with a developer-written justification recorded as a Decision, or explicitly defer — record it as a Judgment Ledger entry, record a deferral as a deferral and a non-response as unanswered and carried forward, skip the step entirely when no decision is required, and never block `/speckit-plan` (FR-043, SC-012)
- [X] T059 [P] [US2] Write `tests/extensions/questmaster/deterministic/test_worklist_response.sh` — a non-empty worklist records a response, a deferral, or an explicit unanswered marker for its top item; an empty worklist elicits nothing and writes nothing; and no path prevents proceeding to the next stage (FR-043)

**Checkpoint**: User Stories 1 and 2 both work independently. Story → Specification integrity is proven end to end.

---

## Phase 5: User Story 3 - Comprehend and assess the Plan (Priority: P3)

**Goal**: `/speckit-questmaster-check-plan` runs the Comprehension Checkpoint before showing anything, then bands `plan.md` against both `story.md` and `spec.md` across eight dimensions, cross-referencing its own findings against the developer's recorded predictions.

**Independent Test**: Supply a `story.md` + `spec.md` + `plan.md` set where the plan is proportionate and preserves every story constraint — confirm the three checkpoint questions are asked before any assessment content appears, the answers are recorded verbatim in `plan.md`'s Questmaster Record, and the assessment is clean. Re-run it and confirm exactly one further, previously unasked question is posed and the earlier answers are restated rather than re-asked. Then supply a set that adds unrequested services and drops a story constraint — confirm those are classified as drift, a justified complex design is not flagged merely for being complex, and a sound-but-unreadable plan bands `legibility` `WEAK`/`ABSENT` while banding well elsewhere.

### Tests for User Story 3 ⚠️

- [X] T037 [P] [US3] Write `tests/extensions/questmaster/deterministic/test_comprehension_rounds.sh` — Round 1 records exactly three questions; each subsequent run appends exactly one round holding exactly one question that differs from every question already recorded for that plan; a decline is recorded as `DECLINED` with `outcome: declined` rather than as an absence; and an exhausted question supply asks nothing rather than padding (FR-041)

### Implementation for User Story 3

- [X] T038 [US3] Create `extensions/questmaster/commands/speckit.questmaster.check-plan.md` with its frontmatter, the same Agent-tool independence wrapper and `SELF-ASSESSED` fallback as T029 applied to the assessment portion only (step 3's checkpoint is direct developer interaction and is explicitly not subject to FR-037), and steps 1–2: exit silently when hook-triggered with no `story.md`, explain when explicitly invoked, and require `story.md` and `spec.md` alongside `plan.md` (FR-025, FR-026, FR-037)
- [X] T039 [US3] Add step 3 to `extensions/questmaster/commands/speckit.questmaster.check-plan.md`: read the recorded Comprehension rounds first; with none recorded ask exactly three (most likely wrong, what they would cut, what breaks first); with one or more recorded restate those answers and ask exactly one further question differing from every question already recorded, drawn from the non-derivable families in data-model.md, saying so and asking nothing if the supply is exhausted. Record answers verbatim under a new round heading via `qm-record.sh`, add each as a `comprehension_answer` Judgment Ledger entry, permit a decline and record it as a decline, never answer on the developer's behalf, and never block (FR-041, SC-013); makes T037 pass
- [X] T040 [US3] Add step 4 to `extensions/questmaster/commands/speckit.questmaster.check-plan.md`: digest `story.md`, `spec.md`, and `plan.md` via `qm-digest.sh` — the Questmaster Record exclusion is what stops step 3's own writes from marking this plan changed — and apply the same still-holds / auto-resolve accepted-risk judgment as check-spec's step 5 (FR-039, FR-040)
- [X] T041 [US3] Add step 5 to `extensions/questmaster/commands/speckit.questmaster.check-plan.md`: band all eight `plan_integrity_rubric` dimensions against both `story.md` and `spec.md` with cited evidence, banding `intent_preservation` independently of technical quality so a sound plan that abandons the story's outcome cannot band well overall, and `legibility` independently of technical correctness (FR-016, FR-036)
- [X] T042 [US3] Add steps 6–9 to `extensions/questmaster/commands/speckit.questmaster.check-plan.md`: assign exactly one Drift Classification to every component, service, and abstraction, consulting both artifacts' Decisions before `ACCEPTED_SCOPE_CHANGE`; band `constraint_preservation` separately so a story-level constraint dropped in technical design is flagged even where `spec.md` carried it forward; never flag or recommend simplifying an element solely for complexity traceable to a stated requirement, constraint, or risk; and produce a full finding for every `DISCOVERED`/`ACCEPTED_SCOPE_CHANGE`/`UNJUSTIFIED_DRIFT` element (FR-017–FR-021)
- [X] T043 [US3] Add step 10 to `extensions/questmaster/commands/speckit.questmaster.check-plan.md`: state explicitly where this assessment's findings agree or disagree with the developer's recorded predictions from **every** round, not only the current run's (FR-041, data-model.md § Plan Integrity)
- [X] T044 [US3] Add steps 11–13 to `extensions/questmaster/commands/speckit.questmaster.check-plan.md`: assemble decision-first from `integrity-report-template.md`, write/overwrite `<feature-dir>/plan-integrity.md` with digests and context label, present the same content in the same order, and remain advisory throughout — never blocking `/speckit-tasks` (FR-022, FR-031, FR-038)
- [X] T045 [US3] Register the `after_plan` hook in `extensions/questmaster/extension.yml` — `command: speckit.questmaster.check-plan`, `optional: false`, no `condition:` field (FR-030)

**Checkpoint**: All three user stories are independently functional. The Story → Spec → Plan chain is complete.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: The examples, fixture corpora, and evaluation runs that convert Constitution rows VI and XII from CONDITIONAL PASS to a clean PASS, plus end-to-end install verification and documentation.

- [X] T046 [P] Author the faithful-quest example in `extensions/questmaster/examples/faithful-quest/{story.md,spec.md}` — legitimate elaborations that must classify `PRESERVED`/`REFINED`/`CLARIFIED` (SC-005)
- [X] T047 [P] Author the drifting-quest example in `extensions/questmaster/examples/drifting-quest/{story.md,spec.md,plan.md}` — unsupported additions that must classify `UNJUSTIFIED_DRIFT`, plus at least one carrying a matching Decision that must classify `ACCEPTED_SCOPE_CHANGE` (SC-005)
- [X] T048 [P] Build the story-rubric corpus in `tests/extensions/questmaster/judgment/story-fixtures/` — 8–10 complete `story.md` files (finished documents, not interview transcripts), including at least one fixture per critical condition and specifically one with an empty Judgment Ledger (research.md §11)
- [X] T049 [P] Build the cross-artifact corpus in `tests/extensions/questmaster/judgment/fixtures/` — 15–20 labelled `story.md`/`spec.md` and `story.md`/`spec.md`/`plan.md` sets, with T046/T047's pair included as a subset rather than duplicated
- [X] T050 Write the human labels in `tests/extensions/questmaster/judgment/expected/` — expected band per dimension and expected readiness classification for every story fixture, expected Drift Classification per element and expected band ranges per dimension for every cross-artifact fixture
- [X] T051 Implement `tests/extensions/questmaster/judgment/eval.sh` — run real assessments N times per fixture across both corpora and report agreement rate against the human labels (SC-016 target: ≥80% per corpus) plus run-to-run band/score variance against the FR-036 target (90% of bands stable, score within 5 points)
- [X] T052 Run `tests/extensions/questmaster/run.sh` end to end and fix every failure across all three tiers
- [X] T053 Update the Constitution Check rows VI and XII in `specs/001-questmaster-quest-layer/plan.md` with the actual agreement-rate and variance numbers from T052, converting both CONDITIONAL PASS rows to a clean PASS — or, if the measured numbers miss the FR-036 or SC-016 target, coarsen the rubric or sharpen the band anchors per spec.md's stated Assumption rather than relaxing either requirement
- [X] T054 Install end to end with `specify extension add --dev ./extensions/questmaster` and verify the rendered runtime state: three `.claude/skills/speckit-questmaster-*/SKILL.md` files, `.specify/extensions/questmaster/questmaster-config.yml` materialized from the template, and a `.specify/extensions.yml` whose hook entries match `specs/001-questmaster-quest-layer/contracts/extensions.yml`
- [X] T055 Verify FR-042/SC-006 by construction: confirm `specify extension add --dev` changed zero bytes of any existing Spec Kit command, skill, or script file, and that a feature with no `story.md` and no pending story sees standard Spec Kit commands behave exactly as before with no Questmaster-related output
- [X] T056 [P] Update `questmaster.md` at the repository root and `extensions/questmaster/README.md` to document the delivered methodology: the three commands and their real invocation names, the band-based scoring model, the Judgment Ledger and Dragon Pass, the Comprehension Checkpoint round rule, the six-way Drift Classification, and how to retune the rubric through configuration alone (SC-004)
- [X] T057 Run every manual scenario in `specs/001-questmaster-quest-layer/quickstart.md` (A, A2, B, C, D, E, F, G, H, H2, I, J, K, L) and record the outcome of each

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies. T004 gates T006–T009
- **Foundational (Phase 2)**: depends on Setup — **blocks all user stories**
- **User Story 1 (Phase 3)**: depends on Foundational only
- **User Story 2 (Phase 4)**: depends on Foundational only; needs a `story.md` as *input* at runtime, which US1 produces, but nothing in its implementation depends on US1's files
- **User Story 3 (Phase 5)**: depends on Foundational only; needs `story.md` + `spec.md` as runtime input
- **Polish (Phase 6)**: T046–T051 depend on the stories whose logic they exercise; T052–T057 depend on all three stories

### Within Each User Story

- Tests (T015/T016, T026/T027, T037) are written first and must fail before their implementation tasks
- Shared helper scripts before the command that calls them
- Within a single command file, steps are added in contract order — those tasks are sequential by necessity (same file), which is why almost none of them carry `[P]`

### Parallel Opportunities

- T012, T013, T014 (three different deterministic test files) run together once T006–T008 exist
- T015, T016, T017 run together at the start of US1
- T026, T027, T028 run together at the start of US2; T059 joins them (a fourth separate file)
- Once Phase 2 completes, US1, US2, and US3 can be developed in parallel by different people — they touch three disjoint command files and share only the Phase 2 helpers
- T046, T047, T048, T049 (four separate fixture/example trees) run together
- T056 runs alongside any Phase 6 task

## Parallel Example: User Story 1

```bash
# Launch the tests and the template together:
Task: "Write tests/extensions/questmaster/deterministic/test_readiness_gate.sh"
Task: "Write tests/extensions/questmaster/deterministic/test_pending_story.sh"
Task: "Create extensions/questmaster/templates/story-template.md"

# Then T018–T025 proceed sequentially: T019–T025 all edit the same command file.
```

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1 Setup (T001–T004)
2. Phase 2 Foundational (T005–T014) — blocks everything
3. Phase 3 User Story 1 (T015–T025)
4. **STOP and VALIDATE**: run the US1 independent test above against a vague one-line request
5. This is a shippable increment: Socratic problem framing with a banded, readiness-classified story, with no assessment machinery at all

### Incremental Delivery

1. Setup + Foundational → helpers, config, and the governance gate exist
2. + US1 → `/speckit-questmaster-story` (**MVP**)
3. + US2 → Specification Integrity, the first proof that later artifacts can be checked against earlier intent
4. + US3 → Comprehension Checkpoint and Plan Integrity
5. + Polish → fixture corpora and the measured numbers that clear Constitution VI and XII

## Notes

- `[P]` means a different file with no dependency on an incomplete task
- The three command files are each built by a sequence of same-file tasks; this is deliberate — the contracts define ordered steps and splitting them across files would lose that order
- Nothing in this feature writes into `.claude/skills/` or `.specify/` by hand. Those paths are outputs of `specify extension add --dev` (T054), and hand-authoring them would defeat the guarantee FR-042 relies on
- **Open gap carried from plan.md** (T004): the plan's Technical Context requires deterministic `sh`/`jq` helpers but its Project Structure tree gives them no home and `contracts/extension.yml` declares no scripts entry. T004 resolves this before any helper is written
- **T058 and T059 belong to Phase 4 despite their numbers.** They were added by the 2026-09-13 `/speckit-analyze` remediation (FR-043) and appended rather than inserted at T037, because inserting would have renumbered 22 downstream tasks and every cross-reference in the Dependencies section — a botched renumber is a worse outcome than two out-of-position IDs. Phase membership, not ID order, drives execution
- Commit after each task or logical group; stop at any checkpoint to validate a story independently
