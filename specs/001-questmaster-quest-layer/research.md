# Phase 0 Research: Questmaster — Quest Layer for the Spec Kit Lifecycle

All product-level ambiguities were resolved during `/speckit-clarify` (see `spec.md` →
Clarifications) and, for the 2026-09-13a revision, during a critical review documented in
`spec.md`'s Revision Note. This document resolves the remaining **technical/mechanical**
decisions needed to design Phase 1 artifacts, grounded in inspection of the installed Spec Kit
(`1.0.2.dev0`, Claude integration, `ai_skills: true`, sequential feature numbering) in this
repository, and — as of the 2026-09-13b correction (§12) — in a direct clone and code-level
inspection of `github/spec-kit` itself, since several mechanical decisions below turned out to
depend on CLI internals (`src/specify_cli/`) that a locally installed project's files alone do
not show.

## 1. Command naming convention — CORRECTED 2026-09-13b

> **Original decision (2026-09-12), retained for record**: the user-facing command would be
> `/quest-story` (hyphenated Claude Code skill name, directory `.claude/skills/quest-story/`),
> with `quest.story` used only as an internal/hook identifier. Hook-triggered assessment
> commands would follow the same pattern: `quest.check-spec` → `/quest-check-spec`,
> `quest.check-plan` → `/quest-check-plan`.
>
> **Original rationale**: every existing Spec Kit command observed in the locally installed
> project (`speckit-specify`, `speckit-plan`, etc.) is a hyphenated Claude Code skill; the
> dotted form (`speckit.specify`) appeared only in hook `command:` fields and workflow YAML.
> `/quest-story` was judged to preserve the user's naming intent while matching the one
> convention every other command in the project followed.

**Corrected decision**: the user-facing commands are `/speckit-questmaster-story`,
`/speckit-questmaster-check-spec`, and `/speckit-questmaster-check-plan`, registered under the
internal ids `speckit.questmaster.story`, `speckit.questmaster.check-spec`, and
`speckit.questmaster.check-plan` in Questmaster's own `extension.yml` manifest
(`contracts/extension.yml`). Free-form aliases (`speckit.quest-story`, etc.) are additionally
registered where a shorter invocation is wanted, rendering to `/speckit-quest-story` — still
`speckit-`-prefixed, since that prefix is not something an alias can escape (see below).

**Why the original decision was wrong, not just suboptimal**: the original rationale reasoned
from what a hyphenated Claude skill *looks like*, which was correct as far as it went, but never
checked what actually *makes a hook fire correctly* or *what command-id shape the extension
registration system will accept at all*. Direct inspection of the real `specify_cli` source
settles both questions and neither one has a "use your own judgment" answer:

1. **The extension safety check only recognizes `speckit.<ext-id>.<cmd>` (3+ dot segments)**
   (`presets/ARCHITECTURE.md`'s Command Registration diagram; confirmed against the working
   `extensions/git/extension.yml`, whose five commands are all `speckit.git.*`). A command id
   with only two segments and no `speckit.` prefix — `quest.story` — is not recognized as either
   a core command or a valid extension command by this system at all.
2. **`HookExecutor._skill_name_from_command`** (`src/specify_cli/extensions/__init__.py:4799`)
   does `if not command_id.startswith("speckit."): return ""`. A hook whose `command:` field is
   `quest.check-spec` gets no skill-name translation and the renderer falls through to a literal,
   non-invocable `/quest.check-spec` (the dotted string, unrendered) rather than a working
   `/speckit-...` slash command. The original design's `contracts/extensions.yml` would have
   shipped a hook that silently never actually fires correctly against the real hook renderer.
3. **`CommandRegistrar._compute_output_name`** (`src/specify_cli/agents.py:559`) computes every
   Claude skill's on-disk name the same way regardless of input: strip a leading `speckit.` if
   present, replace remaining dots with hyphens, then **unconditionally re-prepend `speckit-`**.
   There is no code path that produces a bare `speckit-story`-free name like `quest-story` from
   the command-registration system — even a fully free-form alias renders through this same
   function, so the closest achievable short form is `/speckit-quest-story`, never the original
   brief's bare `/quest-story`.

None of this is a style preference the original research could have reasonably guessed at from
the locally installed project's `.claude/skills/` directory alone, since that directory shows
only the *output* of this naming function for already-correctly-named core commands
(`speckit-specify`, `speckit-plan`) — it never shows what happens to an incorrectly-shaped input,
because no incorrectly-shaped input had ever been registered.

**Alternatives considered**: keeping `/quest-story` by deliberately not using the extension
registration system at all — hand-authoring `.claude/skills/quest-story/` directly and
hand-writing `.specify/extensions.yml`'s hook entries with a plain `quest.check-spec` string
(which does still work as a literal command for an LLM-driven agent reading YAML, per the
templates in `templates/commands/*.md`, since those templates run the *literal* `command:`
value as a slash command themselves rather than routing it through `HookExecutor`). This was a
real, viable option — raised explicitly with the developer — and rejected in favor of full
compliance: it would have forfeited real condition evaluation (§4), automatic multi-agent
registration (`CommandRegistrar` writes `.claude/`, `.gemini/`, `.github/agents/`, and 14+ other
agent directories from one manifest), and catalog publishability, all for a shorter command name.

## 2. How `/quest-story` gets a feature directory (FR-029) — SUPERSEDED 2026-09-13a

> **Original decision (2026-09-12), retained for record**: `/quest-story` inlines the same
> directory/number-resolution steps `speckit-specify`'s own Outline performs, allocating the
> feature directory itself before writing `story.md`.
>
> **Original rationale**: `speckit-specify`'s Claude skill does not call
> `create-new-feature.sh` — it performs numbering/mkdir/persist directly in its own Outline
> prose, which also unconditionally stubs an empty `spec.md`, a side effect premature for a
> command meant to run before any specification exists. Mirroring the inline approach kept
> directory-allocation behavior identical across both commands.

**Superseding decision (2026-09-13a, path corrected 2026-09-13b)**:
`/speckit-questmaster-story` allocates **nothing**. When no feature directory exists, it writes
the story to a single fixed location, `.specify/extensions/questmaster/pending-story.md` —
Questmaster's own extension config directory (`ConfigManager.extension_dir`, confirmed in §12),
not a bespoke top-level path — and stops there. No directory, no branch, no number, no
`.specify/feature.json` write. See §3 (superseded) for why the original design's downstream
consequence — editing `speckit-specify` — is what this change exists to avoid, and
`data-model.md`'s Pending Story section for the full state-transition table.

**Rationale for reversal**: The review that drove this revision asked a different question of
the same fact pattern. The original research correctly established that *no existing mechanism*
in this Spec Kit installation can express "reuse a directory `/quest-story` already created" from
inside `speckit-specify` without editing that skill's own file — hooks fire before or after a
skill's Outline, never inside it, and presets substitute template *content*, never control flow.
That conclusion was sound. What it evaluated, though, was only the space of *mechanisms* for
satisfying FR-029 as originally written ("`/quest-story` allocates the feature directory
itself"). It never asked whether that requirement was worth its cost. A permanent edit to a
vendored Spec Kit skill — one that has to be re-applied or merge-resolved on every future Spec
Kit upgrade, forever, for every project that installs Questmaster — is exactly the kind of
standing cost Constitution Principle XI exists to avoid, and the "conditional pass" the original
plan recorded for it was the loudest warning sign in that document.

The actual constraint the developer needs is an *ordering* one: the story must exist before the
spec is written, so the spec can be checked against it. Nothing requires
`/speckit-questmaster-story` to be the directory's origin. Making `/speckit-specify` (unmodified)
the sole allocator, and having its own **template** — a mechanism `speckit-specify` already uses
in its designed, supported way — pick up a pending story as its input, satisfies the same
ordering constraint with zero edits to any existing Spec Kit file. FR-042 was added specifically
to make this constraint explicit and prevent the trade-off from being silently re-opened toward
the file edit under time pressure. §12 confirms this mechanism directly against the real
`templates/commands/specify.md`, rather than only inferring it from the locally installed copy.

**Alternatives considered**:
- The original directory-self-allocation design — rejected per the above; it is the one
  remaining source of a Principle XI violation in the entire feature, and removing it costs
  nothing acceptance-visible (see spec.md User Story 1, unchanged).
- Shelling out to `create-new-feature.sh --short-name ...` for the pending case — rejected
  because it also unconditionally creates a stub `spec.md`, and because a single fixed pending
  location is simpler than a second numbering path that only sometimes runs.

## 3. Where FR-029's "reuse existing directory" logic must live — SUPERSEDED 2026-09-13a

> **Original decision (2026-09-12), retained for record**: a minimal, additive edit to
> `.claude/skills/speckit-specify/SKILL.md`'s Outline step 3, checking for an existing
> `story.md` before allocating a new directory number.
>
> **Original rationale**: judged unavoidable — hooks cannot intercept mid-Outline, and the
> template stack only customizes content. Recorded in the original plan.md's Complexity
> Tracking table as the one Principle XI exception.

**Superseding decision (2026-09-13a, mechanism confirmed 2026-09-13b)**: no edit to
`speckit-specify` is made or needed. `speckit-specify` runs completely unmodified, exactly as it
does for a non-adopting project. The one place Questmaster logic executes is *inside
`/speckit-questmaster-check-spec`* (a new, additive command), whose first step — run by the
`after_specify` hook, which already fires unconditionally after `speckit-specify` completes —
checks for `.specify/extensions/questmaster/pending-story.md` and, if present, moves it into the
feature directory `speckit-specify` just created, naming it `story.md`, before running the
Specification Integrity assessment against it. The spec template itself carries a Questmaster
addendum that references the pending story's content where present — delivered as an
**extension-provided template** (`contracts/extension.yml`'s `provides.templates`, `strategy:
prepend`), not a preset, since Questmaster is registered as an extension, not a preset (§12) —
so a developer who ran `/speckit-questmaster-story` first sees their story reflected in the
drafted `spec.md`, using the mechanism Spec Kit already provides for exactly this purpose,
without changing `speckit-specify`'s control flow.

**Why this fully resolves the exception, rather than relocating it**: the original edit was
necessary specifically to change *which directory gets allocated*. The new design never needs to
change that — `speckit-specify` always allocates its own directory, always by its own existing
logic, unconditionally. The only new behavior is what happens *after* that directory exists,
which is squarely inside `after_specify`'s designed purpose and entirely inside a new file
(`speckit.questmaster.check-spec`'s own logic). Constitution Principle XI's Complexity Tracking table
(`plan.md`) is now empty — there is no exception left to justify.

**Alternatives considered**:
- Leave `speckit-specify` untouched and accept a second, conflicting numbered directory —
  rejected in the original 2026-09-12 pass and still rejected; the pending-story mechanism is
  precisely how this is now avoided without an edit.
- A `before_specify` hook relocating the pending story before `speckit-specify` runs — rejected:
  `before_specify` fires before the feature directory exists, so there is nothing to relocate
  into yet; the relocation can only happen after directory allocation, i.e. in `after_specify`.

## 4. Hook wiring for automatic Integrity assessments (FR-030) — rationale corrected 2026-09-13b

**Decision (unchanged)**: `hooks.after_specify` and `hooks.after_plan` — declared in
Questmaster's own `extension.yml` and, once installed, registered into the project's
`.specify/extensions.yml` — point at `speckit.questmaster.check-spec` /
`speckit.questmaster.check-plan`, **with no `condition` field**. The `story.md`-existence check
(i.e., "only do anything when this feature has adopted Questmaster") is performed as the *first
step inside* `/speckit-questmaster-check-spec` and `/speckit-questmaster-check-plan` themselves:
when no `story.md` exists for the active feature (and no pending story to relocate — see §2/§3
above), the command exits immediately, writes no report file, and adds no visible output — so a
non-adopting project's `/speckit-specify`/`/speckit-plan` completion report is unaffected
(FR-025).

**Corrected rationale**: the original claim — "no HookExecutor exists in this bash/Claude-only
installation" — is factually wrong and is corrected here rather than silently fixed, since the
*conclusion* (ship every Questmaster hook with no `condition` field) still holds for a different
reason than originally stated. Direct inspection of `github/spec-kit` (§12) found a real,
working `HookExecutor` class (`src/specify_cli/extensions/__init__.py:4771`) whose
`_evaluate_condition` method genuinely parses and evaluates `config.<path> is set`,
`config.<path> == 'value'`, `env.<VAR> is set`, and `env.<VAR> == 'value'` condition
expressions — this is real, shipped code, not a stub.

What *is* true, and is the actual reason an unconditioned hook is the only reliable choice: the
LLM-facing command templates that an interactive Claude Code session follows
(`templates/commands/specify.md`, `plan.md`, etc. — confirmed verbatim in the cloned repo) tell
the agent itself, in prose, to skip any hook with a non-empty `condition` and "leave condition
evaluation to the HookExecutor implementation" — and never instruct the agent to invoke that
Python class (there is no `specify hooks ...` CLI subcommand anywhere in the templates the agent
is told to shell out to). The `HookExecutor` exists and is presumably exercised by some other,
non-agentic invocation path within `specify_cli` itself, but an interactive agent session
following these templates never reaches it. The practical conclusion is identical to the
original — no Questmaster hook should carry a `condition` field, because nothing in this
invocation path will ever evaluate one — but the reason is "the agent is explicitly told not to
evaluate it and has no path to the component that could," not "the component doesn't exist."

**Alternatives considered**: Using `condition:` as documented, relying on the real
`HookExecutor` to evaluate it — rejected for the same practical reason as before (an
interactive Claude Code session never invokes that code path), now correctly attributed.

## 5. Rubric dimensions and weights (spec.md FR-010/FR-015/FR-016, revised 2026-09-13a)

> **2026-09-12b decision, retained for record**: nine-dimension Specification Integrity rubric
> and ten-dimension Plan Integrity rubric, organized around *how* fidelity is judged (story
> fidelity, scope discipline, traceability, handling of ambiguity) rather than *what* is checked
> for coverage, replacing the original spec's coverage-pair structure. Full detail was recorded
> in that revision of `contracts/questmaster-config.yml`.

**Superseding decision (2026-09-13a)**: the dimension sets are consolidated further, and scoring
mechanics change from free-integer assignment to anchored bands (see §6 below).

- **Story rubric** (FR-010): ten dimensions unchanged in count, but `background_context` merges
  into `constraints_and_context`, `actors_users` becomes `actors_and_current_state` (absorbing
  current-behavior coverage), and a new **`developer_judgment`** dimension (weight 10) is added,
  banded from the Judgment Ledger alone. Total weight is rebalanced to remain 100.
- **Specification Integrity rubric** (FR-015): nine dimensions collapse to **seven**:
  `requirement_clarity` + `acceptance_testability` → `requirement_testability`;
  `handling_of_assumptions` + `handling_of_unknowns` → `handling_of_ambiguity`. Weights shift
  toward `scope_discipline` (20) and `story_fidelity` (20) as the two dimensions most load-bearing
  for catching drift.
- **Plan Integrity rubric** (FR-016): ten dimensions collapse to **eight**:
  `architectural_appropriateness` + `complexity` + `unnecessary_scope` →
  `proportionality`; `technical_constraint_coverage` folds into `specification_coverage`. A new
  **`legibility`** dimension (weight 15) is added — whether a developer who did not author the
  plan can follow it — banded independently of technical correctness.

Full detail: `contracts/questmaster-config.yml`.

**Rationale**: The 2026-09-12b redesign was the right shape (judge *how* fidelity holds, not
enumerate a coverage checklist) but the review that drove this revision found two gaps a
dimension-count reduction alone would not fix, addressed by the two additions rather than by
further collapsing:

1. **No dimension anywhere measured what a developer actually did.** `developer_judgment` gives
   Principle VII (Reward Engineering Judgment) — asserted in the original plan's Constitution
   Check but unbacked by any rubric — an actual scored expression, and it is deliberately banded
   from a different evidence source (the Judgment Ledger) than every other dimension, so it
   cannot be inflated by better AI writing.
2. **No dimension distinguished a correct plan from a comprehensible one.** `legibility` exists
   because the reported failure mode is developers not understanding plans that may well be
   technically sound — a plan can score `STRONG` on every technical dimension and still fail the
   actual problem Questmaster exists to solve if no dimension checks whether a human can follow
   it.

Collapsing dimension counts (29 → 25 total) is a secondary benefit of the same review: several
of the original dimensions (`handling_of_assumptions` vs. `handling_of_unknowns`,
`architectural_appropriateness` vs. `complexity` vs. `unnecessary_scope`) asked an assessor to
draw a distinction between near-identical judgments the same evidence would support either way —
ceremony, per Constitution Principle IX, not rigor.

**Alternatives considered**: Keeping 29 dimensions and only adding the two new ones (31 total) —
rejected; the review's proportionality finding (Constitution IX, revised) applies to the rubric
itself, not only to the story's section count. Adding `developer_judgment` to the Specification
and Plan rubrics as well as the story rubric — rejected for this release: the Judgment Ledger is
cumulative across the whole feature and re-scoring the same ledger at every stage would double
(triple) count the same evidence; a future Final Quest Integrity synthesis (Out of Scope) is the
more natural place to look at judgment across the whole lifecycle at once.

Neither Integrity rubric defines a pass/fail **readiness threshold** — FR-022 prohibits any
assessment from blocking or gating an artifact, and no requirement calls for a spec/plan gate
analogous to FR-012's story gate. Bands and Drift Classification findings are presented together,
advisory only, decision-first (FR-038).

## 6. Bands instead of free-integer scores (spec.md FR-036, new in 2026-09-13a)

**Decision**: Every rubric dimension, in every assessment, is judged as exactly one of four
anchored bands (`ABSENT`/`WEAK`/`ADEQUATE`/`STRONG`), each with a per-dimension anchor definition
published in `contracts/questmaster-config.yml`. A band converts to a numeric contribution via a
fixed multiplier (0 / ⅓ / ⅔ / 1 of the dimension's weight); the 0-100 overall score is the sum of
those contributions, never assigned directly.

**Rationale**: The original design let an LLM assessor pick any integer 0-15 (or whatever a
dimension's weight was) for each dimension, then present the sum as if it were meaningful to one
point of precision. Nothing in that design bounded how much such a score would move if the same
artifact were assessed twice with no changes — and free-integer judgment at that resolution does
move, by several points, run to run, on the same input. Once a developer sees an unedited
document's score change between runs, every score in the system — and every drift finding
presented next to it — loses credibility, which defeats the evidence-based posture Constitution
Principle V exists to protect. Reducing the number of distinguishable outcomes per dimension from
"any integer" to four named bands, each with a written anchor describing what STRONG actually
looks like for that specific dimension, asks the assessor for the resolution of judgment an LLM
can actually sustain, and makes the reproducibility target in FR-036/SC-009 (90% of bands
identical, score within five points on re-assessment) a testable, falsifiable claim rather than
an aspiration.

**Alternatives considered**: Keeping free-integer scores but adding a stated confidence interval
— rejected as more ceremony for the developer to parse, without actually constraining the
assessor's judgment the way a fixed anchor set does. A 10-point scale (1-10 per dimension) —
rejected as splitting the same difference without evidence that 10 distinguishable levels are any
more reproducible than free integers; 4 named, anchored bands is the smallest set that still lets
"present but weak" be distinguished from "present and strong."

## 7. Independent assessment (spec.md FR-037, new in 2026-09-13a)

**Decision**: Every Specification and Plan Integrity assessment MUST be invoked in a context that
has never seen the conversation that authored the artifact under assessment — concretely, as a
subagent/fresh-session invocation seeded only with the artifact files, the rubric configuration,
and the relevant Questmaster Records, rather than as a continuation of the same session that ran
`/speckit-specify` or `/speckit-plan`. Where the hook-firing mechanism in a given host has no way
to start such a context, the assessment still runs in whatever context is available, but its
output — in the response and in the persisted report — is labelled `SELF-ASSESSED`, a label with
no configuration flag to suppress it.

**Rationale**: This is the single highest-leverage change identified by the review. An assessor
asked to find fault in text it just wrote, with its own reasoning about that text still present
in context, exhibits the same anchoring a person would: it rates its own recent work favorably and
is predisposed to classify its own scope additions as justified refinement rather than drift. This
is not a prompt-wording problem — telling the assessor "be skeptical of your own prior work" does
not remove the anchor, because the disqualifying information (what it just decided, and why) is
still in the context window regardless of instruction. The only structural fix is to not let that
context reach the assessment at all. Claude Code's Agent tool (subagent spawning) is the concrete
mechanism available in this environment; `speckit.questmaster.check-spec`/
`speckit.questmaster.check-plan`'s own skill definitions are expected to invoke their assessment logic via a subagent call rather than
in-line reasoning, specifically so the hook-triggered, automatic case (FR-030) — the case least
likely to get a careful human double-check before being trusted — is also the case least likely to
be a self-assessment.

**Alternatives considered**: Relying on prompt instructions alone ("assess this as if you did not
write it") — rejected per the above; anchoring is a property of context contents, not of
instructions given within that context. Requiring a human reviewer for every assessment before it
is trusted — rejected as contradicting the advisory, lightweight posture the whole methodology is
built on (Constitution Principle IX); the `SELF-ASSESSED` label achieves the same transparency
goal (the developer knows not to over-trust this particular result) without adding a mandatory
human step.

## 8. Developer participation: Judgment Ledger, Dragon Pass, Comprehension Checkpoint (spec.md
FR-034/FR-035/FR-041, new in 2026-09-13a)

**Decision**: Three linked mechanisms give Principle VII an actual, scored expression:

1. The **Judgment Ledger** records every contribution that could only have come from the
   developer — a challenge, a cut, an asserted fact or constraint, a dismissed or accepted risk,
   a comprehension answer — as a subsection of each artifact's Questmaster Record, using a fixed
   `{date, stage, kind, developer_words, effect}` schema (data-model.md).
2. The **Dragon Pass** runs at the story stage, after the interview and before scoring: a bounded
   number of adversarial, story-specific challenges, each requiring a recorded response.
3. The **Comprehension Checkpoint** runs at the plan stage, before any assessment is shown: three
   fixed questions whose answers cannot be derived from the plan itself, recorded verbatim.

The story rubric's `developer_judgment` dimension (§5) is banded from the ledger alone, and the
story readiness gate's `no_developer_judgment_recorded` critical condition (FR-012) makes `READY`
unreachable with an empty ledger, regardless of score.

**Rationale**: The review's central finding was that every rubric dimension in the original
design measured document completeness — a property entirely of the AI's writing — while
Constitution Principle VII commits the project to rewarding engineering judgment, a property of
the developer. Those two things were never in tension in the design; they were simply never
connected. The fix is not "add a judgment dimension" in the abstract (a dimension needs evidence,
and nothing was collecting evidence a developer, specifically, produced) — it is these three
concrete elicitation points, each designed so that the response cannot be produced by the AI on
the developer's behalf (a genuine dismissal, an asserted fact the AI had no way to know, a
prediction made before seeing the assessment), plus one ledger that makes that evidence available
to scoring wherever it's needed.

**Alternatives considered**: Scoring "developer engagement" from message count or interview
length — rejected explicitly; Constitution Principle VII prohibits rewarding volume or speed, and
message count is exactly the kind of proxy that would reward talking more rather than judging
better. Making the Dragon Pass and Comprehension Checkpoint optional/configurable-off — rejected
for v1: an optional judgment-elicitation step is a step that gets turned off under the exact
deadline pressure it exists to counteract; both remain non-blocking (a decline/dismissal is a
valid, recorded response) without being skippable outright.

## 9. Decision-first reporting and carry-forward (spec.md FR-038/FR-039/FR-040, new in 2026-09-13a)

**Decision**: Every Integrity report leads with a Decision Worklist (at most three items, highest
severity first), then any Outstanding Accepted Risk carried from earlier stages, then the banded
dimension summary, then the full findings (aggregated for non-actionable classifications, full
detail in an appendix). Every persisted report records a content digest of each source artifact,
so a later run can detect and state when an upstream artifact has changed since the report was
written.

**Rationale**: The original report structure — a full dimension table followed by one
classification-table row per compared element — was designed for completeness and, per the
review, was read by nobody: a 30-row table where 27 rows say `PRESERVED` communicates nothing on
a skim and gets skimmed anyway. The fix inverts what leads: a developer opening the report should
be able to tell, in the time it takes to read three lines, whether anything requires them to
decide something right now. Persisting is still complete — nothing is dropped, only reordered and
aggregated in the *presented* view — so SC-003's "every element gets a classification" guarantee
is unaffected. Digests exist because the previous design's staleness warning ("tell the developer
downstream reports may now be stale") was pure assertion with nothing to check it against; a
digest mismatch turns a hedge into a fact.

**Alternatives considered**: A single unified severity-sorted list with no cap — rejected; an
unbounded list re-creates the original problem at a different sort order. Summarizing everything
and dropping the full appendix — rejected; SC-003 requires every element to receive and retain a
classification somewhere, and an appendix is the cheapest way to keep that guarantee without
cluttering the primary view.

## 10. Final Quest Integrity: requirement retired, design intent preserved (spec.md, formerly
FR-032; retired 2026-09-13a)

**Original decision (2026-09-12b), retained for record**: `spec.md` would formally define the
Final Quest Integrity synthesis method (no simple averaging; identify strongest/weakest phase,
largest loss of intent, largest scope expansion, most significant unresolved risk, most
significant technical divergence) as FR-032, without implementing `/quest-review`/
`/quest-complete` in this release.

**Superseding decision (2026-09-13a)**: FR-032 is retired as a *requirement*. "System MUST
define — but is not required to implement" a method is satisfied by the sentence's own existence
and cannot be failed by any implementation; it was a design note wearing a requirement's clothes,
and Constitution Principle XII (testing the methodology) implicitly asks every requirement to be
the kind of claim a test could fail. The synthesis method's content is unchanged and is preserved
verbatim in `spec.md`'s Out of Scope section, where a future release implementing it has the same
ready contract to build against.

**Rationale**: Spotted during the review's pass over Functional Requirements for testability
(the same pass that produced FR-036's reproducibility requirement and FR-038's presentation
requirement). An untestable MUST is worse than no requirement at all: it occupies the same
document real estate as FR-001–FR-031, which are all genuinely falsifiable, and dilutes what
"MUST" means everywhere else in the same list.

**Alternatives considered**: Rewording FR-032 as a MAY — rejected as still redundant with simply
describing it in Out of Scope, where design intent for deferred work already lives elsewhere in
this spec (e.g. the Tasks/Implementation/Final Review stages).

## 11. Testing approach (Principle XII, revised 2026-09-13a, extended 2026-09-13c)

**Decision**: Three tiers, not two.

- **Deterministic tier** (unchanged in mechanism from the original design; path corrected
  2026-09-13b to match the real convention — §12): plain Bash assertion scripts under
  `tests/extensions/questmaster/`, run by a dependency-free
  `tests/extensions/questmaster/run.sh` — config parsing/fallback, band-to-score arithmetic, the
  readiness classification rule (including the critical-condition override and the new
  `no_developer_judgment_recorded` condition), and digest-mismatch detection.
- **Judgment tier**, now explicitly two fixture corpora rather than one (gap closed
  2026-09-13c — see below):
  1. **Story-rubric fixtures**: 8-10 complete `story.md` files (a finished document, not a live
     interview transcript — see Rationale for why the interview itself is out of scope for this
     tier), each with a human-assigned expected band per dimension and expected readiness
     classification, including at least one fixture per critical condition (unclear problem,
     unidentified actor, unbounded scope, and — specifically for FR-012's newest
     condition — an empty Judgment Ledger). Run through `/speckit-questmaster-story`'s scoring
     step N times, reporting agreement rate against the human labels and run-to-run variance.
  2. **Cross-artifact drift fixtures** (the original judgment-tier design, unchanged): a labelled
     corpus of 15-20 `story.md`/`spec.md` (and `story.md`/`spec.md`/`plan.md`) pairs, each with a
     human-assigned expected Drift Classification per element and expected band ranges per
     dimension, run through the check-spec/check-plan assessments N times. The faithful/drifting
     pair required by SC-005 is a subset of this corpus, not a separate set of files.
- **Governance tier** (new 2026-09-13c): an automated, independent re-verification of this
  feature's own Constitution Check — see below.

**Rationale (judgment tier gap, closed 2026-09-13c)**: the 2026-09-13a design's judgment tier
covered only cross-artifact Drift Classification (spec/plan against story) and had no fixture
coverage at all for the story rubric's own scoring and readiness-classification logic — the thing
`/speckit-questmaster-story` actually does. `quickstart.md`'s manual Scenarios A/A2/D/E/F do
exercise the story stage, but only as live, human-run interviews; nothing in the *automated*
suite checked whether the story rubric's bands and the readiness gate are applied correctly and
reproducibly on their own, independent of the drift-classification logic layered on top of them
in later stages. Story-rubric fixtures are pre-written completed `story.md` files rather than
interview transcripts specifically because the interview itself (a live, branching Socratic
dialogue whose question sequence depends on the developer's own answers) is not practically
fixture-able without either scripting a fake developer or losing exactly the property — natural,
unscripted answers — the interview exists to elicit; scoring a finished story against the rubric
is the part of `/speckit-questmaster-story` that *is* fixture-able, and was the part left
untested.

**Rationale (governance tier, new 2026-09-13c)**: Constitution Governance already requires that
"a constitution check MUST NOT be self-assessed by the context that authored the artifact under
review" and "MUST be re-run independently before the artifact is treated as having passed" — but
as originally written this was a one-off manual step, dependent on someone remembering to invoke
it, exactly the failure mode Principle XIII exists to prevent in every *other* stage of the
lifecycle. Automating it removes that dependency: `tests/extensions/questmaster/governance/
check_constitution.sh` spawns an independent agent (no access to the conversation that authored
`plan.md`) given only `constitution.md` and the artifact under check, asks it to verify every
Constitution Check row's claimed status against the actual principle text and cited evidence, and
fails the suite if any row is unsupported or overstated. This is the same independent-assessment
mechanism FR-037 already requires Questmaster to apply to a user's `spec.md`/`plan.md`, applied
reflexively to Questmaster's own planning artifacts, and it is the first thing the test suite runs
— a design whose own foundational compliance claims are unverified is not worth testing further.

`test_feature_reuse.sh` is retired along with the file-editing design it tested (§2/§3 above);
its replacement is `test_pending_story.sh`, exercising the pending-story write/relocate/consume
cycle purely as file operations (still deterministic).

**Alternatives considered**: Treating the judgment tier as out of scope for v1 and relying on
manual spot-checking — rejected; this is precisely the gap the review identified in Principle
XII's self-assessment ("PASS" was recorded in the original plan.md on the strength of the
deterministic tier alone), and leaving it unaddressed would repeat the same mistake this revision
exists to fix. `bats-core` or a Python test runner for either tier — rejected for the same
reasons as the original decision: no new external dependency, consistency with this repo's
all-Bash `.specify/scripts/`. Leaving the Constitution self-check as a manual, occasionally-run
step — rejected per the developer's explicit direction that the first verification should be
automated rather than something a human has to remember to trigger.

## 12. Questmaster is a Spec Kit extension, not a preset — and its delivery mechanism was wrong
(new in 2026-09-13b, prompted by directly inspecting `github/spec-kit`)

**Context**: the developer pointed at `presets/scaffold` in the upstream repo (whose README says
to download it as a starting point) and asked for a review of how Spec Kit presets are actually
scaffolded. Answering that properly required cloning `github/spec-kit` and reading
`presets/ARCHITECTURE.md`, `extensions/EXTENSION-DEVELOPMENT-GUIDE.md`, the real
`extensions/git/extension.yml` (a working precedent doing almost exactly what Questmaster needs
— new commands plus `hooks:` plus a delivered config file), and the relevant `specify_cli`
source (`presets/__init__.py`, `extensions/__init__.py`, `agents.py`). This surfaced three
corrections beyond naming (§1) and hook rationale (§4), and one confirmation.

**Finding — `presets/scaffold` is the wrong starting point for Questmaster itself**: a preset's
manifest (`preset.yml`) only supports `provides.templates` entries typed `template`/`command`/
`script`, and every `command`/`script` entry exists to *override* something already provided by
core or an installed extension (`replaces: <name>` is how the scaffold's own examples work,
and there is no example anywhere of a preset introducing a command, hook, or config file with no
prior existence). Presets also have no `hooks:` key at all. Questmaster's three commands are
net-new capability, not overrides — Constitution Principle XI already named this distinction in
prose ("extensions MUST be reserved for genuinely new capability that presets cannot express")
without the contracts ever adopting the actual extension manifest shape that follows from it.
`extensions/template/` (via `extensions/EXTENSION-DEVELOPMENT-GUIDE.md`'s quick start) is the
correct starting point; `presets/scaffold` remains the right download only for a possible future
companion preset (e.g., a standalone spec-template tweak with no new commands).

**Decision**: Questmaster ships `contracts/extension.yml`, a real extension manifest (schema
confirmed against `extensions/git/extension.yml` and the development guide): `provides.commands`
(`speckit.questmaster.story`/`check-spec`/`check-plan`, per §1), `provides.config`
(`questmaster-config.yml`, materializing via the real `ConfigManager` at
`.specify/extensions/questmaster/questmaster-config.yml` — corrected from the original design's
invented `.specify/questmaster/config.yml`; `extensions/__init__.py:4484` is unambiguous about
this path, and it comes with two free override layers Questmaster does not need to reimplement:
a gitignored `local-config.yml` and `SPECKIT_QUESTMASTER_<KEY>` environment variables),
`provides.templates` (`story-template` net-new, `spec-template` as a `prepend`-strategy
addendum — extensions can provide templates too, confirmed by
`EXTENSION-DEVELOPMENT-GUIDE.md`'s own list of valid `provides.*` sections and by
`ExtensionManifest._validate_provided_artifacts` accepting a `templates` section), and `hooks:`
(`after_specify`/`after_plan`, per §4). Development and local testing use the documented real
workflow: `specify extension add --dev ./extensions/questmaster`, mirroring
`EXTENSION-DEVELOPMENT-GUIDE.md`'s quick start.

**Repository layout implication**: Questmaster's own source now lives at
`extensions/questmaster/` at the repository root (mirroring how the upstream monorepo itself
lays out `extensions/git/`, `extensions/assess/`, etc.) rather than assuming its files are
hand-placed directly into `.claude/skills/` and a bespoke `.specify/questmaster/` tree. Tests
move to `tests/extensions/questmaster/`, matching the real convention observed in the cloned
repo (`tests/extensions/git/`, `tests/extensions/assess/`, `tests/extensions/bug/`) rather than
the original design's ad hoc `tests/questmaster/`. See plan.md's revised Project Structure.

**Confirmation, not correction**: the pending-story handoff mechanism itself (§2/§3) is fully
validated by this inspection, not merely re-justified. `templates/commands/specify.md` states,
verbatim, "The spec directory and file are always created by this command, never by the hook,"
and its own Outline step 3 names "Resolve the active `spec-template` through the Spec Kit
preset/template resolution stack" as a first-class, designed step — exactly the seam an
extension-provided template addendum uses. Nothing about the pending-story design itself needed
to change; only where its two files (config, pending story) actually live.

**Alternatives considered**: Treating this as cosmetic (fix paths, keep everything else) —
rejected; the naming correction (§1) is not cosmetic, since the original command ids would not
have produced working hook invocations at all against the real `HookExecutor`, and shipping
`contracts/extensions.yml` as a project-root file for a developer to hand-copy (the original
design) is a different, non-standard installation model from every other extension in the
ecosystem, which would have made Questmaster harder to install, update, and reason about
alongside any other installed extension for no offsetting benefit.

## 13. Mechanism seams closed by the 2026-09-13 clarification pass (spec.md FR-029, FR-034, FR-039, FR-040, FR-041)

**Context**: a `/speckit-clarify` pass run after this plan existed resolved five ambiguities. All
five sit where two independently-designed mechanisms meet — the place a specification is least
likely to be ambiguous on its face and most likely to be ambiguous in effect, because each
mechanism reads correctly on its own. They are recorded here as decisions rather than folded
silently into the artifacts they change.

**Decision 1 — a pending-story collision is refused, never merged or overwritten (FR-029)**.
`/speckit-questmaster-story` invoked for an unrelated request while an unclaimed pending story
exists states the pending story's Quest Title and requires an explicit revise / consume / discard
choice.

*Rationale*: the pending story lives at one fixed path precisely because no feature directory
exists yet to key it by (§2), so the mechanism that avoids editing Spec Kit's control flow is the
same mechanism that has nowhere to put a second story. The overwrite failure is not the lost
interview but the silent one after it: `/speckit-specify` relocates whatever sits at that path
into the newly created feature directory, so an unrelated story becomes the anchor every later
Integrity assessment compares against, and every drift finding it produces is confidently wrong.
Refusing costs one command; the alternative costs the credibility of the whole assessment chain.

*Alternatives considered*: treating the second run as a revision (the pre-clarification fall-through)
— rejected, it merges two unrelated problem statements into one document; overwriting with a
warning — rejected, a warning after destruction is not a choice; multiple slug-keyed pending
stories — rejected as scope, it re-introduces the feature-identity problem the single fixed path
was chosen to avoid, and no evidence suggests a developer needs two open interviews at once.

**Decision 2 — source digests exclude the `## Questmaster Record` section (FR-040)**.

*Rationale*: FR-027 writes the Questmaster Record into the same artifacts FR-040 digests, so a
whole-file digest makes Questmaster its own upstream change: accept a risk in `story.md` and the
next Specification Integrity run announces that the story changed since the previous report. §9
introduced digests specifically to convert a staleness hedge into a checkable fact — a fact that
fires on the system's own bookkeeping is back to being noise, with the added cost that developers
learn to dismiss it before the first real upstream edit arrives. Excluded content is still read
(Decisions gate `ACCEPTED_SCOPE_CHANGE` per FR-019); it is only excluded from what "this artifact
changed" means.

*Alternatives considered*: digest everything and accept the false positives — rejected for the
reason above; dual digests, full and body-only, reporting on the body-only — rejected as the same
rule with a second number nothing reads; per-section digests naming which section changed —
rejected as more machinery than the staleness signal needs, though it remains the natural
extension if per-section staleness is ever wanted.

**Decision 3 — an Outstanding Accepted Risk resolves by developer statement or by evidence-backed,
attributed, reopenable auto-resolution (FR-039)**.

*Rationale*: FR-039's original wording ("until the developer records that it is resolved or the
condition that prompted it no longer holds") left the second clause without an actor. Both
degenerate readings are bad: never auto-resolving means an accepted risk is restated at every
stage forever, including after the developer fixed it, which is exactly the alert fatigue
Principle VIII warns about; auto-resolving freely means an AI silently closing a record of a human
decision. The three constraints — cited evidence, attribution to Questmaster rather than to the
developer, and a report at the next stage — keep the developer the authority (Principle X) while
letting the record stay accurate. Auto-resolutions are deliberately **not** Judgment Ledger
entries: the ledger is the evidence base for `developer_judgment` (FR-010, FR-035), and letting
AI-authored resolutions into it would inflate the one dimension designed to be immune to
AI-authored content.

*Alternatives considered*: developer-only resolution — rejected, it guarantees stale carry-forward;
auto-resolution alone — rejected, it lets inference close a human decision; both, with
auto-resolution silent — rejected, an unreported status change is indistinguishable from the
record never having existed, which is the failure mode the Development Workflow section names for
acceptances that are never seen again.

**Decision 4 — the Dragon Pass is bounded at 2-3 challenges (Short) / 3-5 (Full), inside the
FR-033 budget (FR-034)**.

*Rationale*: "a small number" bounded nothing, and the Dragon Pass is developer-facing question
time by any honest accounting. Left outside the budget, a ~6-question Short Quest becomes ten or
twelve while every stated figure in the plan stays true — the precise way Principle IX says
ceremony grows ("by adding mandatory sections... while counting only the files"). The bound is
fixed rather than project-configurable for the same reason §8 rejected making the pass optional:
the knob would be turned down under the deadline pressure the pass exists to counteract, and a
configurable adversarial step is a removable one.

*Alternatives considered*: run-time judgment proportionate to risk surface — rejected, it is what
the spec already said and it produced no testable bound; a configurable count — rejected per above,
though if real use shows the fixed bounds are wrong for a class of quest, config is where that
correction belongs; enlarging the FR-033 budgets to accommodate the pass — rejected, the budgets
were set from what a developer will actually sit through, not from what the stages want.

**Decision 5 — the Comprehension Checkpoint asks three questions on the first run and exactly one
previously unasked question on each re-run (FR-041)**.

*Rationale*: the checkpoint was unconditional before every Plan Integrity result while the
assessment is explicitly re-runnable (FR-030), so a re-run re-interrogated the developer with
questions they had already answered — ceremony that gets routed around, and worse, a re-run that
teaches the developer the checkpoint is a toll rather than a prompt. Asking nothing on a re-run is
the opposite failure: Principle XIV says a stage that can be completed by pressing return is not a
gate. One new question preserves both properties at roughly thirty seconds' cost, and has a
property neither alternative has — it accumulates. A plan re-assessed three times carries five
recorded predictions from the developer rather than three restated ones, which is more evidence for
later stages to check against, not less.

*Alternatives considered*: re-ask all three every run — rejected as above; ask only on the first
run — rejected, a materially revised plan then executes against comprehension of a different plan;
re-ask only when the plan's digest changed — a close second, and the mechanism already exists
(Decision 2), but it makes the developer's participation a function of whether the AI edited a
file, when the point of the checkpoint is that the developer's understanding is worth eliciting
independently of that.

## 14. Two more corrections found only by actually running `specify extension add --dev`
(new 2026-09-13e, tasks.md T054)

**Context**: §12's 2026-09-13b correction was itself produced by cloning and reading
`github/spec-kit` source, but not by actually *running* the install against that source — it
inspected `_validate_provided_artifacts` and `extensions/git/extension.yml` closely enough to get
the manifest *shape* right, but not closely enough to catch two runtime behaviors that only
surface when `specify extension add --dev ./extensions/questmaster` is actually executed
(tasks.md T054). Both are corrected here rather than silently fixed, per this document's own
established convention — and both are exactly the class of mistake §12 exists to prevent,
recurring one level deeper: "confirmed against source" is not the same claim as "confirmed by
running it," and Constitution Principle XII does not treat the former as satisfying the latter.

**Finding 1 — an extension-provided template can only ever use `strategy: replace`.**
`contracts/extension.yml`'s `spec-template` entry (`strategy: "prepend"`) is rejected outright:
`ExtensionManifest._validate_provided_artifacts` raises `ValidationError` the moment a `strategy`
key appears on an extension-provided template ("'strategy' is not authorable for
extension-provided artifacts, which always use 'replace' semantics" —
`src/specify_cli/extensions/__init__.py`). `presets/ARCHITECTURE.md`'s composition table (prepend/
append/wrap) applies to **presets only**; §12 already knew presets and extensions were different
manifest kinds but wrongly assumed both could express `strategy: prepend`, because the only
`provides.templates` example actually inspected (`extensions/git/extension.yml`) doesn't use one at
all — an absence that reads identically whether the field is unsupported or simply unused, and
that ambiguity was resolved only by trying it and reading the resulting error.

**Decision**: the pending-story spec-template addendum ships as a companion **preset**,
`presets/questmaster-pending-story/` (schema confirmed against `presets/scaffold/preset.yml`),
whose sole artifact is exactly `contracts/extension.yml`'s intended `spec-template` entry —
`strategy: "prepend"`, `replaces: "spec-template"` — moved to the one manifest kind that actually
supports it. The extension's own `provides.templates` keeps only `story-template` (a net-new
name, which never needed `strategy` in the first place). Nothing about the addendum's *content*
changes, and FR-042 still holds: no existing Spec Kit file is edited, edit or otherwise — a
companion preset is additional installed configuration, not a modification to core.

**Alternatives considered**: embedding a full copy of the core `spec-template.md` inside the
extension's own replacement template (satisfying "replace" semantics without a second manifest) —
rejected: it forks and duplicates upstream content that this project does not own and has no
mechanism to keep in sync, the exact standing-maintenance-cost failure mode Constitution XI and
§2's reversal both already rejected once for a different mechanism. A companion preset costs one
extra installed artifact, no ongoing duplication, and was already the anticipated fallback in
§12's own text ("presets/scaffold remains the right download only for a possible future companion
preset").

**Finding 2 — `provides.scripts` is a real, validated manifest section, and the whole extension
source tree installs verbatim.** `ExtensionManifest._validate_provided_artifacts` is called for
`section="scripts"` exactly as it is for `section="templates"`; `tasks.md` T004's finding ("no
`provides.scripts` entry exists in the manifest schema") is simply wrong. Separately, the
installer's own inline commentary (`ensure_executable_scripts`, called at the end of every
install/update route to restore Unix execute bits `copytree`/archive-extraction strip) states
plainly that a "documented `.specify/extensions/<id>/scripts/...` invocation" is the expected
shape — because the installer copies the **entire** extension source directory into
`.specify/extensions/<id>/`, not merely the files named in `provides.*`. `qm-*.sh` therefore lands
at a knowable, stable path (confirmed by running the install: `.specify/extensions/questmaster/
scripts/qm-*.sh`, executable, byte-identical to the source) with zero extra delivery mechanism
required.

**Decision**: `extensions/questmaster/extension.yml` now declares all eight helpers under
`provides.scripts` (accurate manifest, matches installed reality, and lets a future `specify
extension info` / catalog listing show them). The three command skills **continue to inline each
helper as a heredoc** rather than switching to a path reference —not because the path doesn't
work (it demonstrably does, per T054's install), but as a deliberate simplicity choice now that
both delivery mechanisms are confirmed viable: a self-contained command file has one fewer
moving part (no dependency on the installed extension directory retaining its exact shape across
a future Spec Kit upgrade) for a one-time authoring cost that has already been paid. `README.md`'s
"Helper script delivery" note is updated accordingly, reframed from "forced by a schema
limitation" to "a choice made with the limitation's absence confirmed."

**Alternatives considered**: switching all three command files to reference
`.specify/extensions/questmaster/scripts/qm-*.sh` by path and deleting the heredoc copies —
rejected for this release on cost/benefit: it is a real simplification (removes ~2,800 duplicated
lines across three files) but a mechanical rewrite of already-correct, already-tested content
with no behavior change, and the heredoc form's only real cost (verbosity) is not a correctness or
maintainability problem now that a single canonical source (`extensions/questmaster/scripts/`) is
what the deterministic test tier exercises directly. Worth revisiting in a future release if the
duplication becomes a genuine editing burden.
