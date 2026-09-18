# Feature Specification: Questmaster — Quest Layer for the Spec Kit Lifecycle

**Feature Branch**: `001-questmaster-quest-layer`

**Created**: 2026-09-12

**Last Revised**: 2026-09-13 (Session 2026-09-13b — mechanism-correction revision; clarification pass same day, see Clarifications → Session 2026-09-13)

**Status**: Draft

**Input**: User description: "Build Questmaster, a Spec Kit preset/extension concept that adds a playful but rigorous \"quest\" layer to an AI-assisted software development lifecycle. The project is intended primarily for Claude Code + GitHub Spec Kit, although the design should avoid unnecessary coupling to Claude Code where practical. Questmaster turns software development into a guided quest, layering problem understanding, traceability, assessment, and narrative on top of the existing Spec Kit workflow (specify → clarify → plan → checklist → tasks → analyze → implement → converge). The central principle: before asking AI what to build, establish what problem is actually being solved, then continuously assess whether the specification, plan, implementation, and final result remain faithful to that original intent. The most important new command, `/quest.story`, is a \"Storyteller\" stage that runs before `/speckit.specify`: it Socratically explores a vague feature request (problem, who's affected, desired outcome, why it matters, evidence, assumptions, constraints, non-goals, unknowns, potential solution bias) without immediately jumping to a specification, stopping once there is enough evidence, and writes a `story.md` artifact alongside the feature's Spec Kit artifacts. The story is scored 0-100 against a transparent, configurable rubric (problem clarity 20, user/customer clarity 15, desired outcome 20, evidence/motivation 15, constraints 10, assumptions 10, unknowns 10) with evidence for the score, not just a number; 70+ is normally \"ready\" for `/speckit.specify` but the threshold is configurable, and a low score prompts the developer to continue, revise, or proceed deliberately. The resulting `spec.md` must be assessable against `story.md` for problem fidelity, desired-outcome fidelity, user/customer coverage, success-criteria coverage, constraint coverage, non-goal preservation, unsupported scope, unsupported assumptions, and traceability — explicitly flagging \"Quest Drift\": behaviour, scope, architecture, assumptions, or complexity introduced in a later artifact that cannot reasonably be justified from the preceding artifact, while distinguishing legitimate refinement from unjustified scope expansion rather than mechanically rejecting anything not verbatim in the story. `plan.md` must similarly be assessed against both `story.md` and `spec.md` for story fidelity, specification coverage, architectural appropriateness, complexity, risk management, test strategy, technical constraint coverage, unnecessary scope, and traceability, identifying technical decisions that cannot be justified by the story or spec. \"Quest Integrity\" represents how faithfully original intent survives across Story → Specification → Plan → Tasks → Implementation → Final Review, tracked as multidimensional scores (e.g. intent, requirements, architecture, verification, risk, complexity, traceability, knowledge/documentation) summarized only at the end, not collapsed internally. Quest Drift findings must explain what changed, where it appeared, which artifact introduced it, why it appears unsupported, whether it may be legitimate refinement, and what question the developer should answer — the system must not auto-simplify complex designs, only provoke engineering judgment. Light fantasy/RPG language (Quest, Storyteller, Architect, Seer, Tester, Dragon, Judge, Quest Integrity, Quest Drift, monsters such as Complexity Hydra/Schema Serpent/Documentation Ghost/Test Coverage Goblin/Legacy Zombie, XP, Victory) should make the workflow engaging without becoming frivolous or the focus of v1. Questmaster must reward engineering judgment (understanding the problem, challenging assumptions, identifying ambiguity, validating AI output, detecting unnecessary complexity, maintaining traceability, questioning unexpected changes) and must not reward volume/speed of AI-generated output or blind acceptance of AI recommendations. It should use Spec Kit's existing preset/extension/override/template/script mechanisms rather than forking Spec Kit, using the smallest appropriate mechanism and preserving normal Spec Kit commands and behaviour. Desired flow: `/quest.story` → `story.md`; `/speckit.specify` → `spec.md` → Quest Integrity assessment; `/speckit.plan` → `plan.md` → Quest Integrity assessment; later phases (not in v1) add `/quest.review` and `/quest.complete`. Initial scope is limited to `/quest.story`, `story.md`, story scoring, story→spec alignment, spec scoring, spec→plan alignment, plan scoring, Quest Drift detection, a reusable scoring rubric/configuration, and documentation — explicitly excluding a web UI, database, multiplayer, persistent XP, elaborate graphics, external SaaS integrations, and automated developer performance measurement in v1. The system must be deterministic where practical, transparent, evidence-based, explainable, configurable, resistant to score gaming, useful to experienced engineers, and lightweight — scores must always read like \"87/100 because X, Y and Z\", never a bare number. Deliverables: `story.md` template, story/spec/plan scoring rubrics, Quest Drift rules, `/quest.story`, appropriate Spec Kit command/template overrides, tests for scoring and traceability logic, methodology documentation, and examples of a faithful quest and a drifting quest. The current repository and installed Spec Kit version/structure should be inspected and treated as the source of truth rather than assumed."

## Revision Note (Session 2026-09-13b — mechanism correction)

A request to review how Spec Kit presets are actually scaffolded (pointing at
`github/spec-kit`'s `presets/scaffold`, whose README says to download it as a starting point)
led to cloning and directly inspecting the real upstream mechanism rather than reasoning only
from this project's locally installed `.specify`/`.claude` files, per the standing Assumption
that the installed Spec Kit structure is source of truth. That inspection found the prior
revision's *design* sound but its *delivery mechanics* wrong in three concrete, evidenced ways
(full trail: research.md §1, §4, §12):

1. **`presets/scaffold` is the wrong starting point for Questmaster itself.** A Spec Kit preset
   can only override or compose *existing* templates/commands; it has no mechanism for net-new
   commands, hooks, or config files. Questmaster's three commands are net-new capability, so it
   must be delivered as a Spec Kit **extension** (`extensions/template/` is the correct
   scaffold), with a real manifest (`contracts/extension.yml`) installed via
   `specify extension add --dev`, not a hand-authored file layout that merely resembles one.
2. **Every command name is corrected**, not restyled: `/quest-story` →
   `/speckit-questmaster-story`, and likewise for the check-spec/check-plan commands (FR-001,
   FR-029, FR-030 and all other command references throughout this document). This was not a
   style choice available either way — the real hook-invocation code
   (`HookExecutor._skill_name_from_command`) only produces a working agent invocation for a
   `speckit.<extension-id>.<command>`-shaped id; the original ids would have registered hooks
   that never actually resolve to an invocable command.
3. **The rubric config path is corrected**: `.specify/questmaster/config.yml` (FR-024) →
   `.specify/extensions/questmaster/questmaster-config.yml`, the real location
   `ConfigManager` (the actual, shipped config-resolution class) uses for any extension's
   project config — which brings a gitignored local-override file and
   `SPECKIT_QUESTMASTER_<KEY>` environment-variable layer for free.

The developer was asked, given the naming correction's user-facing cost, whether to adopt full
compliance or hand-author the original short names outside the extension system; full
compliance was chosen. Nothing about the design itself changes: the pending-story mechanism
(FR-029), band-based scoring (FR-036), Judgment Ledger (FR-035), Dragon Pass (FR-034),
Comprehension Checkpoint (FR-041), and independent-assessment requirement (FR-037) from the
2026-09-13a revision all stand exactly as designed — this revision corrects only how they are
delivered and invoked.

## Revision Note (Session 2026-09-13a — review-driven)

A critical review of the previous draft, conducted from three perspectives (engineering
management/adoption, technical-lead/comprehension, and staff-engineer/measurement-honesty),
found that the design measured **documents** while the problem it exists to solve is about
**people**. Five findings drove material change; all five are now backed by constitution
principles added in v1.1.0.

1. **The score could not motivate, because the developer did not earn it.** Claude interviewed,
   Claude wrote `story.md`, Claude scored `story.md` — in the same turn. Every one of the ten
   story dimensions measured document completeness, so a developer who challenged each assumption
   and one who agreed with everything scored identically. Principle VII was asserted but had no
   expression in any rubric. → New Judgment Ledger and `developer_judgment` dimension (FR-035,
   FR-010), Dragon adversarial pass (FR-034), and a critical condition that makes `READY`
   unreachable with no recorded developer contribution (FR-012).

2. **Assessments would have been self-assessments.** `after_specify`/`after_plan` hooks fired in
   the same context that had just authored the artifact, with the whole authoring conversation
   still in scope. An assessor anchored on its own reasoning will classify its own additions as
   `REFINED`. → Independent assessment required (FR-037, Principle XIII).

3. **The remedy for unread AI prose was two more unread AI prose files.** Integrity reports led
   with a nine- or ten-row score table and a classification table carrying one row per
   requirement, most of them saying `PRESERVED`. → Decision-first reporting: at most three
   decisions surfaced up front, non-actionable classifications aggregated (FR-038).

4. **Nothing tested comprehension, which is the stated problem.** Every gate could be passed by
   pressing return, and `READY_WITH_ACCEPTED_RISK` was a free, permanent, never-revisited escape.
   → Plan Comprehension Checkpoint (FR-041), developer-written justifications and carry-forward
   of outstanding accepted risk (FR-014, FR-039).

5. **The scores were not reproducible and the ceremony was not proportionate.** Free-integer LLM
   scoring on 15-weight dimensions moves several points run to run; and an 18-section story
   applied equally to a two-day change guarantees the process is routed around. → Four anchored
   bands with a deterministic composite and a repeatability requirement (FR-036); Short Quest
   path and stated interview budgets (FR-033); story structure reduced from 18 mandatory sections
   to 9 core + 4 extended (FR-003); rubric dimensions reduced from 29 to 25 while adding
   `developer_judgment` and `legibility`.

Two further changes remove self-inflicted cost:

- **FR-029 is redesigned so that no existing Spec Kit file is modified.** The prior design
  required editing `speckit-specify`'s own directory-allocation step, accepted as a "conditional
  pass" against Principle XI. Re-examining the *requirement* rather than the mechanism showed the
  ordering constraint was the cheaper thing to change: `/speckit-questmaster-story` no longer allocates a
  feature directory at all (FR-029, FR-042). This supersedes Clarification Q1 of 2026-09-12.
- **FR-032 is retired.** "System MUST define — but is not required to implement" was satisfied by
  its own existence; it was untestable and unfalsifiable as a requirement. Its content is
  preserved as design intent under Out of Scope.

**Scope decision deferred to the developer**: the review recommended going further — dropping
Plan Integrity *scoring* from this release and spending it on Tasks-stage comprehension, since
task comprehension is the originally reported pain. This revision does not do that. It keeps the
Plan Integrity stage and attaches the comprehension checkpoint and a `legibility` dimension to
it, on the grounds that the plan is where comprehension first fails and that Tasks-stage work
needs a Plan-stage anchor to compare against. Reversing this remains a live option and is
recorded here rather than silently resolved.

## Revision Note (Session 2026-09-12b)

Following the initial draft and `/speckit-clarify` pass, the developer substantially deepened
this specification's model of what a Quest Story is and how fidelity is judged across the
lifecycle: the five-way separation of **Problem / Need / Outcome / Requirement / Solution** (Key
Concepts); **Solution Neutrality** as a first-class scored concept; a four-state readiness gate
(`NOT_READY` / `NEEDS_CLARIFICATION` / `READY` / `READY_WITH_ACCEPTED_RISK`) driven by named
objective criteria rather than score alone; "Alignment Assessment" renamed to **Integrity
Assessment** throughout; and a unified six-way cross-artifact **Drift Classification**
(`PRESERVED` / `REFINED` / `CLARIFIED` / `DISCOVERED` / `ACCEPTED_SCOPE_CHANGE` /
`UNJUSTIFIED_DRIFT`) applied at every stage transition. The original FR-001–FR-023 numbering and
the rubrics they referenced are superseded by that revision and by this one.

## Clarifications

### Session 2026-09-12

- ~~Q: Should `/quest.story` create the feature's directory and branch itself when none exists
  yet?~~ **SUPERSEDED by the 2026-09-13a revision.** The original answer (`/quest.story` allocates
  the directory itself, and `/speckit-specify` reuses it) forced a modification to
  `speckit-specify`'s own control flow. The revised design has `/speckit-questmaster-story` allocate nothing:
  see FR-029.
- Q: How should the specification and plan alignment assessments actually be triggered? → A:
  Automatically via Spec Kit's extension hooks (`hooks.after_specify`, `hooks.after_plan`), firing
  right after `/speckit-specify`/`/speckit-plan` complete, but only when a `story.md` exists for
  the feature; the hook invokes a normal Questmaster command that remains separately re-runnable
  on demand. *(Still valid; FR-037 additionally requires the invoked assessment to run in an
  independent context.)*
- Q: What format and location should the Questmaster scoring rubric configuration live in? → A:
  One YAML file holding all three rubrics plus the readiness threshold. *(The single-file intent
  is still valid; the literal path decided in this session — `.specify/questmaster/config.yml` —
  is corrected in the 2026-09-13b revision to `.specify/extensions/questmaster/
  questmaster-config.yml`, the real per-extension config location, discovered by directly
  inspecting `github/spec-kit`'s `ConfigManager` rather than assuming a path; see research.md
  §12. The correction also gains a gitignored local-override layer and environment-variable
  layer for free, neither of which the original single-file answer anticipated.)*
- Q: Where should Questmaster record it when a developer knowingly proceeds past a low score or an
  unresolved Quest Drift finding? → A: Appended directly into the relevant artifact rather than a
  separate log file. *(Still valid in substance; the in-artifact section is now the **Questmaster
  Record**, of which Decisions is one subsection — see FR-027.)*
- Q: Should the full alignment assessment output be persisted to a file, or only shown in the
  response? → A: Persisted as a dedicated report file per assessment (`spec-integrity.md`,
  `plan-integrity.md`), overwritten each time that assessment reruns. *(Still valid; FR-038 now
  governs the order in which that content is presented.)*

### Session 2026-09-13

- Q: What should happen when a developer runs `/speckit-questmaster-story` for a second, unrelated
  idea while an earlier pending story is still unclaimed? → A: Refuse to overwrite — state that an
  unclaimed pending story exists (with its title) and require an explicit choice to revise it,
  consume it via `/speckit-specify`, or discard it (FR-029).
- Q: Should an Integrity report's source digest cover the whole artifact file, including the
  `## Questmaster Record` Questmaster itself appends? → A: No — the digest covers artifact content
  excluding the Questmaster Record, so recording a Decision, Judgment Ledger entry, or
  Comprehension answer never marks a downstream report stale (FR-040).
- Q: How does an Outstanding Accepted Risk stop being outstanding? → A: Both paths — the developer
  may resolve it explicitly at any time, and Questmaster may auto-resolve it when it finds evidence
  the underlying gap is closed, recording that evidence and reporting the auto-resolution at the
  next stage so the developer can reopen it (FR-039).
- Q: How many challenges should a Dragon Pass raise, and do they count against the interview
  budgets? → A: 2-3 on a Short Quest and 3-5 on a Full Quest, counted inside the FR-033 budgets,
  which are unchanged (FR-034, FR-033).
- Q: On a re-run of the Plan Integrity assessment, should the three Comprehension Checkpoint
  questions be asked again? → A: No — a re-run asks exactly one further question, which MUST differ
  from every question already asked and recorded for that plan (FR-041).

## Key Concepts & Terminology

These distinctions apply everywhere in this document and in every Questmaster artifact. They
MUST NOT be collapsed or used interchangeably.

- **Problem**: The undesirable situation that exists today. Independent of any fix.
- **Need**: What the affected user(s) or system require in order for the problem to no longer
  hold. Still solution-independent.
- **Outcome**: What becomes observably true once the problem is solved. Describes a resulting
  state, not an action taken to reach it.
- **Requirement**: A specific behavior the system must provide to make the outcome possible.
  The first point where "what" starts to constrain "how."
- **Solution**: A specific way of implementing one or more requirements. The most concrete and
  most replaceable of the five.
- **Solution Neutrality**: The degree to which a story or specification describes the problem
  and desired outcome without unnecessarily prescribing a solution. A developer-supplied
  proposed solution is always recorded, never rejected outright.
- **Known Fact**: Something established by evidence (an observation, report, metric, or prior
  decision record).
- **Assumption**: Something believed true but not yet established by evidence.
- **Unknown**: Information needed to make a decision that is not currently available.
- **Decision**: An explicit choice made despite unresolved alternatives (including a developer's
  choice to proceed past a gap — see FR-014, FR-027).
- **Refinement**: A later artifact making an earlier artifact's intent more concrete without
  changing it.
- **Clarification**: A later artifact resolving genuine ambiguity left open by an earlier one.
- **Discovery**: A later artifact introducing a requirement newly justified by evidence
  uncovered during that stage (not present in, but not contradicting, the earlier artifact).
- **Accepted Scope Change**: A new or changed requirement beyond the earlier artifact's intent
  that has been explicitly acknowledged and accepted by the developer.
- **Unjustified Drift ("Quest Drift")**: A change that cannot currently be justified as
  refinement, clarification, discovery, or an accepted scope change.
- **Preserved**: No divergence detected between an element and its origin.

Concepts introduced by the 2026-09-13a revision:

- **Developer Judgment**: A contribution to an artifact that originates with the developer and
  could not have been generated or inferred by the AI on their behalf — a challenge to a
  proposed requirement, a cut, a constraint asserted from knowledge the AI lacks, an assumption
  converted into an evidenced known fact, a risk named before being pointed out, or an answer to
  a comprehension question. Distinct from the developer approving AI-authored content.
- **Judgment Ledger**: The record of developer judgment for a feature, held as a subsection of
  the Questmaster Record inside the artifact each entry concerns. The evidence base for the
  `developer_judgment` rubric dimension, and the thing that distinguishes a developer who used
  Questmaster from one who watched it run.
- **Dragon Pass**: A bounded adversarial challenge to a story before it is scored — what can
  fail, which assumption is unsafe, what happens under unexpected input, partial failure, or
  changing requirements. The developer's responses become Judgment Ledger entries.
- **Comprehension Checkpoint**: Three fixed questions about a plan whose answers cannot be
  derived from the plan itself, asked before the plan is executed, recorded verbatim — plus one
  further, previously unasked question on each subsequent Plan Integrity run.
- **Band**: One of four anchored judgment levels — `ABSENT`, `WEAK`, `ADEQUATE`, `STRONG` —
  assigned per rubric dimension. The unit of judgment in every Questmaster assessment; numeric
  scores are computed from bands, never assigned directly.
- **Independent Assessment**: An assessment performed with only the artifacts under comparison,
  the rubric configuration, and the recorded Questmaster Record in scope — never with the
  conversation that authored the artifact in scope.
- **Decision Worklist**: The at-most-three items requiring a developer's judgment, presented
  before any score or complete finding list.
- **Outstanding Accepted Risk**: A gap the developer knowingly accepted that has not since been
  resolved. Re-surfaced at every subsequent stage until resolved or the quest ends.
- **Questmaster Record**: The single in-artifact section (`## Questmaster Record`) holding, as
  subsections, that artifact's Judgment Ledger, Comprehension answers, and Decisions.

Together, Refinement / Clarification / Discovery / Accepted Scope Change / Unjustified Drift /
Preserved form the six-way **Drift Classification** used at every artifact-to-artifact
transition (FR-017/FR-018). The system's task is never to decide whether divergence is inherently
good or bad — divergence is expected in iterative development — but to classify it correctly
and, for the last two classifications in particular, surface the question a developer must
answer: *was the change understood and intentionally accepted?*

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Turn a vague request into a bounded, challenged, scored Quest Story (Priority: P1)

A developer has a rough, under-specified idea (e.g. "we need to let customers configure
notification preferences"). Instead of letting an AI jump straight to writing a specification,
the developer runs `/speckit-questmaster-story`. Questmaster first establishes how large this quest is and
selects a Short or Full path accordingly, then conducts a bounded Socratic conversation covering
the problem, affected actors, current behavior, a small number of meaningful use cases, the
desired outcome, scope boundaries, success criteria, and the separation of known facts from
assumptions and unknowns — plus, on a Full Quest, background, business rules, constraints, and
any solution the developer already has in mind.

The Storyteller then hands over to the Dragon: a short adversarial pass that names what could
fail, which assumptions are unsafe, and what happens under partial failure or changing
requirements. The developer answers, dismisses, or accepts each challenge, and those responses —
along with every point where the developer corrected, cut, or asserted something the AI could not
have known — are recorded in the Judgment Ledger.

Questmaster writes `story.md`, scores it band-by-band with cited evidence, and classifies
readiness using named criteria — never from the score alone, and never `READY` when the ledger is
empty.

**Why this priority**: This is the foundational capability. Every other Questmaster capability
depends on a story existing with enough rigor to compare against. It is also the only stage where
the developer's understanding is cheap to improve.

**Independent Test**: Run `/speckit-questmaster-story` against a deliberately vague, one-sentence feature
request and confirm that (a) a Short or Full path is chosen and stated, (b) the developer is
asked clarifying questions rather than handed an instant specification, (c) the interview stops
within the stated budget rather than continuing indefinitely, (d) a Dragon pass challenges the
story and the developer's responses are recorded, (e) a `story.md` is produced with every core
section present and any inapplicable extended section marked N/A with a reason, (f) any proposed
solution is recorded separately with a Solution-Neutrality Assessment, and (g) a banded Story
Integrity Assessment with per-dimension evidence and a named readiness classification is shown.
This delivers value on its own: a clearer, better-interrogated, solution-neutral problem
statement, even if the developer never proceeds to `/speckit-specify`.

**Acceptance Scenarios**:

1. **Given** a new feature with no existing Spec Kit artifacts, **When** the developer runs `/speckit-questmaster-story` with a vague one-line request, **Then** Questmaster establishes the quest size, states which path it is taking and why, and asks a bounded series of Socratic questions covering the core sections before producing any document.
2. **Given** a request that already contains a proposed solution (e.g. "create a NotificationPreference table so customers can disable marketing emails"), **When** the Storyteller processes it, **Then** it records the proposal separately, restates the underlying problem/outcome in solution-neutral language, and determines which parts of the proposal are genuine requirements, which are implementation choices, which are assumptions, and whether the proposal unnecessarily constrains the story — without rejecting it.
3. **Given** a story whose core sections have been answered, **When** the Storyteller judges the evidence sufficient, **Then** it stops asking questions and runs the Dragon pass rather than continuing to interview.
4. **Given** the Dragon pass, **When** it challenges the story, **Then** it raises a bounded number of specific, answerable challenges drawn from this story's own content (not generic risk boilerplate), the developer's response to each is recorded verbatim in the Judgment Ledger, and a challenge the developer dismisses is recorded as dismissed rather than dropped.
5. **Given** a completed `story.md`, **When** Questmaster scores it, **Then** each rubric dimension receives one of `ABSENT`/`WEAK`/`ADEQUATE`/`STRONG` with a written justification citing specific story content (e.g. "Use cases: WEAK — one trivial case, no failure path described"), the overall 0-100 score is computed from those bands rather than chosen, and no dimension is awarded a band above `ABSENT` for a section that merely exists.
6. **Given** an unchanged `story.md` scored twice, **When** the results are compared, **Then** the bands and the computed score are materially identical.
7. **Given** a story with a high score but one unresolved critical condition (e.g. the primary affected actor is never identified, or the Judgment Ledger is empty), **When** Questmaster classifies readiness, **Then** it reports `NOT_READY` regardless of the numeric score and states exactly which critical condition is unmet.
8. **Given** a story with no critical gap but a score below the configured threshold, **When** the developer is shown the result, **Then** Questmaster classifies it `NEEDS_CLARIFICATION`, states specifically what is missing or weak, and requires an explicit choice — revise, or proceed and accept the gap — where accepting requires the developer to write their own reason and is recorded as `READY_WITH_ACCEPTED_RISK` in the story's Questmaster Record.
9. **Given** a story with no critical gap and a score at or above the threshold, **When** the developer is shown the result, **Then** Questmaster classifies it `READY`.

---

### User Story 2 - Assess Specification Integrity between Story and Specification (Priority: P2)

After `/speckit-questmaster-story` produces a scored `story.md`, the developer proceeds to Spec Kit's normal
specification step. Once `spec.md` exists, a Specification Integrity assessment runs — in a
context that has only `story.md`, `spec.md`, the rubric, and the Questmaster Record in scope, not
the conversation that wrote the spec — comparing the two across seven dimensions and applying the
six-way Drift Classification to every requirement, scope item, and assumption.

What the developer sees first is not the score. It is at most three decisions they need to make,
each with the question to answer, plus any accepted risk still outstanding from the story stage.
The scores, the aggregate classification summary, and the full per-element table follow, and the
complete report is persisted for anyone who wants it.

**Why this priority**: This is the first place Questmaster proves its central premise — that
later artifacts can be checked against earlier intent — and the most common place scope silently
grows. It depends on Story 1 but delivers distinct value: catching drift before it reaches a plan
or implementation, where it is more expensive to unwind.

**Independent Test**: Take a `story.md`/`spec.md` pair where the spec faithfully reflects the
story; confirm a high Specification Integrity result, every requirement classified
`PRESERVED`/`REFINED`/`CLARIFIED`, and a decision worklist stating there is nothing to decide.
Then take a pair where the spec introduces scope absent from the story; confirm those additions
are classified `DISCOVERED`, `ACCEPTED_SCOPE_CHANGE`, or `UNJUSTIFIED_DRIFT` as appropriate, that
at most three are surfaced up front with the rest in the appendix, and that each carries a
specific developer question.

**Acceptance Scenarios**:

1. **Given** a `story.md` and a `spec.md` that faithfully reflects it, **When** the assessment runs, **Then** it reports a banded, evidence-based result across all seven dimensions, with every requirement classified `PRESERVED`, `REFINED`, or `CLARIFIED`, and its decision worklist explicitly states that no decision is required.
2. **Given** a `spec.md` that introduces a requirement, scope item, or assumption not reasonably supported by `story.md` and with no accompanying Questmaster Decision, **When** the assessment runs, **Then** it classifies the item `UNJUSTIFIED_DRIFT` (if wholly unjustified) or `DISCOVERED` (if newly justified by evidence surfaced during specification) and reports source artifact, destination artifact, original intent, new behavior, classification, evidence, severity, and the question the developer should answer.
3. **Given** an assessment producing more than three findings requiring a decision, **When** it is presented, **Then** only the three highest-severity items appear in the decision worklist, the remainder are counted and named in one line, and all of them appear in full in the persisted report.
4. **Given** a `spec.md` requirement that elaborates a story element without contradicting or exceeding its intent, **When** the assessment runs, **Then** it is classified `REFINED`, not flagged as drift, and it is summarized in aggregate rather than given its own finding block.
5. **Given** a `spec.md` requirement beyond the story's scope accompanied by a Questmaster Decision recording explicit developer acceptance, **When** the assessment runs, **Then** it is classified `ACCEPTED_SCOPE_CHANGE`, not `UNJUSTIFIED_DRIFT`.
6. **Given** an accepted risk recorded at the story stage that has not since been resolved, **When** the Specification Integrity assessment is presented, **Then** that outstanding accepted risk is restated, with the date it was accepted and the developer's own stated reason.
7. **Given** any Drift Classification finding, **When** it is reported, **Then** the specification is not automatically edited, blocked, or rejected — the finding is advisory and requires the developer's judgment.
8. **Given** a feature directory with `spec.md` but no `story.md`, **When** an assessment is explicitly requested, **Then** Questmaster states that it could not be assessed because no story exists and explains how to create one, rather than fabricating a comparison or failing silently.
9. **Given** an assessment that cannot be performed in an independent context, **When** it is presented, **Then** it is explicitly labelled as self-assessed rather than presented as a review.
10. **Given** an assessment whose Decision Worklist is non-empty, **When** it is presented, **Then** the developer is asked for a response to its highest-severity item, that response — resolved, accepted with their own written justification, or explicitly deferred — is recorded in the Questmaster Record as a Judgment Ledger entry, an unanswered item is recorded as unanswered rather than silently dropped, and proceeding to `/speckit-plan` is never prevented either way.

---

### User Story 3 - Comprehend and assess the Plan (Priority: P3)

Once Spec Kit's planning step produces `plan.md`, Questmaster does two things in order. First, the
Comprehension Checkpoint: before showing any assessment, it asks the developer three questions
about the plan whose answers are not in the plan — which part is most likely to be wrong, what
they would cut, and what breaks first. The answers are recorded verbatim; declining is permitted
and is itself recorded. A later re-run does not re-ask them — it asks one further question the
developer has not been asked before about this plan, and restates the earlier answers.

Then the Plan Integrity assessment runs independently against both `story.md` and `spec.md`,
covering intent preservation, specification coverage, constraint preservation, proportionality,
legibility, risk management, test strategy, and traceability. It is explicitly not just a
technical-quality score: it checks whether the plan preserves the story's desired outcome and
constraints, and whether a developer who did not write it could understand it — and it applies
the six-way Drift Classification to every technical decision not traceable to the story or spec.

**Why this priority**: Plans are where unjustified technical complexity most often enters, where a
story's constraints are most easily lost in translation, and — per the review that prompted this
revision — where developer comprehension most reliably fails. Asking the developer to commit to a
prediction before showing them an assessment converts them from a reviewer into a participant,
and gives later stages something the developer said to check against.

**Independent Test**: Supply a `story.md` + `spec.md` + `plan.md` set where the plan is
proportionate and preserves the story's constraints; confirm the checkpoint is asked before any
assessment appears, the answers are recorded, and the assessment is clean. Then supply a set where
the plan introduces unrequested services or drops a stated constraint; confirm those are
classified as drift with rationale, that a genuinely justified complex design is not flagged
merely for being complex, and that a plan which is sound but unreadable scores poorly on
`legibility` while scoring well elsewhere.

**Acceptance Scenarios**:

1. **Given** a newly produced `plan.md`, **When** Questmaster reaches the plan stage, **Then** the three Comprehension Checkpoint questions are asked before any score, finding, or report is shown.
2. **Given** the developer answers the checkpoint, **When** the answers are recorded, **Then** they are stored verbatim in `plan.md`'s Questmaster Record and added to the Judgment Ledger, and the assessment that follows explicitly notes where the developer's prediction agrees or disagrees with its own findings.
3. **Given** the developer declines the checkpoint, **When** this is recorded, **Then** the decline is recorded as a decline (not as an absence), the assessment proceeds normally, and nothing is blocked.
4. **Given** a feature whose plan has already been through a Comprehension Checkpoint, **When** the Plan Integrity assessment is run again, **Then** exactly one further question is asked — one that differs from every question already recorded for that plan — and the earlier answers are restated rather than asked again.
5. **Given** `story.md`, `spec.md`, and a proportionate `plan.md` that preserves every story-level constraint, **When** the assessment runs, **Then** it reports banded, evidence-based coverage across all eight dimensions with traceability from each major technical decision back to a story or spec element.
6. **Given** a `plan.md` introducing components, services, or abstractions not traceable to any requirement in `story.md` or `spec.md`, **When** the assessment runs, **Then** each receives a Drift Classification with source artifact, destination artifact, original intent, new decision, evidence, severity, and the developer question.
7. **Given** a `plan.md` satisfying the specification's stated behavior but dropping or contradicting a constraint stated in `story.md` (even if `spec.md` carried it forward), **When** the assessment runs, **Then** the loss is flagged under constraint preservation, not only under specification coverage.
8. **Given** a `plan.md` that is complex but where every complex element is traceable to a stated constraint, risk, or requirement, **When** the assessment runs, **Then** the plan is not classified as drift merely for being complex, and simplification is not recommended on complexity grounds alone.
9. **Given** a technically sound `plan.md` that a developer who did not author it cannot follow — unexplained decisions, undefined terms, no stated order of work — **When** the assessment runs, **Then** `legibility` is banded `WEAK` or `ABSENT` with specific evidence, independently of how the technical dimensions band.
10. **Given** a Plan Integrity assessment with findings, **When** it is reported, **Then** it leads with at most three decisions, is advisory throughout, and does not block proceeding to tasks.

---

### Edge Cases

- What happens when a developer runs `/speckit-questmaster-story` for a feature that already has a `story.md`? Questmaster must not silently overwrite prior answers; it treats this as revising an existing story, preserves the existing Questmaster Record, and tells the developer that downstream `spec-integrity.md`/`plan-integrity.md` are now stale (detected via recorded source digests, FR-040 — not merely asserted).
- What happens when a developer starts a new, unrelated story while an unclaimed pending story is still waiting? Questmaster refuses to overwrite it: it names the pending story's Quest Title and requires an explicit choice — revise it, consume it via `/speckit-specify`, or discard it — so that neither the earlier interview is silently destroyed nor an unrelated story is later relocated into the wrong feature directory (FR-029).
- What happens when the developer gives contradictory answers during the interview? Questmaster surfaces the contradiction and asks for clarification rather than silently picking one; the resolution is a Judgment Ledger entry.
- What happens when a developer insists the proposed solution *is* the story and resists separating problem from implementation? Questmaster records the proposal separately, notes that Solution Neutrality could not be fully assessed and why, and does not block — the gap is surfaced, not enforced.
- What happens when a story scores well numerically but a critical condition remains unmet? It is classified `NOT_READY`, never `READY`, regardless of score.
- What happens when the developer engages with nothing — accepts every generated answer, dismisses nothing, answers no Dragon challenge? The Judgment Ledger is empty, `developer_judgment` bands `ABSENT`, the `no_developer_judgment_recorded` critical condition is unmet, and the story is `NOT_READY`. The developer may still knowingly proceed, but it is recorded as an override rather than a pass.
- What happens when a developer deliberately proceeds past `NOT_READY`, `NEEDS_CLARIFICATION`, a drift finding, or a low Integrity result? Questmaster requires a justification the developer writes themselves, records it, and re-surfaces it as an Outstanding Accepted Risk at every later stage until it is resolved.
- What happens when the gap behind an accepted risk is quietly closed by a later artifact? Questmaster may auto-resolve the risk, but only with cited evidence that the condition no longer holds; the resolution is attributed to Questmaster, not to the developer, and is reported at the next stage so they can reopen it (FR-039).
- What happens when a developer offers no justification, or an empty one, when accepting a risk? The acceptance is not recorded and the status does not change — a menu selection, an empty string, or silence is not judgment (FR-014).
- What happens when a later artifact is classified `ACCEPTED_SCOPE_CHANGE` but no matching Questmaster Decision actually exists? Treat it as `UNJUSTIFIED_DRIFT` until an explicit acceptance is recorded — acceptance is never inferred from the absence of an objection.
- What happens when the rubric configuration or critical-condition list is missing, malformed, or partially specified? Questmaster falls back to documented defaults for the affected rubric only, warns the developer, and proceeds rather than failing the assessment.
- What happens when a specification or plan is restructured so heavily that section-by-section comparison is not meaningful? The assessment compares by underlying intent and content, not by matching section titles, literal wording, or traceability identifiers alone.
- What happens when an assessment cannot be run in an independent context (no mechanism available in the host environment)? It still runs, but it is labelled self-assessed in both the response and the persisted report, and that label is not removable by configuration.
- What happens when a Short Quest is chosen for something that turns out to be large? The Storyteller may escalate to a Full Quest mid-interview, stating why; the developer may also request either path explicitly at any point, and their choice is honoured and recorded.
- What happens when an upstream artifact changed after a report was written? The recorded source digest no longer matches, and the next assessment states which upstream artifact changed and that the previous findings were based on a different version. Questmaster's own additions to that artifact's Questmaster Record are outside the digested content and never trigger this (FR-040).
- What happens on a project that has not adopted Questmaster at all? Existing Spec Kit commands behave exactly as they do today — Questmaster never makes its artifacts or assessments prerequisites for standard Spec Kit commands, and installing Questmaster modifies no existing Spec Kit file.

## Requirements *(mandatory)*

### Functional Requirements

**Quest Story authoring**

- **FR-001**: System MUST provide a `/speckit-questmaster-story` command that conducts a structured, Socratic dialogue with the developer covering, at minimum, the story's core sections (FR-003): the problem being solved, who is affected, current behavior, meaningful use cases, the desired outcome, scope boundaries, success criteria, and known facts versus assumptions versus unknowns. On a Full Quest it additionally covers background/context, business rules, constraints, and — when the developer has one in mind — a proposed solution assessed separately for Solution Neutrality.
- **FR-002**: System MUST end the dialogue once there is sufficient evidence to produce a useful story, rather than continuing to ask questions once the required information has been gathered, and MUST design to the interview budgets in FR-033.
- **FR-003**: System MUST produce a `story.md` artifact, located alongside the feature's other Spec Kit artifacts, structured as **nine core sections** (Quest Title, Problem Statement, Who Is Affected/Actors, Current Behaviour, Use Cases, Desired Outcomes, Scope Boundaries, Success Criteria, Assumptions & Known Unknowns), **four extended sections** (Background/Context, Business Rules, Constraints, Proposed Solutions & Solution-Neutrality Assessment), and **four recorded sections** produced by Questmaster rather than the interview (Dragon's Questions, Questmaster Record, Story Readiness Assessment, Story Integrity Assessment). Core sections MUST always be present. Extended sections MUST be present on a Full Quest, and on a Short Quest only where material. A section genuinely not applicable MUST be explicitly marked not applicable with a one-line reason rather than omitted or padded with filler. See data-model.md for full section definitions.
- **FR-004**: System MUST keep Problem, Need, Outcome, Requirement, and Solution distinct throughout the story and MUST NOT present a proposed implementation as evidence that the underlying problem has been understood.
- **FR-005**: System MUST treat a developer-proposed solution as data to record and analyze, not something to accept or reject outright: it MUST determine which parts are genuine requirements, which are proposed implementation detail, which are assumptions, and whether the proposal unnecessarily constrains the story.
- **FR-006**: System MUST capture a small number of meaningful use cases rather than an exhaustive list of trivial interactions; each MUST record the acting party, their goal, the triggering condition, the expected result, and any important alternate or failure path, and MUST later serve as evidence for corresponding functional requirements in `spec.md`.
- **FR-007**: System MUST record In-Scope Behaviour, Explicit Non-Goals/Out-of-Scope, and Adjacent Concerns as three distinct lists, so that scope creep can later be detected against a bounded definition rather than an implicit one.
- **FR-008**: System MUST keep Known Facts, Assumptions, Unknowns, and Decisions as distinguishable categories — they MUST NOT be collapsed into a single undifferentiated list.
- **FR-009**: System MUST require every success criterion to describe an observable outcome rather than an implementation step.

**Quest sizing and process budget**

- **FR-033**: System MUST establish the size of a quest before interviewing and MUST offer two paths: a **Short Quest** (core sections only, extended sections only where material) targeting roughly six questions and under five minutes, and a **Full Quest** (all sections) targeting roughly twelve questions and under fifteen minutes. These budgets MUST cover the whole developer-facing stage, including the Dragon Pass challenges (FR-034); the Dragon Pass MUST NOT be treated as sitting outside the budget. The system MUST state which path it has chosen and why; the developer MUST be able to override the choice at any point; and the Storyteller MUST be able to escalate a Short Quest to a Full Quest mid-interview, stating why. These targets are design budgets, not enforced limits, and MUST NOT be implemented as hard cut-offs that truncate a productive conversation.

**Adversarial challenge**

- **FR-034**: Before scoring a story, system MUST conduct a bounded **Dragon Pass**: two to three specific adversarial challenges on a Short Quest, three to five on a Full Quest, derived from this story's own content — what can fail, which assumption is unsafe, what happens under unexpected input, dependency failure, partial failure, migration, or changing requirements. Challenges MUST be specific to the story rather than generic risk boilerplate. The developer's response to each MUST be recorded verbatim, including an explicit dismissal, and each response MUST become a Judgment Ledger entry. The Dragon Pass MUST NOT block, MUST NOT rewrite the story on the developer's behalf, and MUST NOT add unanswered challenges to the story as if they were the developer's own content.

**Developer judgment**

- **FR-035**: System MUST maintain a **Judgment Ledger** recording every contribution that originated with the developer and could not have been generated or inferred on their behalf: a challenge to a proposed requirement, a cut, a constraint or fact asserted from knowledge the AI lacked, an assumption converted to an evidenced known fact, a risk named before being raised, a Dragon response, a comprehension answer, or a correction of AI-authored content. Each entry MUST record the stage, the date, the developer's own words, and what changed as a result. Approving, accepting, or proceeding past AI-authored content MUST NOT be recorded as a judgment entry. The ledger MUST live in the Questmaster Record of the artifact the entry concerns.
- **FR-036**: System MUST band every rubric dimension, in every assessment, as exactly one of `ABSENT`, `WEAK`, `ADEQUATE`, or `STRONG`, against anchored definitions published in the rubric configuration. A dimension's numeric contribution MUST be a deterministic function of its band and weight (`ABSENT` = 0, `WEAK` = one third, `ADEQUATE` = two thirds, `STRONG` = full weight), and the overall 0-100 score MUST be computed from the bands rather than assigned directly. Re-assessing an unchanged artifact against an unchanged rubric MUST reproduce the same bands for at least 90% of dimensions and an overall score within five points.

**Story Integrity scoring and readiness**

- **FR-010**: System MUST score every completed story against a documented, transparent, project-editable rubric with exactly these ten dimensions and default weights: Problem definition (15), Actors and current state (10), Use cases (15), Desired outcomes (15), Scope and boundaries (10), Success criteria (10), Assumptions and unknowns (5), Constraints and context (5), Solution neutrality (5), Developer judgment (10) — producing a Story Integrity Score of 0-100 computed per FR-036. Weights MUST sum to 100 and MUST be project-editable (FR-024). The Developer judgment dimension MUST be banded from the Judgment Ledger alone and MUST NOT be banded from the quality of AI-authored story content.
- **FR-011**: System MUST accompany every dimension band with a written, evidence-based justification citing specifics from the story; a section's mere presence MUST NOT earn a band above `ABSENT`, and vague or self-contradictory content MUST band poorly regardless of length.
- **FR-012**: System MUST classify story readiness as exactly one of `NOT_READY`, `NEEDS_CLARIFICATION`, `READY`, or `READY_WITH_ACCEPTED_RISK`, using named, objective criteria. The default critical-condition list is: unclear core problem, unidentified primary actor when one is required, absent desired outcome, missing critical use cases, unbounded scope, unresolved critical assumptions, success that cannot be evaluated, and **no developer judgment recorded**. The Story Integrity Score alone MUST NOT determine this classification — any unmet critical condition MUST force `NOT_READY` regardless of score.
- **FR-013**: System MUST treat the story readiness score threshold (defaulting to 70) as a per-project configurable value feeding the `NEEDS_CLARIFICATION`/`READY` distinction only, not a hard-coded constant and not the sole determinant of readiness.
- **FR-014**: When a story is classified anything other than `READY`, system MUST state specifically what is missing, weak, or unmet, and MUST require the developer to explicitly choose to revise or to proceed and accept the gap. Accepting MUST require a justification the developer writes in their own words: a menu selection, a generated justification, an empty string, or silence MUST NOT be recorded as acceptance, and where none is supplied the status MUST remain unchanged. An accepted override MUST be reclassified `READY_WITH_ACCEPTED_RISK`, recorded per FR-027, and carried forward per FR-039.

**Specification Integrity**

- **FR-015**: System MUST support a Specification Integrity assessment of `spec.md` against `story.md`, banding seven dimensions against a documented, project-editable, weighted rubric summing to 100: story fidelity (20), requirement completeness (15), requirement testability (15), scope discipline (20), traceability (10), handling of ambiguity (10), internal consistency (10).

**Plan Integrity**

- **FR-016**: System MUST support a Plan Integrity assessment of `plan.md` against both `story.md` and `spec.md`, banding eight dimensions against a documented, project-editable, weighted rubric summing to 100: intent preservation (20), specification coverage (15), constraint preservation (15), proportionality (15), legibility (15), risk management (10), test strategy (5), traceability (5). Intent preservation MUST be banded independently of technical quality, so a technically sound plan that abandons the story's desired outcome or constraints cannot band well overall. **Legibility** MUST assess whether a developer who did not author the plan could follow it — are decisions explained, terms defined, and the order of work stated — and MUST be banded independently of whether the plan is technically correct.

**Comprehension**

- **FR-041**: Before presenting any Plan Integrity result, system MUST conduct a **Comprehension Checkpoint** whose questions' answers are not derivable from `plan.md`. On the first checkpoint for a given plan it MUST ask exactly three: which part of the plan is most likely to be wrong; what they would cut if they had to cut one thing; and what breaks first under load, failure, or a change of requirements. On any subsequent Plan Integrity run for the same feature it MUST ask exactly **one** further question, which MUST differ from every question already asked and recorded for that plan, and MUST restate the previously recorded answers rather than re-asking them. Answers MUST be recorded verbatim in the plan's Questmaster Record and added to the Judgment Ledger. The developer MUST be able to decline, and a decline MUST be recorded as a decline rather than as an absence. The checkpoint MUST NOT block, MUST NOT be answered by the AI on the developer's behalf, and the assessment that follows MUST state where its own findings agree or disagree with the developer's stated predictions.

**Quest Drift — cross-artifact classification**

- **FR-017**: For every requirement, scope item, assumption, or technical decision compared between two artifacts, system MUST assign exactly one Drift Classification: `PRESERVED`, `REFINED`, `CLARIFIED`, `DISCOVERED`, `ACCEPTED_SCOPE_CHANGE`, or `UNJUSTIFIED_DRIFT`. A bare "drift / no drift" binary MUST NOT be used.
- **FR-018**: For every element classified `DISCOVERED`, `ACCEPTED_SCOPE_CHANGE`, or `UNJUSTIFIED_DRIFT`, system MUST report: source artifact, destination artifact, original intent, new behavior/decision, the classification, supporting evidence, a severity, and the specific question the developer should answer to resolve it.
- **FR-019**: System MUST classify an element `ACCEPTED_SCOPE_CHANGE` only when a matching Questmaster Decision recording explicit developer acceptance exists in the artifact; absent that record, an out-of-story-scope element that is not otherwise `REFINED`/`CLARIFIED`/`DISCOVERED` MUST be classified `UNJUSTIFIED_DRIFT` — acceptance is never inferred from silence.
- **FR-020**: System MUST NOT mechanically classify content `UNJUSTIFIED_DRIFT` solely because it is not present verbatim in the preceding artifact; reasonable elaboration MUST be classified `REFINED` or `CLARIFIED`.
- **FR-021**: System MUST NOT classify or penalize a design element as drift, and MUST NOT recommend simplification, solely on the grounds of complexity when that complexity is traceable to a stated requirement, constraint, or risk.

**Independence, presentation, and carry-forward**

- **FR-037**: System MUST perform every Specification and Plan Integrity assessment in a context containing only the artifacts under comparison, the rubric configuration, and the Questmaster Records of the artifacts involved — never the conversation that authored the artifact under assessment. Where the host environment offers no mechanism to do so, the assessment MUST still run but MUST be labelled `SELF-ASSESSED` in both the response and the persisted report, and that label MUST NOT be suppressible by configuration.
- **FR-038**: System MUST present every Integrity assessment decision-first: a **Decision Worklist** of at most three items requiring developer judgment (highest severity first, each stating the question to answer), followed by any Outstanding Accepted Risk, followed by the banded dimension summary, followed by the full findings. Where more than three items require a decision, the remainder MUST be counted and named in a single line rather than omitted. Elements classified `PRESERVED`, `REFINED`, or `CLARIFIED` MUST be summarized in aggregate rather than enumerated one row per element in the presented output; the persisted report MUST still contain the complete per-element classification. When no item requires a decision, the worklist MUST say so explicitly.
- **FR-043**: When a Specification Integrity assessment produces a non-empty Decision Worklist, system MUST elicit a recorded developer response to at least its highest-severity item — resolve it, accept it with a justification the developer writes themselves (FR-014), or explicitly defer it — and MUST record that response as a Judgment Ledger entry (FR-035). A deferral MUST be recorded as a deferral rather than as an absence, and an item left unanswered MUST be recorded as unanswered and carried forward per FR-039. Where the worklist states that no decision is required, system MUST NOT elicit anything. Consistent with FR-022 this MUST NOT block `/speckit-plan`: the response is recorded, never required in order to proceed.
- **FR-039**: System MUST carry every Outstanding Accepted Risk forward: each Integrity assessment MUST restate, before its own findings, every accepted risk from an earlier stage that has not since been resolved, including the date accepted and the developer's own stated reason. A risk MUST remain outstanding until it is resolved by one of exactly two paths: (a) the developer explicitly records it as resolved at any time, or (b) Questmaster auto-resolves it on finding evidence that the condition which prompted it no longer holds — in which case it MUST record the specific evidence, MUST attribute the resolution to Questmaster rather than to the developer, and MUST report the auto-resolution at the next stage so the developer can reopen it. An auto-resolution MUST NOT be recorded without cited evidence, and absence of an objection MUST NOT be treated as evidence.
- **FR-040**: System MUST record, in every persisted Integrity report, a content digest of each source artifact the assessment was based on. The digest MUST be computed over the artifact's content **excluding its `## Questmaster Record` section** (FR-027), so that appending a Decision, Judgment Ledger entry, or Comprehension answer — content Questmaster itself writes — MUST NOT mark a downstream report stale; only a change to the artifact's substantive content may. On a subsequent run, a digest that no longer matches MUST cause the assessment to state which upstream artifact changed since the previous report and that the previous findings were based on a different version. Revising a `story.md` MUST mark existing downstream reports stale by this mechanism rather than by assertion alone.

**Evidence, advisory posture, and traceability**

- **FR-022**: System MUST present every band and score together with its underlying evidence and reasoning — never as a bare number or a bare band — and MUST NOT automatically modify, block, or reject a specification, plan, or implementation on the basis of any score or Drift Classification. All Questmaster findings are advisory and the developer retains final judgment, including the ability to knowingly proceed past a `NOT_READY` story.
- **FR-023**: System MAY assign traceability identifiers (`ST-`, `UC-`, `REQ-`, `SC-`, and — for future stages — `TASK-`/`TEST-`). IDs SHOULD be assigned to use cases and functional requirements, where they most directly support Drift Classification; the system MUST use judgment about where an identifier adds value rather than forcing one onto every element.

**Configuration, persistence, and Spec Kit integration**

- **FR-024**: System MUST expose the scoring rubrics (dimensions, weights, and the anchored band definitions required by FR-036), the story readiness score threshold, and the readiness-gate critical-condition list as explicit, human-readable, project-editable configuration rather than logic hidden inside assessment behavior. This configuration MUST live in a single project-local YAML file (`.specify/extensions/questmaster/questmaster-config.yml`).
- **FR-025**: System MUST integrate with the existing Spec Kit lifecycle as an additive layer, and MUST NOT change the behavior or output of existing Spec Kit commands for a feature or project that has not adopted Questmaster (i.e., has no `story.md` and no pending story).
- **FR-026**: When a Specification or Plan Integrity assessment is requested for a feature that has no `story.md`, system MUST clearly state that the assessment could not be performed and explain how to produce a story, rather than fabricating a comparison, guessing at intent, or failing without explanation.
- **FR-027**: System MUST record every knowing developer override — proceeding past a `NOT_READY`/`NEEDS_CLARIFICATION` story, a low Integrity result, or an `UNJUSTIFIED_DRIFT`/unresolved `ACCEPTED_SCOPE_CHANGE` finding — in a **Questmaster Record** section appended directly to the relevant artifact (`story.md`, `spec.md`, or `plan.md`) rather than a separate log file. The Questmaster Record holds three subsections: Judgment Ledger (FR-035), Comprehension (FR-041), and Decisions. Each Decision entry MUST record the date, what was unmet or flagged, the developer's explicit choice, and the justification in the developer's own words (FR-014).
- **FR-028**: System MUST operate entirely within the local repository and the existing Spec Kit project structure, without requiring a web UI, database, network service, or external SaaS integration.
- **FR-029**: System MUST allow `/speckit-questmaster-story` to run before any other Spec Kit feature artifact exists, and MUST NOT allocate a feature directory or branch in order to do so. When no feature directory exists for the request, `/speckit-questmaster-story` MUST write the story to a single pending location (`.specify/extensions/questmaster/pending-story.md`). The first subsequent `/speckit-specify` run MUST take a pending story as primary input — achieved through an extension-provided template addendum resolved by Spec Kit's own template-resolution stack, which substitutes template content and requires no change to any existing command's control flow — and the `after_specify` hook MUST relocate the pending story into the newly created feature directory as `story.md` before any assessment runs. When a feature directory with a `story.md` already exists, `/speckit-questmaster-story` MUST revise that story in place and no pending story is created. At most one pending story MUST exist at a time: when `/speckit-questmaster-story` is invoked for a new, unrelated request while an unclaimed pending story exists, the system MUST NOT overwrite it — it MUST state that a pending story exists, name its Quest Title, and require the developer to explicitly choose to revise it, consume it via `/speckit-specify`, or discard it before a new interview begins.
- **FR-042**: Installing or running Questmaster MUST NOT modify, override, or replace any existing Spec Kit command, skill, or script file. Questmaster MUST be delivered as a Spec Kit extension (not a preset — a preset cannot express net-new commands or hooks) whose every provided artifact is additive: a new command, a new template resolved through the existing template-resolution stack, a new configuration file, or new hook wiring, all declared in one extension manifest. A design that cannot satisfy a requirement without editing an existing Spec Kit file MUST change the requirement rather than the file, or record the requirement as unmet.
- **FR-030**: System MUST trigger the Specification Integrity assessment automatically immediately after `/speckit-specify` completes, and the Plan Integrity assessment automatically immediately after `/speckit-plan` completes, using Spec Kit's extension hook mechanism — but only for a feature that has a `story.md` or a pending story; a feature without one MUST see no Questmaster-triggered behavior. Each assessment MUST also be re-invocable on demand as a standalone command, independent of the hook firing.
- **FR-031**: System MUST persist the full output of every Specification and Plan Integrity assessment (dimension bands with evidence, every Drift Classification, source digests per FR-040, and the independence label per FR-037) as a dedicated report file alongside the assessed artifact (`spec-integrity.md`, `plan-integrity.md`), overwriting the previous report on each re-run.

**Retired requirements**

- **FR-032** *(retired 2026-09-13a)*: previously "System MUST define — but is not required to implement — a Final Quest Integrity synthesis method." Retired as untestable: the requirement was satisfied by its own existence and could not be failed. The synthesis method it described is preserved as design intent under Out of Scope, where it belongs. The number is retired rather than reused, to keep prior cross-references honest.

### Key Entities

- **Quest Story (`story.md`)**: The problem-framing artifact produced by `/speckit-questmaster-story` for a single feature; nine core, four extended, and four recorded sections (FR-003). The anchor all later Integrity assessments compare against.
- **Problem / Need / Outcome / Requirement / Solution**: The five conceptual layers every artifact must keep distinct; not files, but a discipline enforced at every stage.
- **Use Case**: A meaningful interaction captured in the story: actor, goal, trigger, expected result, key alternate/failure paths. Provides evidence for one or more functional requirements in `spec.md`.
- **Scope Boundary**: The story's In-Scope, Out-of-Scope, and Adjacent Concerns lists — a bounded definition later assessments use to detect scope creep.
- **Known Fact / Assumption / Unknown / Decision**: The four categories the story and later artifacts track separately.
- **Dragon's Questions**: The adversarial challenges raised against a story (FR-034) and the developer's verbatim responses, including dismissals.
- **Judgment Ledger**: The record of developer-originated contributions across the lifecycle (FR-035); sole evidence base for the `developer_judgment` dimension and for distinguishing a used process from a watched one. A subsection of the Questmaster Record.
- **Band**: One of `ABSENT`/`WEAK`/`ADEQUATE`/`STRONG`, assigned per dimension against anchored definitions; the unit of judgment from which all numeric scores are computed (FR-036).
- **Story Integrity Score**: The 0-100 result computed from the story rubric's bands (FR-010, FR-036), with per-dimension evidence. Recorded in the story's Story Integrity Assessment section; not a separate file.
- **Story Readiness Status**: One of `NOT_READY` / `NEEDS_CLARIFICATION` / `READY` / `READY_WITH_ACCEPTED_RISK` (FR-012), determined by named critical conditions plus, secondarily, the score threshold — never by score alone.
- **Scoring Rubric**: A named, weighted set of dimensions with anchored band definitions (plus, for the story rubric, a readiness threshold and critical-condition list). Project-editable configuration in a single YAML file (FR-024).
- **Integrity Assessment**: An independent (FR-037), evidence-based comparison of one artifact against the artifact(s) preceding it, producing per-dimension bands, an overall score, and Drift Classification findings; triggered via hooks (FR-030), re-runnable on demand, presented decision-first (FR-038), and persisted with source digests (FR-031, FR-040).
- **Comprehension Checkpoint**: Three fixed questions about a plan on first run, and one further previously unasked question on each re-run, asked before any assessment is shown, answered in the developer's own words or explicitly declined (FR-041).
- **Decision Worklist**: The at-most-three items requiring developer judgment that open every assessment (FR-038). When it is non-empty, its highest-severity item elicits a recorded response (FR-043); when it is empty, it says so and asks nothing.
- **Drift Classification**: The six-way judgment applied to every compared element at every artifact-to-artifact transition (FR-017).
- **Quest Drift Finding**: The structured record produced for a `DISCOVERED`, `ACCEPTED_SCOPE_CHANGE`, or `UNJUSTIFIED_DRIFT` classification (FR-018).
- **Outstanding Accepted Risk**: A knowingly accepted gap, with date and the developer's own reason, re-surfaced at every later stage until resolved — either explicitly by the developer or by an evidence-backed, attributed, reopenable auto-resolution (FR-039).
- **Traceability Identifier**: An optional `ST-`/`UC-`/`REQ-`/`SC-`/`TASK-`/`TEST-` label assigned where it adds value (FR-023).
- **Questmaster Record**: The in-artifact section (not a separate file) holding an artifact's Judgment Ledger, Comprehension answers, and Decisions (FR-027).
- **Pending Story**: A `story.md` written before a feature directory exists, held at `.specify/extensions/questmaster/pending-story.md` and relocated into the feature directory by the `after_specify` hook (FR-029).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A developer starting from a single vague sentence can complete `/speckit-questmaster-story` and receive a banded, readiness-classified `story.md` with every core section present (and every inapplicable extended section explicitly marked N/A) in one guided session, without manually structuring the document themselves.
- **SC-002**: For 100% of bands produced in any assessment, the developer sees at least one specific, dimension-linked piece of evidence — never a band or a number alone.
- **SC-003**: For 100% of Specification and Plan Integrity assessments, every compared requirement, behavior, or technical decision receives exactly one Drift Classification in the persisted report, and every `DISCOVERED`/`ACCEPTED_SCOPE_CHANGE`/`UNJUSTIFIED_DRIFT` finding is reported rather than silently omitted.
- **SC-004**: A developer can change a project's story readiness threshold, critical-condition list, rubric weights, and band anchors through configuration alone, with no changes to command behavior, and see the new values reflected in the next assessment.
- **SC-005**: Given a paired example of a faithful quest and a drifting quest, Drift Classification marks the unsupported additions `UNJUSTIFIED_DRIFT` (or `ACCEPTED_SCOPE_CHANGE` where a matching Decision exists) in the drifting example, and marks the legitimate elaborations `REFINED`/`CLARIFIED`/`PRESERVED` in the faithful example.
- **SC-006**: For a project that has not created any `story.md`, every standard Spec Kit command produces its normal output with no Questmaster-related errors, warnings, or required steps — and installing Questmaster changes zero bytes of any existing Spec Kit command, skill, or script file.
- **SC-007**: A story is never classified `READY` while any named critical condition remains unmet, even at a score above the threshold; and a developer is always given an explicit revise/accept choice rather than being silently blocked or silently waved through.
- **SC-008**: For a proposed solution supplied at the start of an interview, the resulting story separately records the proposal and states which parts are requirements, which implementation detail, which assumptions, and whether it unnecessarily constrains the problem statement.
- **SC-009**: Scoring an unchanged artifact against an unchanged rubric twice reproduces at least 90% of dimension bands identically and an overall score within five points (FR-036).
- **SC-010**: A story cannot reach `READY` with an empty Judgment Ledger, and every Judgment Ledger entry traces to something the developer wrote rather than something they approved (FR-012, FR-035).
- **SC-011**: Every Dragon Pass raises between two and three challenges on a Short Quest (three to five on a Full Quest), each citing specific content from the story under challenge, and 100% of challenges receive a recorded developer response — answered, accepted, or explicitly dismissed (FR-034).
- **SC-012**: Every Integrity assessment presents at most three decisions before any score or full finding list, states explicitly when no decision is required, and a developer can determine what is required of them within the first screen of output (FR-038); and where the worklist is non-empty, the developer's response to its highest-severity item — resolved, accepted, deferred, or recorded as unanswered — exists in the Questmaster Record before the next stage begins (FR-043).
- **SC-013**: Every Plan Integrity assessment is preceded by the Comprehension Checkpoint, and the checkpoint result — three verbatim answers on the first run, one further answer to a previously unasked question on each re-run, or a recorded decline — exists in `plan.md`'s Questmaster Record before any assessment content is shown (FR-041).
- **SC-014**: Every accepted risk is restated at every subsequent stage, with its acceptance date and the developer's own reason, until it is recorded as resolved (FR-039); and no acceptance is ever recorded without a developer-written justification (FR-014).
- **SC-015**: Every Integrity assessment is either performed independently of the authoring context or visibly labelled `SELF-ASSESSED` in both the response and the persisted report (FR-037).
- **SC-016**: Band assignment, readiness classification, and Drift Classification are each evaluated against a corpus of fixtures carrying human-assigned expected results, and every evaluation run reports an agreement rate per corpus alongside the run-to-run variance of SC-009. The provisional target is at least 80% agreement with the human labels; where a corpus falls below it, the response is to coarsen the rubric or sharpen the band anchors, never to lower the target (Constitution Principle XII).

## Assumptions

- The target environment is a project using GitHub Spec Kit (`1.0.2.dev0` installed locally at the time of writing; mechanism details in this revision are additionally confirmed against a direct clone of `github/spec-kit`'s current source, per research.md §12, since the locally installed copy's files alone do not show the CLI's internal registration/hook/config-resolution logic) with its standard lifecycle; Questmaster is delivered as a real Spec Kit **extension** (not a preset — see FR-042) and, per FR-042, modifies none of Spec Kit's own files.
- The primary interface is Claude Code slash commands/skills, but the story, rubric, and assessment logic is designed to avoid unnecessary Claude-Code-specific coupling. Independent assessment (FR-037) is the one capability whose *quality* depends on the host offering a fresh-context mechanism; where it does not, FR-037's labelling requirement keeps the limitation visible rather than hidden.
- "Sufficient evidence" to end an interview, and which extended sections are material to a given feature, are matters of engineering judgment applied at run time, bounded by the budgets in FR-033 rather than a fixed question count.
- Default rubric weights and band anchors are sensible, explainable starting points (FR-010/FR-015/FR-016, `contracts/questmaster-config.yml`), project-editable rather than fixed constants.
- Band-level judgment is assumed to be reproducible where free-integer scoring is not. FR-036's threshold (90% of bands, ±5 points) and SC-016's agreement target (80%) are both starting assumptions to be validated by the fixture-corpus evaluation, not measured results; if evaluation shows bands are not reproducible at that level, or that agreement with the human labels falls short, the response is to coarsen the rubric further or sharpen the band anchors, not to relax the requirement.
- All scores, assessments, and findings are advisory: the developer always makes the final call, and no artifact is auto-modified, blocked, or rejected — including a story classified `NOT_READY`.
- Questmaster is opt-in per project: a project without a `story.md` or pending story sees no change to existing Spec Kit behavior.
- Gamified framing is a naming and presentation layer in this release. The Dragon is the one narrative element implemented as behaviour rather than vocabulary (FR-034), because an adversarial pass is cheap and is where the framing earns its keep; elaborate gamification (persistent XP, monsters as visual entities, a web UI) remains out of scope.

## Out of Scope (this release)

- Drift Classification and Integrity assessment at the Tasks, Implementation, and Final Review stages — the cross-artifact model extends cleanly to them, but no `/quest-review`, `/quest-complete`, or equivalent command is implemented here. *(The review that drove the 2026-09-13a revision recommended trading Plan Integrity scoring for Tasks-stage comprehension; that trade is recorded in the Revision Note as an open decision rather than made silently.)*
- **Final Quest Integrity synthesis** (formerly FR-032, retired as a requirement, retained here as design intent): a future synthesis across stages should not average per-stage results. It should identify the strongest phase, the weakest phase, the largest loss of intent, the largest scope expansion, the most significant unresolved risk, and the most significant technical divergence, and produce a written overall assessment naming a primary weakness and a primary recommendation alongside a per-phase summary. This release produces the per-stage inputs such a synthesis would consume.
- A web UI, database, multiplayer functionality, persistent XP, elaborate graphics, external SaaS integrations, or automated developer performance measurement. The Judgment Ledger (FR-035) is explicitly not a productivity metric: it is per-feature evidence for one rubric dimension and for the developer's own benefit, and MUST NOT be aggregated across developers or over time to measure individuals.
- Mandatory, universally-applied traceability identifiers on every story/spec/plan element — identifiers are applied selectively per FR-023.
- Automated enforcement of the FR-033 process budgets. The budgets are design targets; measuring and reporting actual interview duration is deferred.
