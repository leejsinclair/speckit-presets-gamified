# Implementation Plan: Questmaster — Quest Layer for the Spec Kit Lifecycle

**Branch**: `001-questmaster-quest-layer` | **Date**: 2026-09-12 | **Revised**: 2026-09-13e |
**Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-questmaster-quest-layer/spec.md`

## Revision Note (2026-09-13e — corrections found by actually running the install, tasks.md T054)

Running `specify extension add --dev ./extensions/questmaster` for real (rather than continuing
to reason from source inspection alone, per the 2026-09-13b correction's own methodology taken one
step further) surfaced two mechanical errors in the 2026-09-13b design, both corrected without
changing any requirement or acceptance-visible behavior (research.md §14 has the full evidence
trail):

1. **The `spec-template` addendum cannot ship from the extension.** `strategy: "prepend"` on an
   extension-provided template is rejected outright — extension templates are always `replace`;
   only a preset's `provides.templates` entries support prepend/append/wrap. The addendum now
   ships from a companion preset, `presets/questmaster-pending-story/` (installed alongside the
   extension: `specify preset add --dev ./presets/questmaster-pending-story`), whose sole artifact
   is that one `strategy: prepend` template entry. No content changed, no existing Spec Kit file
   is touched, FR-042 is unaffected — only which manifest carries this one entry changed.
2. **`provides.scripts` is real** (T004's finding that it doesn't exist was wrong), **and the
   whole extension directory installs verbatim** to `.specify/extensions/questmaster/`, scripts
   included, at exactly the `.specify/extensions/<id>/scripts/...` path the installer's own
   source names. `extension.yml` now declares all eight `qm-*.sh` helpers under `provides.scripts`
   for an accurate manifest. The three command skills still inline each helper as a heredoc — a
   deliberate simplicity choice now that both mechanisms are confirmed to work, not a workaround
   for a missing one.

Verified end to end (T054): `specify extension add --dev ./extensions/questmaster` now succeeds,
registers all three commands (plus aliases) into `.claude/skills/`, materializes
`.specify/extensions/questmaster/questmaster-config.yml` byte-identical to the template, writes
the `after_specify`/`after_plan` hook entries into `.specify/extensions.yml` matching
`contracts/extensions.yml`'s illustrative content, and leaves every pre-existing `.claude/skills/
speckit-*` file with an unchanged mtime and no mention of Questmaster anywhere in its content
(T055's by-construction check).

## Revision Note (2026-09-13d — clarification fold-in)

A `/speckit-clarify` pass run after this plan already existed resolved five ambiguities, all of
them at seams where two separately-designed mechanisms meet. None changes the architecture; four
of the five close a gap that would have produced a wrong result at runtime rather than merely an
undocumented one, so each is recorded with the failure it prevents:

1. **Pending-story collision (FR-029).** A second `/speckit-questmaster-story` for an unrelated
   request, run while an unclaimed pending story exists, previously fell through to "revise the
   pending story" — silently merging two unrelated problems into one file, which the next
   `/speckit-specify` would then relocate into whichever feature directory happened to be created
   first. Now: refuse to overwrite, name the pending story's Quest Title, require an explicit
   revise / consume / discard choice.
2. **Digest scope (FR-040).** Digests were computed over whole artifact files, but FR-027 appends
   the Questmaster Record *into* those same files — so recording a Decision would have marked
   every downstream report stale and trained developers to ignore the staleness signal FR-040
   exists to make trustworthy. Now: the digest covers artifact content excluding
   `## Questmaster Record`, making it a deterministic-tier test case (`test_digest_scope.sh`).
3. **Accepted-risk resolution (FR-039).** The spec said a risk stays outstanding "until the
   developer records that it is resolved or the condition no longer holds" without saying who
   decides the second clause. Now both paths exist: explicit developer resolution at any time,
   plus evidence-backed auto-resolution by Questmaster, attributed to Questmaster (never to the
   developer), reported at the next stage, and reopenable. Constitution X is preserved because
   auto-resolution requires cited evidence and cannot be inferred from silence.
4. **Dragon Pass bounds (FR-034/FR-033).** "A small number" of challenges was unbounded and could
   silently double a Short Quest's ~6-question budget. Now: 2-3 challenges on a Short Quest, 3-5
   on a Full Quest, counted *inside* the FR-033 budgets, which are unchanged. Deliberately fixed
   rather than configurable — a project that can retune the adversarial pass down to zero has
   removed it.
5. **Comprehension Checkpoint on re-runs (FR-041).** The checkpoint was unconditional before every
   Plan Integrity result while the assessment is explicitly re-runnable, so a re-run re-asked all
   three questions — the ceremony Principle IX says gets routed around. Now: three questions on
   the first checkpoint, exactly **one further, previously unasked** question on each subsequent
   run, with earlier answers restated. This also turns a re-run into a small source of new
   Judgment Ledger content rather than a repeat of old content.

## Revision Note (2026-09-13b)

Prompted by a request to review how Spec Kit presets are actually scaffolded (pointing at
`github/spec-kit`'s `presets/scaffold`), this revision corrects mechanical decisions the prior
plan got wrong by never cloning and inspecting the real `specify_cli` source — it had reasoned
entirely from the locally installed project's own `.claude/`/`.specify/` files, which show only
the *output* of the real registration system for already-correctly-shaped input, never what
happens to an incorrectly-shaped one. Full evidence trail: research.md §1, §4, §12.

1. **Questmaster is a Spec Kit *extension*, not files hand-placed to resemble one.** It ships a
   real `extension.yml` manifest (`contracts/extension.yml`) and installs via
   `specify extension add --dev ./extensions/questmaster`, the same real, documented mechanism
   `extensions/git` uses upstream — not a bespoke, hand-authored file layout that merely looks
   similar. `presets/scaffold` (what the developer pointed at) is the correct starting point only
   for a *preset* (which can only override existing templates/commands); Questmaster's net-new
   commands, hooks, and config require the extension mechanism instead.
2. **Command names are corrected**, not merely restyled: `/quest-story` → `/speckit-questmaster-story`,
   `/quest-check-spec` → `/speckit-questmaster-check-spec`, `/quest-check-plan` →
   `/speckit-questmaster-check-plan`. This is not a naming preference — the real hook-invocation
   code (`HookExecutor._skill_name_from_command`) only produces a working agent invocation for a
   `speckit.<ext-id>.<cmd>`-shaped command id; the original ids would have rendered hooks that
   silently never fire correctly.
3. **The rubric config path is corrected**: `.specify/questmaster/config.yml` →
   `.specify/extensions/questmaster/questmaster-config.yml`, the real per-extension
   `ConfigManager` location — which comes with a gitignored local-override layer and
   `SPECKIT_QUESTMASTER_*` env-var layer for free, previously unused.
4. **Repository layout changes**: Questmaster's own source now lives at
   `extensions/questmaster/` (mirroring the upstream monorepo's own `extensions/git/` layout)
   rather than assuming direct placement into `.claude/skills/`; tests move to
   `tests/extensions/questmaster/` to match the real convention.

Nothing about the *design* changes — the pending-story mechanism, band scoring, Judgment Ledger,
Dragon Pass, Comprehension Checkpoint, and independent-assessment requirement from the
2026-09-13a revision all stand unmodified. This is a correction of delivery mechanics, confirmed
against real, cloned upstream source rather than the locally installed copy alone.

## Revision Note (2026-09-13a)

This plan is revised following a critical review of the original design (see `spec.md`'s
Revision Note for the full finding list) and the constitution amendment (1.0.0 → 1.1.0) it
produced. Three changes reshape the plan materially:

1. **No existing Spec Kit file is edited.** The original plan's sole Constitution exception —
   editing `speckit-specify/SKILL.md` — is removed entirely by redesigning FR-029 (§ Complexity
   Tracking, below, is now empty). This plan builds strictly additive files.
2. **Assessment commands invoke a subagent, not inline reasoning.** The check-spec and
   check-plan commands MUST start an independent context per Constitution Principle XIII /
   spec.md FR-037, using Claude Code's Agent tool. This is a new architectural element the
   original plan did not have.
3. **Two new artifacts per feature carry recorded developer judgment**: the Dragon Pass and
   Judgment Ledger (story stage) and the Comprehension Checkpoint (plan stage), plus band-based
   scoring throughout (§ Technical Context, Project Structure below).

## Summary

Add a "quest" layer on top of this project's existing Spec Kit lifecycle, delivered as a real
Spec Kit extension (`contracts/extension.yml`): a new `/speckit-questmaster-story` command that
Socratically interviews the developer — sized as a Short or Full Quest — before any
specification exists, runs a story-specific Dragon Pass adversarial challenge, and writes a
bounded `story.md` (9 core + up to 4 extended + 4 recorded sections) that keeps Problem/Need/
Outcome/Requirement/Solution distinct and separately assesses Solution Neutrality. The story is
banded against a ten-dimension rubric — including a `developer_judgment` dimension scored from a
Judgment Ledger, not from AI-authored content — and classified into a four-state readiness gate
driven by named critical conditions (including "no developer judgment recorded"), not score
alone.

Two hook-triggered assessment commands (`/speckit-questmaster-check-spec`,
`/speckit-questmaster-check-plan`) band `spec.md`/`plan.md` against the preceding artifact(s),
**running in an independent subagent context** so neither ever assesses text the same
conversation just wrote, and apply a unified six-way Drift Classification to every compared
element. The check-plan command additionally runs a Comprehension Checkpoint — three questions
the plan itself cannot answer, and one further previously unasked question on each re-run —
before showing any assessment. Every report is presented
decision-first (at most three items needing a developer's judgment, then outstanding accepted
risk, then bands, then full findings) and persists a content digest of its sources so staleness
is detected, not merely asserted.

Implemented as a real Spec Kit extension — new commands, a new config file, new templates, and
`hooks:` all declared in one manifest (`contracts/extension.yml`), installed via
`specify extension add --dev ./extensions/questmaster` exactly as any other extension is. **No
existing Spec Kit command, skill, or script is modified** (FR-042): the design's one avoided
exception (editing `speckit-specify`'s directory allocation) is eliminated by having
`/speckit-questmaster-story` write to a pending-story location instead of allocating a feature
directory itself, and letting `speckit-specify`'s own unmodified template mechanism and
`after_specify` hook do the handoff.

## Technical Context

**Language/Version**: Bash (POSIX-`sh`-compatible, matching `.specify/scripts/bash/*.sh` and
`init-options.json`'s `"script": "sh"`) for supporting scripts; Markdown + YAML frontmatter
(Claude Code Skill format) for command definitions; YAML for the rubric config. No
general-purpose application language — scoring/drift judgment is LLM-applied rubric reasoning
per the skill's own instructions (same pattern as every existing `speckit-*` skill in this
repo), not a separately coded scoring engine. Banding (FR-036) is judgment applied against
published anchors, not arithmetic done by the LLM — the conversion from band to numeric score
IS arithmetic and MUST be computed deterministically (a small `sh`/`jq` helper), never left to
the LLM to add up.

**Primary Dependencies**: GitHub Spec Kit `>=1.0.0` real extension mechanism —
`specify_cli.extensions` (`ExtensionManager`, `HookExecutor`, `ConfigManager`,
`CommandRegistrar`) and preset/template-resolution stack, confirmed against a direct clone of
`github/spec-kit` (research.md §12), not only the locally installed copy; `jq` and
`python3`+`PyYAML` (already required by `.specify/scripts/bash/common.sh`); Claude Code's Agent
tool (subagent spawning), used by the check-spec/check-plan commands to satisfy FR-037's
independent-context requirement — no other new dependency.

**Storage**: Flat files, per the real extension layout confirmed in research.md §12: feature
artifacts in the local repo (`story.md`, `spec-integrity.md`, `plan-integrity.md`) plus
Questmaster's own extension state (`.specify/extensions/questmaster/questmaster-config.yml`,
`.specify/extensions/questmaster/pending-story.md`) at the real `ConfigManager` path, not the
original design's invented `.specify/questmaster/` tree. N/A — no database (FR-028).

**Testing**: Three tiers under `tests/extensions/questmaster/` (research.md §11, extended
2026-09-13c; path matches the real convention observed in the cloned repo —
`tests/extensions/git/`, `tests/extensions/assess/`, etc.): a dependency-free Bash assertion
tier for deterministic logic (config fallback, band→score arithmetic, readiness classification,
digest-mismatch detection including the Questmaster Record exclusion, pending-story collision
refusal, accepted-risk carry-forward and auto-resolution attribution, and comprehension-round
progression — the last four added 2026-09-13d, each covering a clarified seam); a fixture-corpus judgment-evaluation tier covering both the story
rubric on its own (8-10 labelled `story.md` fixtures — closes a gap the 2026-09-13a design left
covered only by manual scenarios) and cross-artifact Drift Classification (15-20 labelled
story/spec/plan sets), measuring agreement rate and band/score run-to-run variance against
Constitution Principle XII's revised standard, which explicitly rejects deterministic-only
testing as sufficient for judgment logic; and a governance tier — an automated, independent
subagent re-verification of this plan's own Constitution Check (Principle XIII applied
reflexively, Governance section's re-run requirement made automatic rather than manual), run
first, before either other tier, since a design whose own compliance claims are unverified is
not worth testing further.

**Target Platform**: Local developer machine running Claude Code against this Spec Kit project
(Linux/macOS/WSL Bash); the working repository itself is not a Git repository.

**Project Type**: Single project — Claude Code skill/extension for Spec Kit (not a
library/web-service/mobile app).

**Performance Goals**: N/A for latency/throughput. FR-033 sets *process* budgets instead
(Short Quest: ~6 questions, <5 min; Full Quest: ~12 questions, <15 min; assessment output:
<2 min to identify what's required of the developer) — design targets, not enforced limits.

**Constraints**: No web UI/DB/network service/external SaaS (FR-028); zero behavior change for
a feature/project with no `story.md`/pending story (FR-025, SC-006); zero modification to any
existing Spec Kit file (FR-042); must not depend on `git` being present.

**Scale/Scope**: Single feature, single developer, local repo at a time — no concurrency
requirement.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design below.*

**Independently re-verified 2026-09-13c** by an agent with no access to the session that
authored this plan, given only `constitution.md` and this document (the Governance tier's own
mechanism, research.md §11, applied to itself before that tier existed as a script — this run
was its manual proof of concept). Result: **13 of 15 rows CONFIRMED**; two (VI, XII) were
**DISPUTED** and are corrected below rather than left as originally recorded. Both disputed the
same defect: "PASS *(measured)*" described a fixture corpus and eval harness that do not exist
in this repository yet — a target, not a result — and for VI this was already directly
contradicted by spec.md's own Assumptions section ("a starting assumption... not a measured
result," spec.md:509). Row IX's "(measured)" survived scrutiny because its cited figures
(current section/dimension counts) are facts about the artifacts as written today, not future
test output — the distinction the two corrected rows failed to draw.

| Principle | Status | Notes |
|---|---|---|
| I. Intent Before Implementation | PASS | `/speckit-questmaster-story` runs before any spec exists; FR-029 (redesigned) makes this the actual entry point without touching Spec Kit's own allocation; FR-004/FR-005 keep Problem/Need/Outcome/Requirement/Solution distinct |
| II. Traceability | PASS | Every band cites specific artifact evidence (data-model.md report structure); FR-040 digests make staleness checkable, not asserted. (FR-023 traceability identifiers are optional — MAY/SHOULD, not MUST — and carry little independent weight here; the Drift Classification machinery in FR-017–021 is what actually satisfies this principle) |
| III. Preserve Intent | PASS | Specification/Plan Integrity reports exist specifically to catch silent intent drift; FR-016's `intent_preservation` dimension is banded independently of technical quality |
| IV. Challenge Assumptions | PASS | Story interview surfaces facts/assumptions/unknowns/solution bias (FR-001, FR-008); Dragon Pass (FR-034) actively challenges rather than passively records |
| V. Evidence Over Assertion | PASS | FR-011/FR-022 require cited evidence for every band; FR-040 makes the staleness claim itself evidenced (digest) rather than asserted |
| VI. Explainable and Repeatable Scoring | **CONDITIONAL PASS** *(measured 2026-09-13f; SC-016 clears, FR-036 partially misses)* | Band anchors published in config (contracts/questmaster-config.yml); FR-036 states an explicit reproducibility target (90% of bands stable, score within 5 points), SC-016 states an explicit agreement-rate target (≥80% per corpus). `judgment/eval.sh` has now actually run against both fixture corpora (T052): **cross-artifact element-classification agreement 82.2%** and **story-fixture readiness-status agreement 90%** both clear SC-016's ≥80% target. FR-036's own reproducibility target does not fully clear yet: run-to-run **band stability across the story corpus measured 86%** (target ≥90%) and one fixture's score range spanned 9 points across two runs (target ≤5). The instability traces to one dimension — `problem_definition` oscillated STRONG/ADEQUATE in 6 of 10 fixtures, far more than any other dimension (2-3 fixtures each) — so, per spec.md's stated Assumption (sharpen anchors rather than relax the requirement), that dimension's STRONG/ADEQUATE anchor boundary has been rewritten from a subjective "one supporting detail is missing" test to a mechanically-checkable "is there a concrete/quantified detail, or only qualitative language" test (questmaster-config.template.yml). This sharpening has not yet been re-measured against the eval corpus — that re-run is the concrete remaining step to a clean PASS, not a redesign |
| VII. Reward Engineering Judgment | PASS *(newly backed)* | `developer_judgment` dimension (FR-010) banded from the Judgment Ledger (FR-035) alone; `no_developer_judgment_recorded` critical condition (FR-012) makes `READY` unreachable without developer participation. Previously this row was PASS on assertion alone with no rubric dimension behind it — that gap is what this revision closes |
| VIII. Detect Quest Drift | PASS | FR-017–FR-021; six-way Drift Classification distinguishes refinement/clarification/discovery/accepted change from unjustified drift |
| IX. Minimise Process Overhead (proportionality) | PASS *(measured)* | Story sections: 9 core + up to 4 extended, down from 18 uniformly-mandatory (data-model.md); rubric dimensions: 25 total, down from 29, despite two additions; Short Quest path with a stated ~5-minute/~6-question budget (FR-033); reports lead with ≤3 decisions, not a full table (FR-038). Confirmed independently: these are current counts of the artifacts as written, verifiable today — not a future test result, which is what distinguishes this row from VI/XII below. Strengthened 2026-09-13d: the Dragon Pass is now bounded (2-3 Short / 3-5 Full) and counted *inside* the FR-033 budget rather than alongside it, and a Plan Integrity re-run asks one question rather than re-asking three (FR-041) — both close routes by which ceremony could grow without any number in this row changing |
| X. AI Is an Engineering Assistant | PASS | FR-022/FR-014: every gate ends in a developer choice, never an automatic action; FR-014 additionally requires the choice be *written*, not selected from a menu. Re-checked 2026-09-13d against the one place Questmaster now changes a record on its own — auto-resolving an Outstanding Accepted Risk (FR-039): it is bounded by three properties that keep the developer the authority, namely cited evidence is required (never inferred from silence), the resolution is attributed to Questmaster rather than to the developer, and it is reported at the next stage so it can be reopened |
| XI. Preserve Existing Spec Kit | **PASS** *(no exception required — see Complexity Tracking)* | FR-029/FR-042: zero existing Spec Kit files modified. The prior "conditional pass" exception is fully eliminated by the pending-story redesign (research.md §2/§3), not merely re-justified. Delivered as a real extension (`contracts/extension.yml`), not a preset — research.md §12 confirms presets cannot express net-new commands/hooks, so extension is the correct mechanism, not an over-reach. Independently cross-checked against the live upstream repo: the manifest schema and `hooks:` block match `extensions/git/extension.yml` as claimed |
| XII. Test the Methodology (judgment evaluated) | **PASS** *(measured 2026-09-13f)* | `tests/extensions/questmaster/run.sh` now runs all three tiers for real (research.md §11): **governance** — an independent agent re-verified all 15 Constitution Check rows against the actual principle text, 15/15 CONFIRMED; **deterministic** — all 9 test files pass (config fallback, band arithmetic, readiness gate, pending-story collision, digest scope, accepted-risk carry-forward, comprehension rounds, report ordering, worklist response); **judgment** — both fixture corpora ran through the real assessment logic and produced real agreement-rate/variance numbers (quoted in row VI above), closing the gap the amended principle identifies. The row's own condition ("governance tier run clean" + "judgment tier has produced real numbers") is now literally satisfied, independent of whether every one of those numbers itself clears its target (that nuance lives in row VI) |
| XIII. Independent Assessment | PASS *(new principle)* | The check-spec/check-plan commands invoke their assessment via Claude Code's Agent tool (a subagent with no access to the authoring conversation) per FR-037; where unavailable, output is labelled `SELF-ASSESSED`, never silently presented as independent. This entire Constitution Check row was itself validated by exactly this mechanism (see the independent re-verification note above) |
| XIV. Developer Participation Is Mandatory | PASS *(new principle)* | Judgment Ledger (FR-035) requires developer-original content, distinguished by design from approving AI output; FR-014 requires a written justification for any override, rejecting menu selections and empty strings |
| XV. Comprehension Before Execution | PASS *(new principle)* | Comprehension Checkpoint (FR-041) runs before any Plan Integrity content is shown, answers recorded verbatim, decline explicitly permitted and recorded as such |

**2026-09-13d re-check**: the five clarifications were evaluated against all fifteen principles.
Fourteen rows are unaffected. Row X is the only one whose supporting argument changed, because
auto-resolution (FR-039) is the first place Questmaster alters a recorded developer decision
without being asked — its note above now states the three properties that keep that inside the
principle rather than leaving the row on its prior wording. Row IX gains two strengthened
citations. No row moved status, and no clarification introduced a new exception.

**2026-09-13f re-check (T053, after actually running the suite)**: no gate failures. XII converts
to a clean PASS — the governance and judgment tiers have both now genuinely run (research.md §11),
which was the entirety of what that row conditioned on. VI stays a **CONDITIONAL PASS**, but no
longer for lack of measurement: SC-016's agreement-rate targets clear (82.2% cross-artifact, 90%
story-status, both ≥80%), while FR-036's own reproducibility target (band stability ≥90%, score
range ≤5) measured 86% and a 9-point range respectively. This is a genuine, narrow gap — not a
design flaw — traced to a single dimension's anchor wording and already corrected in
`questmaster-config.template.yml` per spec.md's stated Assumption (sharpen anchors, never relax
the requirement); the correction has not yet been re-measured, which is the one concrete step
left before VI, too, converts to a clean PASS.

## Project Structure

### Documentation (this feature)

```text
specs/001-questmaster-quest-layer/
├── plan.md               # This file (/speckit-plan command output)
├── research.md            # Phase 0 output
├── data-model.md          # Phase 1 output
├── quickstart.md          # Phase 1 output
├── contracts/              # Phase 1 output
│   ├── extension.yml       # Questmaster's real extension manifest — the actual source artifact
│   ├── quest-story.md      # Command contract docs (internal doc names, kept for continuity —
│   ├── quest-check-spec.md #   the real command ids/paths are speckit.questmaster.*, stated
│   ├── quest-check-plan.md #   inside each doc; see contracts/extension.yml for the manifest)
│   ├── questmaster-config.yml
│   └── extensions.yml      # ILLUSTRATIVE — what installing the extension writes into a
│                            #   project's .specify/extensions.yml; never hand-authored
└── tasks.md               # Phase 2 output (/speckit-tasks command — NOT created by /speckit-plan)
```

### Source Code (repository root) — corrected 2026-09-13b to match the real extension layout

Two distinct trees, per research.md §12: Questmaster's own **extension source** (what this
feature builds and ships, mirroring how the upstream monorepo itself lays out `extensions/git/`),
and the **installed runtime state** that appears in *any* project (including, potentially, this
one) after `specify extension add --dev ./extensions/questmaster` runs. The prior revision
conflated these into one hand-placed tree; the real mechanism keeps them separate.

```text
extensions/questmaster/                   # Questmaster's own extension source (NEW tree)
├── extension.yml                         # = contracts/extension.yml — commands, config,
│                                          #   templates, hooks: all declared here
├── commands/
│   ├── speckit.questmaster.story.md          # NEW — sizing, interview, Dragon Pass,
│   │                                          #        Judgment Ledger, band scoring,
│   │                                          #        readiness gate
│   ├── speckit.questmaster.check-spec.md      # NEW — hook target (after_specify). Its own
│   │                                          #        Outline invokes the assessment via a
│   │                                          #        subagent (Agent tool) to satisfy
│   │                                          #        FR-037; falls back to an explicitly
│   │                                          #        labelled SELF-ASSESSED path if
│   │                                          #        unavailable. Also relocates any
│   │                                          #        pending story (FR-029).
│   └── speckit.questmaster.check-plan.md      # NEW — hook target (after_plan). Comprehension
│                                               #        Checkpoint runs inline (direct
│                                               #        developer interaction, not subject to
│                                               #        FR-037); the assessment portion runs
│                                               #        via the same subagent pattern.
├── config/
│   └── questmaster-config.template.yml   # NEW — = contracts/questmaster-config.yml; materializes
│                                          #        at .specify/extensions/questmaster/
│                                          #        questmaster-config.yml on install (FR-024)
├── templates/
│   ├── story-template.md                 # NEW — 9 core + 4 extended + 4 recorded section
│   │                                      #        skeleton, resolved by name (no `replaces:`
│   │                                      #        needed — net-new, not a core override)
│   └── spec-template-pending-story-addendum.md  # NEW — strategy: prepend onto core
│                                                 #        spec-template; renders only when a
│                                                 #        pending story is present (FR-029)
└── examples/
    ├── faithful-quest/
    │   ├── story.md                      # NEW — fixture (SC-005), also part of the judgment
    │   │                                  #        corpus (copied/symlinked into
    │   │                                  #        tests/extensions/questmaster/fixtures/)
    │   └── spec.md                       # NEW — fixture
    └── drifting-quest/
        ├── story.md                      # NEW — fixture
        ├── spec.md                       # NEW — fixture
        └── plan.md                       # NEW — fixture

tests/extensions/questmaster/             # matches the real tests/extensions/<id>/ convention
├── run.sh                                # NEW — dependency-free test runner (all three tiers,
│                                          #        governance first — research.md §11)
├── governance/                           # NEW tier (2026-09-13c)
│   └── check_constitution.sh             # spawns an independent agent (no access to this
│                                          #   session) with only constitution.md + the artifact
│                                          #   under check; fails the suite if any Constitution
│                                          #   Check row is unsupported or overstated
├── deterministic/
│   ├── test_config_defaults.sh           # missing/malformed config → fallback + warning
│   ├── test_band_score_arithmetic.sh     # band multiplier → weighted score, deterministic
│   ├── test_readiness_gate.sh            # NOT_READY/NEEDS_CLARIFICATION/READY/
│   │                                     # READY_WITH_ACCEPTED_RISK, incl. high-score-but-
│   │                                     # critical-condition and empty-ledger cases (FR-012)
│   ├── test_pending_story.sh             # write/relocate/consume cycle (FR-029) — replaces
│   │                                     # the retired test_feature_reuse.sh; also the
│   │                                     # collision case: an unclaimed pending story is
│   │                                     # never overwritten (2026-09-13d)
│   ├── test_digest_scope.sh              # NEW (2026-09-13d) — a Questmaster Record edit does
│   │                                     # NOT change the digest; a body edit DOES (FR-040)
│   ├── test_accepted_risk.sh             # NEW (2026-09-13d) — carry-forward while outstanding;
│   │                                     # auto-resolution requires cited evidence and is
│   │                                     # attributed to Questmaster, not the developer (FR-039)
│   ├── test_comprehension_rounds.sh      # NEW (2026-09-13d) — first run asks 3, each re-run
│   │                                     # asks exactly 1 previously unasked question (FR-041)
│   └── test_report_ordering.sh           # decision-first section order, ≤3-item cap,
│                                         # aggregate counts (FR-038)
└── judgment/
    ├── story-fixtures/                   # NEW (2026-09-13c) — 8-10 labelled, COMPLETE story.md
    │                                     # files (not interview transcripts — see research.md
    │                                     # §11 for why the interview itself isn't fixture-able)
    │                                     # with expected bands + readiness classification per
    │                                     # fixture, incl. one per critical condition
    ├── fixtures/                         # 15-20 labelled story/spec/plan sets, incl. the
    │                                     # faithful-quest/drifting-quest pair above
    ├── expected/                         # human-assigned bands (story-fixtures/) and Drift
    │                                     # Classifications + band ranges (fixtures/)
    └── eval.sh                           # NEW — runs real assessments N times per fixture in
                                           # both story-fixtures/ and fixtures/, reports
                                           # agreement rate + run-to-run variance
                                           # (Constitution XII, research.md §11)
```

**Installed runtime state** (produced by `specify extension add --dev ./extensions/questmaster`
against any adopting project, this one included — not hand-authored, not committed as source):

```text
.claude/skills/
├── speckit-questmaster-story/SKILL.md          # rendered from commands/speckit.questmaster.story.md
├── speckit-questmaster-check-spec/SKILL.md     # rendered from commands/speckit.questmaster.check-spec.md
└── speckit-questmaster-check-plan/SKILL.md     # rendered from commands/speckit.questmaster.check-plan.md
    # (CommandRegistrar also writes .gemini/, .github/agents/, and 14+ other agent directories
    # from the same manifest — free, not something Questmaster implements itself)

.specify/
├── extensions.yml                        # CLI-managed hook registry — after_specify/after_plan
│                                          #   entries written here on install (contracts/
│                                          #   extensions.yml shows the resulting content)
└── extensions/questmaster/
    ├── questmaster-config.yml            # materialized from config/questmaster-config.template.yml
    ├── local-config.yml                  # gitignored per-developer override (free, via ConfigManager)
    └── pending-story.md                  # RUNTIME artifact (not committed) — written by
                                           #   /speckit-questmaster-story when no feature
                                           #   directory exists yet; consumed and removed by
                                           #   /speckit-questmaster-check-spec (FR-029)
```

**Structure Decision**: Single project, delivered as a real Spec Kit extension rather than a
hand-placed file layout that merely resembles one. Every source artifact lives under
`extensions/questmaster/` and installs through the documented mechanism
(`specify extension add --dev`); nothing is manually copied into `.claude/` or `.specify/`.
No `src/`/`backend/`/`frontend/` application code is introduced. **No existing Spec Kit command,
skill, or script file is modified** — this is a hard constraint (FR-042), not a documented
exception, and is now additionally guaranteed by construction: the extension mechanism has no
capability to edit a file outside its own installed tree.

**Open gap (recorded 2026-09-13, analyze pass)**: Technical Context above requires deterministic
`sh`/`jq` helpers for band→score arithmetic and digest computation — explicitly "never left to
the LLM to add up" — but neither the tree above nor `contracts/extension.yml` gives them a home:
the manifest declares `commands`, `config`, and `templates` under `provides`, and nothing else.
Whether Questmaster ships `extensions/questmaster/scripts/` as installed files or inlines each
helper into the command skill that uses it depends on what `ExtensionManager` actually supports,
which has not been checked against upstream source. `tasks.md` T004 resolves this before any
helper is written (T006–T009 are gated on it); the outcome must then be folded back into the tree
above and, if applicable, into the manifest. Recorded as unresolved rather than assumed either
way — assuming it is precisely the class of mistake the 2026-09-13b revision exists to correct.

## Complexity Tracking

*Empty.* The previous revision recorded one Constitution Principle XI exception here (editing
`speckit-specify/SKILL.md`). Redesigning FR-029 so `/speckit-questmaster-story` allocates
nothing and the pending story is instead picked up by `speckit-specify`'s own unmodified
template mechanism and consumed by the new `after_specify` hook target eliminates the exception
rather than re-justifying it. See research.md §2/§3 for the full reasoning, including why the
original "unavoidable" conclusion was correct about the mechanism but wrong about which
requirement to hold fixed. §12 additionally confirms, against real cloned source rather than
inference, that the extension mechanism used to deliver everything else has no capability to
edit a file outside its own installed tree in the first place.

No other deviation from constitution principles exists in this design.

## Post-Design Constitution Check

Re-evaluated after Phase 1 design (data-model.md, contracts/, quickstart.md) and then
independently re-verified 2026-09-13c (see the note under Constitution Check above): 13 of 15
rows hold up under independent scrutiny without modification; VI and XII are corrected to
CONDITIONAL PASS rather than left overstated. No row was found unsupportable — the two
corrections are about the difference between a measured result and a stated target, not about
missing or incorrect design.

All fifteen principles are grounded in concrete, inspectable design: band anchors and
reproducibility target (`contracts/questmaster-config.yml`, FR-036), the Judgment Ledger schema
and its exclusion rule (`data-model.md`, FR-035), the subagent-invocation pattern for independent
assessment (`quest-check-spec.md`/`quest-check-plan.md` contracts, FR-037), the decision-first
report structure (`data-model.md`'s Integrity Assessment Report template, FR-038), and the empty
Complexity Tracking table (FR-042) — none of these are restatements of the requirement they
satisfy; each names the artifact and section where the satisfying property actually lives, per
the amended Governance section's standard for what a PASS requires. The independent audit
additionally cross-checked several of these citations against a live clone of `github/spec-kit`
rather than trusting them, and confirmed the extension-mechanism claims (§XI) hold against real
upstream source, not just this project's own account of it.

**Gate result (updated 2026-09-13f, T053)**: PASS on 14 of 15 principles; CONDITIONAL PASS on VI
alone. `tests/extensions/questmaster/run.sh` has now actually run (governance 15/15 CONFIRMED,
deterministic 9/9 PASS, judgment tier producing real numbers), converting XII to a clean PASS as
designed. VI remains conditional: SC-016's agreement-rate targets clear, but FR-036's
run-to-run reproducibility target does not yet fully clear (86% band stability against a 90%
target, traced to the `problem_definition` dimension's anchor wording and already corrected — see
the Constitution Check table above). This does not block the delivered implementation; it names a
specific, already-actioned follow-up (re-run `judgment/eval.sh` after the anchor change) rather
than an open design question.
