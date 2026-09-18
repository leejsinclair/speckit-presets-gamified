# Phase 1 Data Model: Questmaster — Quest Layer for the Spec Kit Lifecycle

All Questmaster data lives as plain files in the local repository — Markdown artifacts and one
YAML config file. There is no database or service (FR-028). This document defines the shape of
every entity in `spec.md`'s Key Entities section, reflecting the Session 2026-09-13a revision
(banded scoring, Judgment Ledger, Dragon Pass, Comprehension Checkpoint, decision-first reports,
independent assessment, and the pending-story mechanism that removes the need to edit any Spec Kit
file).

## Quest Story (`story.md`)

Produced by `/speckit-questmaster-story`. Lives at `<feature-dir>/story.md` once a feature directory exists, or
at `.specify/extensions/questmaster/pending-story.md` until one does (FR-029).

### Quest Story Structure

Seventeen sections in three groups. "Genuinely not applicable" means the Storyteller judged, and
briefly stated why, that this feature has no meaningful content for that section — it is still
present, marked N/A, never silently omitted (FR-003).

#### Core sections — always present, on both Short and Full quests (9)

| # | Section | Purpose | Good content looks like | Poor content looks like | Storyteller question | Complete when |
|---|---|---|---|---|---|---|
| 1 | Quest Title | A short, human name for the feature | "Customer control over marketing email preferences" | "Feature request", "Notification stuff" | "What would you call this in one line to a colleague?" | A reader unfamiliar with the request can identify the feature from the title alone |
| 2 | Problem Statement | The undesirable situation, independent of any fix (Key Concepts: Problem) | "Customers receive marketing email they don't want and have no convenient way to control it" | "We need a NotificationPreference table" (a Solution — redirect to §13) | "What is undesirable about today's situation? If nothing changes, what stays wrong?" | Contains no implementation noun and would still be true if the eventual solution changed |
| 3 | Who Is Affected / Actors | Names the actor(s) experiencing the problem | "Customers who receive marketing email; support agents who field complaints" | "Users" (undifferentiated when multiple actors behave differently) | "Who specifically experiences this? Is there more than one kind of affected party?" | Every actor referenced later in Use Cases/Success Criteria is named here |
| 4 | Current Behaviour | What happens today, factually | "All customers receive all marketing categories; only support can manually suppress an address" | Vague ("it's not great right now") | "What actually happens today, step by step?" | A reader could describe today's behavior without seeing the code |
| 5 | Use Cases | A small number of meaningful interactions (FR-006) | 2-4 cases, each with actor, goal, trigger, expected result, key alternate/failure path | A long list of trivial steps, or one case with no failure path when one matters | "Walk me through the main way someone would use this. What triggers it? What could go wrong?" | Each functional requirement later in `spec.md` can point to a use case that motivates it |
| 6 | Desired Outcomes | What becomes true once solved (Key Concepts: Outcome) | "Customers can disable marketing communications and stop receiving them" | "Implement a notification preference system" (a Solution) | "If this is solved, what is different? What can someone now do or not experience?" | Stated as a resulting state, not an implementation action |
| 7 | Scope Boundaries | Three distinct lists: In-Scope, Out-of-Scope/Non-Goals, Adjacent Concerns (FR-007) | In: per-category opt-out. Out: transactional email. Adjacent: SMS preferences, handled separately | One list, or in-scope restated in the negative as "out of scope" | "What will exist after this quest that doesn't today? What might someone assume is included, that isn't?" | A reader can tell whether any given behavior is this quest's responsibility |
| 8 | Success Criteria | Observable outcomes proving the problem is solved (FR-009) | "Customers can disable marketing communications and the preference takes effect for all future eligible messages" | "Implement a notification preference system" | "How will we know, after shipping, that this actually worked?" | Every criterion is checkable without reference to how it was implemented |
| 9 | Assumptions & Known Unknowns | Two labelled lists, kept distinct from Known Facts (FR-008) | Assumed: most complaints concern marketing, not transactional email (not confirmed by support data). Unknown: whether SMS is in scope | An assumption asserted as fact; an unknown that wouldn't change any decision | "What are we taking for granted that hasn't been confirmed? What do we need to know that we don't?" | Every assumption is phrased as a belief; every unknown, if resolved, would change a decision |

#### Extended sections — required on a Full Quest, included on a Short Quest only where material (4)

| # | Section | Purpose | Good content looks like | Poor content looks like | Storyteller question | Complete when |
|---|---|---|---|---|---|---|
| 10 | Background / Context | Situates the problem: what area, what led here | "Marketing sends promotional email to all customers with no per-category opt-out; support tickets reference this" | Restating the problem statement in different words | "What's the surrounding situation? What prompted this now?" | A reader with no prior context understands where this sits in the product |
| 11 | Business Rules | Domain rules constraining correct behavior, independent of technology | "Transactional/legal-notice email can never be disabled by this preference" | Conflating a business rule with a technical constraint ("must use Postgres") | "Are there rules the business or domain imposes regardless of how this is built?" | Every rule is a domain constraint, not an implementation choice |
| 12 | Constraints | Known technical, timeline, or resource constraints | "Must ship before the Q3 compliance deadline; no new customer-facing infrastructure" | An assumption dressed as a constraint | "What's fixed and non-negotiable about how or when this can be built?" | Each constraint is something the requester actually asserted, not inferred |
| 13 | Proposed Solutions & Solution-Neutrality Assessment | Any solution the requester supplied, recorded as a proposal, then separated into requirement / implementation / assumption / unnecessary constraint (FR-005) | "Proposal: a NotificationPreference table. → Requirement: per-category opt-out. Implementation choice: the table. Assumption: email is the only channel affected." | Silently adopting the proposal as the story's requirement, or rejecting it | "You mentioned doing X — is that the approach you have in mind, or one option among others?" | Every part of a supplied proposal is classified into exactly one of the four buckets; "None supplied" when none was |

#### Recorded sections — produced by Questmaster, not by the interview (4)

| # | Section | Purpose | Complete when |
|---|---|---|---|
| 14 | Dragon's Questions | The adversarial challenges raised against this story and the developer's verbatim responses, including explicit dismissals (FR-034) | Every challenge has a recorded response; challenges cite this story's own content, not generic risk categories |
| 15 | Questmaster Record | Three subsections: **Judgment Ledger** (FR-035), **Comprehension** (FR-041; empty at the story stage), **Decisions** (FR-027) | Present whenever any developer judgment, comprehension answer, or override exists; Decisions is empty until an override occurs |
| 16 | Story Readiness Assessment | The readiness classification and why (FR-012) | States the classification, the score, the threshold, and which critical conditions (if any) are unmet |
| 17 | Story Integrity Assessment | Per-dimension band with evidence, plus the computed 0-100 score (FR-010/FR-011/FR-036) | Every one of the ten dimensions has a band and a specific evidence line |

**Identity**: one `story.md` per feature. Revising an existing story edits it in place, preserves
the existing Questmaster Record, and marks downstream reports stale via digest mismatch (FR-040).

**Section count**: 17 maximum (Full Quest), 13 minimum (Short Quest: 9 core + 4 recorded). This
replaces the previous design's 18 uniformly-mandatory sections; the reduction is the point, not an
accident — see spec.md's 2026-09-13a Revision Note, finding 5.

## Band (FR-036)

The unit of judgment everywhere in Questmaster. Numeric scores are computed from bands; a score is
never assigned directly.

| Band | Multiplier | Means |
|---|---|---|
| `ABSENT` | 0.00 | The dimension's content is missing, or present but substantively empty |
| `WEAK` | 0.33 | Present but vague, contradictory, or insufficient to act on |
| `ADEQUATE` | 0.67 | Sufficient to proceed; specific gaps remain and are nameable |
| `STRONG` | 1.00 | Specific, internally consistent, and sufficient for the next stage without follow-up |

`dimension_score = round(weight × multiplier)`; `overall_score = sum(dimension_scores)`, clamped
to 0-100. Anchored per-dimension definitions of each band live in the rubric config (FR-024) so a
project can retune what "adequate" means without touching command behavior.

**Why bands rather than free integers**: free-integer scoring of a 15-weight dimension is not
reproducible run to run, and a score that moves when the artifact has not destroys trust in the
findings presented beside it (Constitution VI). Coarse judgment is the resolution this assessment
can actually sustain.

## Scoring Rubric Configuration (`.specify/extensions/questmaster/questmaster-config.yml`)

**Corrected 2026-09-13b**: this is `specify_cli`'s real per-extension config path
(`ConfigManager`, `extensions/__init__.py:4484`), materialized on install from
`contracts/extension.yml`'s `provides.config` entry — not the ad hoc `.specify/questmaster/
config.yml` the original design invented before inspecting the actual mechanism. Landing here
also means Questmaster gets two layers of override for free, without writing any merge logic
itself: a gitignored per-developer file at `.specify/extensions/questmaster/local-config.yml`,
and `SPECKIT_QUESTMASTER_<KEY>` environment variables — both resolved beneath the project file
by `ConfigManager` before Questmaster ever reads a value.

A single project-local YAML file (FR-024) holds all three rubrics with their band anchors, the
story readiness threshold, and the critical-condition list. `ConfigManager`'s generic layering
has no opinion on what a *valid* rubric looks like, so Questmaster still owns its own validation
on top: weights must sum to 100, band anchors must be present for every dimension, and a
violation falls back to the documented defaults for the affected rubric only (Validation rule,
below) rather than failing the assessment. Full schema and defaults: `contracts/
questmaster-config.yml` (the content that becomes `provides.config`'s template).

```yaml
band_multipliers:           # FR-036 — project-editable, but changing these changes every score
  ABSENT: 0.00
  WEAK: 0.33
  ADEQUATE: 0.67
  STRONG: 1.00

story_rubric:
  readiness_threshold: 70   # FR-013: feeds NEEDS_CLARIFICATION/READY only
  critical_conditions:      # FR-012: any unmet condition forces NOT_READY regardless of score
    - core_problem_unclear
    - primary_actor_unknown
    - desired_outcome_absent
    - critical_use_cases_missing
    - scope_unbounded
    - critical_assumptions_unresolved
    - success_not_evaluable
    - no_developer_judgment_recorded    # NEW — Judgment Ledger is empty
  dimensions:                # FR-010 — ten dimensions, weights sum to 100
    - {name: problem_definition,        weight: 15}
    - {name: actors_and_current_state,  weight: 10}
    - {name: use_cases,                 weight: 15}
    - {name: desired_outcomes,          weight: 15}
    - {name: scope_and_boundaries,      weight: 10}
    - {name: success_criteria,          weight: 10}
    - {name: assumptions_and_unknowns,  weight: 5}
    - {name: constraints_and_context,   weight: 5}
    - {name: solution_neutrality,       weight: 5}
    - {name: developer_judgment,        weight: 10}   # banded from the Judgment Ledger ALONE

specification_integrity_rubric:   # FR-015 — 7 dimensions
    # story_fidelity 20, requirement_completeness 15, requirement_testability 15,
    # scope_discipline 20, traceability 10, handling_of_ambiguity 10, internal_consistency 10

plan_integrity_rubric:            # FR-016 — 8 dimensions
    # intent_preservation 20, specification_coverage 15, constraint_preservation 15,
    # proportionality 15, legibility 15, risk_management 10, test_strategy 5, traceability 5
```

**Validation rule**: if the file is missing, malformed, or a rubric's weights do not sum to 100,
the reading command falls back to the documented defaults **for that rubric only**, emits a
one-line warning, and never fails the assessment outright.

**Dimension count**: 25 across three rubrics, down from 29, while adding `developer_judgment` and
`legibility`. Merges: `background_context` + `constraints_business_rules` → `constraints_and_context`;
`actors_users` + current-state coverage → `actors_and_current_state`; `requirement_clarity` +
`acceptance_testability` → `requirement_testability`; `handling_of_assumptions` +
`handling_of_unknowns` → `handling_of_ambiguity`; `architectural_appropriateness` + `complexity` +
`unnecessary_scope` → `proportionality`; `technical_constraint_coverage` folded into
`specification_coverage`.

## Judgment Ledger (FR-035)

A subsection of the Questmaster Record in whichever artifact the entry concerns. The sole evidence
base for the `developer_judgment` dimension, and the only thing in the system that distinguishes a
developer who used Questmaster from one who watched it run.

| Field | Type | Notes |
|---|---|---|
| date | ISO date | |
| stage | `story` \| `dragon` \| `spec` \| `plan` \| `comprehension` | |
| kind | `challenge` \| `cut` \| `asserted_fact` \| `asserted_constraint` \| `evidence_supplied` \| `risk_named` \| `correction` \| `dragon_response` \| `comprehension_answer` | |
| developer_words | verbatim string | Recorded as written. Never paraphrased, never generated |
| effect | string | What changed as a result — including "nothing; dismissed" |

**Exclusion rule**: approving, accepting, or proceeding past AI-authored content is **not** a
ledger entry. Neither is an answer to a factual interview question that the AI could have inferred
from context already supplied. The test is: could this have been produced without the developer?

```markdown
### Judgment Ledger

- **2026-09-13** · story · asserted_constraint — "Legal signed off on a 30-day retention window
  last quarter, we can't keep preference history longer than that."
  *Effect*: added to Constraints; later caught a spec.md audit-log requirement as UNJUSTIFIED_DRIFT.
- **2026-09-13** · dragon · dragon_response — "Partial failure doesn't matter here, the preference
  write is a single row and we retry. Not worth designing for."
  *Effect*: dismissed; recorded as a knowingly accepted risk rather than an unconsidered one.
- **2026-09-13** · story · cut — "Drop the per-campaign granularity, nobody asked for it."
  *Effect*: removed from In-Scope; narrowed the quest.
```

**Non-goal** (spec.md Out of Scope): the ledger is per-feature evidence for one rubric dimension.
It MUST NOT be aggregated across developers or over time. It is not a productivity metric and any
use of it as one violates Constitution Principle VII.

## Dragon's Questions (FR-034)

| Field | Type | Notes |
|---|---|---|
| challenge | string | Specific to this story's content; cites the section or claim it challenges |
| category | `failure` \| `unsafe_assumption` \| `unexpected_input` \| `dependency_failure` \| `partial_failure` \| `migration` \| `changing_requirements` | |
| response | verbatim string | The developer's own words |
| disposition | `answered` \| `accepted_as_risk` \| `dismissed` \| `changed_the_story` | A dismissal is recorded, never dropped |

**Count (clarified 2026-09-13)**: two to three challenges on a Short Quest, three to five on a
Full Quest, counted *inside* the FR-033 interview budget rather than added to it. The bound is
fixed rather than project-configurable: a project that can tune the adversarial pass toward zero
has removed the one narrative element implemented as behaviour, under exactly the deadline
pressure it exists to counteract (research.md §8 rejects the same move for making the pass
optional).

A challenge with no recorded response is a defect (SC-011). The Dragon never rewrites the story
and never adds an unanswered challenge to the story as though it were the developer's content.

## Story Integrity Result (rendered; recorded in `story.md` §16–17)

| Field | Type | Notes |
|---|---|---|
| dimension_bands | list of `{name, band, weight, computed, evidence}` | `evidence` MUST cite specifics (FR-011); a band above `ABSENT` MUST NOT be awarded for mere presence |
| overall_score | integer 0-100 | Computed per FR-036, never assigned |
| readiness_threshold | integer | From config |
| unmet_critical_conditions | list of strings | Named conditions currently unmet |
| status | `NOT_READY` \| `NEEDS_CLARIFICATION` \| `READY` \| `READY_WITH_ACCEPTED_RISK` | |
| developer_choice | `revise` \| `accept_risk` \| null | Set only when status is not `READY` |
| acceptance_justification | verbatim string \| null | Required for `accept_risk`; absent or empty ⇒ the acceptance does not take effect (FR-014) |

**Classification rule** (FR-012):
1. If `unmet_critical_conditions` is non-empty → `NOT_READY`, regardless of `overall_score`.
2. Else if `overall_score >= readiness_threshold` → `READY`.
3. Else → `NEEDS_CLARIFICATION`.
4. `READY_WITH_ACCEPTED_RISK` is never a direct outcome of scoring — it is the recorded result of
   a developer choosing `accept_risk` **and** supplying a justification in their own words.

Note that `no_developer_judgment_recorded` is a critical condition, so rule 1 makes `READY`
unreachable for a story the developer did not participate in, whatever it scores.

## Integrity Assessment Report (`spec-integrity.md`, `plan-integrity.md`)

Produced by `/speckit-questmaster-check-spec` and `/speckit-questmaster-check-plan` (FR-031). Overwritten on each re-run.
Section order is normative: FR-038 requires decisions before scores, and scores before the full
enumeration.

### Source digest scope (FR-040, clarified 2026-09-13)

A source digest is `sha256` over the artifact's content **with its `## Questmaster Record` section
removed** — from that heading up to the next same-level heading or end of file — normalized only
by stripping a trailing newline. Computing it is deterministic work for the `sh`/`jq` helper, not
LLM judgment.

The exclusion is what makes the digest mean anything. Questmaster writes the Questmaster Record
into the very artifacts it digests (FR-027: Judgment Ledger entries, Comprehension answers,
Decisions), so a whole-file digest would report "`story.md` changed since the previous report"
every time a developer accepted a risk — a staleness signal that fires on Questmaster's own
bookkeeping is noise, and a noisy signal gets ignored exactly when a real upstream edit finally
occurs. Excluded content is still *read* by every assessment (Decisions gate `ACCEPTED_SCOPE_CHANGE`
per FR-019, and outstanding risk is carried forward per FR-039); it is simply not part of what
"this artifact changed" means.

```markdown
# Specification Integrity Assessment

**Assessed**: 2026-09-14 · **Against**: story.md
**Assessment context**: INDEPENDENT        <!-- or SELF-ASSESSED (FR-037) -->
**Source digests**: story.md `sha256:3f9a…`, spec.md `sha256:c17b…`   <!-- FR-040 -->

## Decisions for you (2)

1. **spec.md adds an admin bulk-resend tool (REQ-011).** The story never mentions
   administrative tooling. → *Was this intended, and does it belong in this quest?*
   `UNJUSTIFIED_DRIFT` · High · see Finding 1
2. **The story's 30-day retention constraint is not carried into spec.md.** → *Was it
   dropped deliberately?* `UNJUSTIFIED_DRIFT` · Medium · see Finding 2

<!-- If more than three: "3 shown; 2 further items require a decision (REQ-014, REQ-019) —
     see the full table below." If none: "No decision required." -->

## Outstanding accepted risk (1)                     <!-- FR-039 -->

- **Accepted 2026-09-12, story stage** — proceeded at 62/100 with evidence/motivation weak.
  Developer's reason: *"Support data is in a dashboard I can't export this week; I'd rather
  start and revisit than stall the quest."* Still unresolved.

## Integrity

story_fidelity **STRONG** 20/20 · requirement_completeness **ADEQUATE** 10/15 ·
requirement_testability **ADEQUATE** 10/15 · scope_discipline **WEAK** 7/20 ·
traceability **ADEQUATE** 7/10 · handling_of_ambiguity **STRONG** 10/10 ·
internal_consistency **STRONG** 10/10 → **74/100**

| Dimension | Band | Score | Evidence |
|---|---|---|---|
| Story fidelity | STRONG | 20/20 | Every story outcome appears as a requirement; problem restated without solution language |
| Scope discipline | WEAK | 7/20 | Two requirements (REQ-011, REQ-014) have no story antecedent |
| … | | | |

## Drift Classification summary

28 elements compared: **21 PRESERVED**, **4 REFINED**, **1 CLARIFIED**, **2 UNJUSTIFIED_DRIFT**.
Per-element table: appendix below.

### Finding 1: admin bulk-resend tool
- **Source artifact**: story.md
- **Destination artifact**: spec.md (REQ-011)
- **Original intent**: customers control which marketing categories they receive
- **New behaviour**: an administrative tool for re-sending suppressed campaigns
- **Classification**: UNJUSTIFIED_DRIFT · **Severity**: High
- **Evidence**: no story actor is an administrator; §7 Scope Boundaries lists "internal tooling"
  under Adjacent Concerns
- **Question for the developer**: was this intended for this quest, or does it belong to the
  adjacent concern the story already set aside?

## Appendix — full per-element classification

| Element | Classification | Notes |
|---|---|---|
| REQ-001 | PRESERVED | Direct carry-over of ST-001 |
| … | | |

## Advisory note

This assessment does not block, modify, or reject the artifact (FR-022). All findings require
developer judgment.
```

**Plan Integrity** uses the same structure with `**Against**: story.md, spec.md`, the eight Plan
Integrity dimensions, a Drift Classification covering every component/service/abstraction in
`plan.md`, and two additional requirements:

- Constraint preservation is reported separately from specification coverage, so a story-level
  constraint lost during technical design is flagged even when `spec.md` carried it forward.
- The report states where its findings **agree or disagree with the developer's Comprehension
  Checkpoint answers** (FR-041) — e.g. "you predicted the retry path was most likely to be wrong;
  this assessment instead found the dropped retention constraint more significant."

**Special case** (FR-026): where no `story.md` exists and an assessment is explicitly requested,
no report file is written; the command states plainly that assessment could not be performed and
explains how to run `/speckit-questmaster-story`.

## Comprehension Checkpoint (FR-041)

Recorded in `plan.md`'s Questmaster Record, before any Plan Integrity content is shown. Held as an
ordered list of **rounds**, not a fixed triple, because the assessment is re-runnable (FR-030).

| Field | Type | Notes |
|---|---|---|
| round | integer ≥ 1 | Round 1 is the first checkpoint for this plan; each later Plan Integrity run adds one round |
| asked | ISO date | |
| questions | list of `{question, answer}` | Round 1 holds exactly three: most-likely-wrong, would-cut, breaks-first. Every later round holds exactly **one** |
| answer | verbatim string \| `DECLINED` | Recorded as written, never paraphrased or generated |
| outcome | `answered` \| `declined` | Per round. A decline is recorded as a decline, never as an absence |

**Round rule (FR-041, clarified 2026-09-13)**: the first checkpoint asks the three fixed
questions. Every subsequent Plan Integrity run asks exactly **one** further question, which MUST
differ from every question already recorded for this plan, and restates the earlier answers rather
than re-asking them. Re-asking all three on each re-run is the ceremony Principle IX predicts will
be routed around; asking nothing makes a re-run pure output with no developer input, which
Principle XIV forbids counting as a gate. One new question keeps both properties, and each round
adds a fresh `comprehension_answer` to the Judgment Ledger.

Later-round questions are drawn from the same family — answers the plan cannot supply — for
example: what would have to be true for this plan to be the wrong shape entirely; which part
would be hardest to reverse once built; what a reviewer unfamiliar with the feature would
misread first. When the supply of genuinely non-derivable questions is exhausted, the checkpoint
says so and asks nothing rather than padding with a question the plan already answers.

```markdown
### Comprehension

**Round 1 · 2026-09-14** — asked before Plan Integrity assessment.

- *Most likely wrong*: "The assumption that we can read preferences synchronously in the send
  path. At campaign volume that's a lookup per recipient."
- *Would cut*: "The per-category audit log. Nobody asked for it."
- *Breaks first*: "The send path, under a large campaign — not the preference UI."

**Round 2 · 2026-09-16** — asked on re-run; round 1 answers restated, not re-asked.

- *Hardest to reverse once built*: "The preference schema. Everything downstream reads it and
  we'd be migrating rows, not redeploying code."
```

Answers are added to the Judgment Ledger as `comprehension_answer` entries and are available to
later stages as recorded developer predictions.

## Questmaster Record (FR-027)

An in-artifact section — **not** a separate file — appended to whichever artifact it concerns.
Supersedes the previous design's standalone "Questmaster Decisions" section by making Decisions
one of its three subsections, so judgment, comprehension, and overrides live under one heading.

```markdown
## Questmaster Record

### Judgment Ledger
<!-- FR-035 entries -->

### Comprehension
<!-- FR-041 answers; empty at the story and spec stages -->

### Decisions
- **2026-09-12** — Story classified NEEDS_CLARIFICATION (62/100, threshold 70; no critical
  condition unmet). Developer chose **accept risk**. Their reason: *"Support data is in a
  dashboard I can't export this week; I'd rather start and revisit than stall the quest."*
  → READY_WITH_ACCEPTED_RISK. **Status: outstanding.**
- **2026-09-14** — Drift finding "admin bulk-resend tool" (spec.md REQ-011, UNJUSTIFIED_DRIFT)
  accepted as intentional. Their reason: *"Support asked for it in the same thread; I'm
  deliberately widening the quest rather than opening a second one."*
  → reclassified ACCEPTED_SCOPE_CHANGE on the next run. **Status: resolved.**
```

Each Decision entry records the date, what was unmet or flagged, the developer's explicit choice,
their justification in their own words, and a status (`outstanding` / `resolved`). The status
field is what FR-039's carry-forward reads: an entry remains outstanding until resolved.

**Resolution (FR-039, clarified 2026-09-13)** — a status reaches `resolved` by exactly two paths,
and the entry records which:

| Field | Type | Notes |
|---|---|---|
| status | `outstanding` \| `resolved` | Carry-forward (FR-039) restates every `outstanding` entry at every later stage |
| resolved_by | `developer` \| `questmaster` \| null | Null while outstanding. Never `developer` unless the developer actually said so |
| resolved_date | ISO date \| null | |
| resolution_evidence | string \| null | Required when `resolved_by: questmaster` — the specific artifact content showing the condition no longer holds. Absence of an objection is **not** evidence |

- **Developer resolution**: the developer states at any time that the gap is closed. Their words
  are recorded; this is also a Judgment Ledger entry.
- **Questmaster auto-resolution**: an assessment finds evidence that the condition which prompted
  the acceptance no longer holds (e.g. a story accepted at `NEEDS_CLARIFICATION` for weak evidence
  now carries the evidence). Questmaster may set `resolved`, but only with `resolution_evidence`
  cited, only attributed to itself — never presented as the developer's judgment, and never a
  Judgment Ledger entry, which would let AI-authored content inflate the `developer_judgment`
  dimension — and it MUST be reported at the next stage so the developer can reopen it.

```markdown
- **2026-09-12** — Story classified NEEDS_CLARIFICATION (62/100). Developer chose **accept risk**.
  Their reason: *"Support data is in a dashboard I can't export this week."*
  → **Status: resolved** by *questmaster* on 2026-09-14 — evidence: story.md §9 now records the
  exported ticket counts as a Known Fact rather than an assumption; `assumptions_and_unknowns`
  bands STRONG where it banded WEAK at acceptance.
  *Reported at the Specification Integrity stage; reopen if this is not what you meant.*
``` `/speckit-questmaster-check-spec` and `/speckit-questmaster-check-plan` consult Decisions before classifying any
element `ACCEPTED_SCOPE_CHANGE` (FR-019).

## Pending Story (FR-029)

`.specify/extensions/questmaster/pending-story.md` — a `story.md` written before any feature
directory exists, in Questmaster's own extension config directory (the same place its
rubric config lives; `ConfigManager`'s `extension_dir`, `extensions/__init__.py:4503`). At most
one exists at a time — and that invariant is enforced by refusal, not by overwrite: a single
fixed path has no feature directory to disambiguate it, so silently replacing an unclaimed
pending story would destroy a completed interview and, worse, leave the *next* `/speckit-specify`
relocating an unrelated story into the new feature directory, where every later Integrity
assessment would compare the spec against the wrong problem statement.

| Transition | Behavior |
|---|---|
| `/speckit-questmaster-story` run with no active feature directory and no pending story | Writes the pending story. Allocates no directory, no branch, no number |
| `/speckit-questmaster-story` run with no active feature directory while an **unclaimed pending story exists** | **Refuses to overwrite.** States that a pending story exists, names its Quest Title, and requires an explicit developer choice: revise it, consume it by running `/speckit-specify`, or discard it. Only after an explicit discard does a new interview begin (FR-029, clarified 2026-09-13) |
| `/speckit-specify` run while a pending story exists | Reads it as primary input via the `spec-template` **extension-provided template addendum** (`contracts/extension.yml`'s `provides.templates`, `strategy: prepend` — template *content*, not control flow, resolved through Spec Kit's own priority stack; no Spec Kit file is modified) |
| `after_specify` hook fires | `/speckit-questmaster-check-spec`'s own step 1 moves the pending story into the new feature directory as `story.md`, then runs the Specification Integrity assessment against it |
| `/speckit-questmaster-story` run while the active feature already has `story.md` | Revises in place; no pending story is created |
| `/speckit-specify` run with no pending story and no `story.md` | Entirely unaffected — the non-adopting case (FR-025, SC-006) |

This replaces the previous design's requirement that `/speckit-questmaster-story` allocate the
feature directory itself, which forced a conditional edit to `speckit-specify`'s own control
flow. Changing the ordering requirement rather than the mechanism removes the only Principle XI
violation in the feature and satisfies FR-042. Confirmed directly against the real
`templates/commands/specify.md` in github/spec-kit: "The spec directory and file are always
created by this command, never by the hook" appears there verbatim, and `spec-template`
resolution already goes through "the Spec Kit preset/template resolution stack" as a named step
in that command's own Outline — exactly the seam an extension-provided template addendum uses,
with zero edits to the command itself (research.md §3, §12).

## Traceability Identifier

Optional label, assigned where it adds value (FR-023), never forced onto every element:

| Prefix | Assigned to | Assigned by |
|---|---|---|
| `ST-###` | A distinct story element worth referencing later | `/speckit-questmaster-story`, selectively |
| `UC-###` | A captured use case | `/speckit-questmaster-story` |
| `REQ-###` | A functional requirement | `/speckit-specify`, or `/speckit-questmaster-check-spec` retrofitting where useful |
| `SC-###` | A success criterion | `/speckit-questmaster-story` or `/speckit-specify` |
| `TASK-###` / `TEST-###` | *(future stage — not assigned by anything in this release)* | — |

## Quest Integrity *(conceptual — no entity in this release)*

Not a file and no longer a requirement: FR-032 was retired in the 2026-09-13a revision as
untestable. The synthesis method is preserved as design intent in `spec.md`'s Out of Scope
section, and this release produces the per-stage inputs (Story Integrity Result, Specification
Integrity Report, Plan Integrity Report, Judgment Ledger, Comprehension answers) a future
synthesis would consume.
