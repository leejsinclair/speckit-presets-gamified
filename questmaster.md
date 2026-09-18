# Questmaster Methodology

> **This release**: everything below describes the intended methodology. The concrete, delivered
> mechanics — the three real commands, the band-scoring system, the Judgment Ledger, the Dragon
> Pass, the Comprehension Checkpoint, Drift Classification, and how to retune any of it — are
> documented in **Delivered Implementation** near the end of this file. Read the narrative
> sections first for *why*; read that section for *how to actually run it*.

## Purpose

Questmaster is a quality and reasoning layer for AI-assisted software development.

It wraps a disciplined software development lifecycle in a narrative structure intended
to encourage curiosity, critical thinking, and engineering judgment.

The central idea is:

> A good implementation is not merely code that works. It is a solution that can be
> traced back to a well-understood problem.

## The Quest

Every meaningful feature begins as a quest.

A quest progresses through:

```
Story
  ↓
Specification
  ↓
Plan
  ↓
Tasks
  ↓
Implementation
  ↓
Verification
  ↓
Completion
```

At each stage, Questmaster asks:

> Has the original intent survived?

## The Story

The story describes the problem before describing the solution.

It answers:

- Who has the problem?
- What is the problem?
- Why does it matter?
- What outcome is desired?
- What evidence supports the problem?
- What constraints exist?
- What assumptions are being made?
- What is explicitly not part of the quest?
- What remains unknown?

The story should avoid premature technical decisions.

## Quest Integrity

Quest Integrity describes the continuity of intent throughout the lifecycle.

It is assessed across several dimensions rather than represented solely by a single
number.

Important dimensions include:

- Intent
- Requirements
- Architecture
- Verification
- Risk
- Complexity
- Traceability
- Knowledge
- Judgment — has a developer contributed something the AI could not have supplied on
  their own behalf?

A score is useful only when accompanied by evidence, and a score is honest only when it
can be repeated: re-assessing something unchanged should not produce a materially
different number. A score that moves on its own destroys trust in every finding
presented next to it. Where precision cannot be sustained, Questmaster reports a smaller
number of named levels — weak, adequate, strong — rather than a false-precision integer.

A score is also only trustworthy when the assessor did not just finish writing the thing
it is scoring. Wherever practical, Questmaster's assessments run separately from the
conversation that produced the artifact being assessed. An assessment that cannot be run
separately says so plainly, rather than presenting a self-assessment as if it were a
review.

## Quest Drift

Quest Drift occurs when a later artifact introduces something that cannot be reasonably
traced to an earlier justified decision.

Examples include:

- unsupported requirements;
- unnecessary architectural complexity;
- unexplained scope expansion;
- assumptions presented as facts;
- implementation behaviour not required by the specification;
- technical abstractions introduced without a demonstrated need.

Quest Drift is not automatically wrong.

Good engineering frequently discovers new information.

The purpose of Quest Drift detection is to ask:

> We have changed direction. Is that change intentional and justified?

## The Storyteller

The Storyteller is responsible for helping the developer understand the problem.

It should behave more like a thoughtful product partner than a code generator.

It may ask questions such as:

- Why does the user need this?
- What happens if we do nothing?
- How would we know that the problem has actually been solved?
- Is the proposed solution itself an assumption?
- What behaviour must not change?

The Storyteller sizes the quest before it interviews. A small, well-bounded change earns a
short conversation; it does not earn the same ceremony as a quarter-long feature. Forcing
every quest through the same fixed set of questions is not rigor — it is the kind of
process overhead that gets routed around.

## The Dragon

The Dragon is adversarial, and it is not optional narrative color: it is a required step,
run after the Storyteller and before any score is given.

Its purpose is to find weaknesses in what the developer just described — not weaknesses in
general, but weaknesses specific to *this* story.

It asks:

- What can fail?
- What assumptions are unsafe?
- What happens under unexpected input?
- What happens when dependencies fail?
- What happens during partial failure?
- What happens during migration?
- What happens when requirements evolve?

Every challenge the Dragon raises gets a recorded answer from the developer — engaged with,
accepted as a known risk, or explicitly dismissed. A dismissal is a legitimate answer. A
challenge with no answer at all is not: it means the Dragon didn't do its job, not that the
risk didn't matter. The developer's answers are Questmaster's only evidence that a human
engaged with the story rather than merely watching it get written — see Quest Integrity,
above, on why that evidence has to come from somewhere real.

## The Architect

The Architect determines how the solution can be implemented while preserving the intent
of the story.

It should challenge unnecessary complexity.

It should not optimise for the smallest possible implementation at the expense of
correctness, maintainability, security, or future requirements.

Before the Architect's plan is assessed, the developer is asked three questions the plan
itself does not answer: what's most likely to be wrong, what they'd cut, what breaks
first. This is not a formality. A plan can be technically sound and still be adopted by a
developer who never actually understood it — that gap, not a shortage of technically
sound plans, is the failure this whole methodology exists to close. Answering the
questions is how a developer demonstrates they read the plan rather than approved it.

## The Judge

The Judge evaluates the completed quest as a whole — did we solve the original problem, did the
implementation match the plan, did Quest Drift occur across the *entire* lifecycle rather than
one stage at a time. **Not implemented in this release** (formerly a requirement, FR-032, retired
2026-09-13a as untestable — a "MUST define but need not implement" clause is satisfied by its own
existence and cannot fail a test). The three stages that *are* implemented — Story, Specification
Integrity, Plan Integrity — produce exactly the per-stage inputs (banded scores, Judgment Ledger,
Comprehension answers, Drift Classification findings) a future Judge would synthesize rather than
recompute.

## Delivered Implementation

This section documents what this release actually built (`extensions/questmaster/`), as opposed
to the narrative design above. It exists as a Spec Kit **extension**, installed via
`specify extension add --dev ./extensions/questmaster` — not files hand-placed to resemble one.

### The three commands

| Command | Alias | Fires | Purpose |
|---|---|---|---|
| `/speckit-questmaster-story` | `/speckit-quest-story` | Manual, before any spec exists | Storyteller interview + Dragon Pass → `story.md` |
| `/speckit-questmaster-check-spec` | `/speckit-quest-check-spec` | Automatic (`after_specify` hook) or manual | Specification Integrity: `spec.md` vs `story.md` |
| `/speckit-questmaster-check-plan` | `/speckit-quest-check-plan` | Automatic (`after_plan` hook) or manual | Comprehension Checkpoint + Plan Integrity: `plan.md` vs `story.md`+`spec.md` |

Both hook-triggered commands run their assessment in an **independent context** (Claude Code's
Agent tool — a fresh subagent with no access to the conversation that authored the artifact being
assessed), because an assessor asked to find fault in text it just wrote rates that text
favorably no matter how it's instructed to be skeptical. Where no such mechanism is available,
every output is labelled `SELF-ASSESSED` instead — never silently presented as an independent
review.

### Band-based scoring (never a freely-assigned number)

Every rubric dimension, in every assessment, is judged as exactly one of four anchored bands —
never a free integer:

| Band | Multiplier | Means |
|---|---|---|
| `ABSENT` | 0.00 | Missing, or present but substantively empty |
| `WEAK` | 0.33 | Present but vague, contradictory, or insufficient to act on |
| `ADEQUATE` | 0.67 | Sufficient to proceed; specific, nameable gaps remain |
| `STRONG` | 1.00 | Specific, internally consistent, sufficient without follow-up |

`dimension_score = round(weight × multiplier)`; `overall_score = sum(dimension_scores)`. This
arithmetic is computed by a small deterministic script (`extensions/questmaster/scripts/
qm-score.sh`) — never left for the model to add up, because free-integer scores move several
points run-to-run on an unchanged artifact and that instability destroys trust in every finding
presented beside the number.

Three rubrics, 25 dimensions total: `story_rubric` (10), `specification_integrity_rubric` (7),
`plan_integrity_rubric` (8) — full anchor text for every band of every dimension lives in
`.specify/extensions/questmaster/questmaster-config.yml`.

### Story readiness (score alone never decides)

A story is classified `NOT_READY` / `NEEDS_CLARIFICATION` / `READY` / `READY_WITH_ACCEPTED_RISK`:
any unmet **critical condition** forces `NOT_READY` regardless of score (a 95/100 story with no
identified primary actor is `NOT_READY`); otherwise `READY` at or above the configured threshold
(default 70), else `NEEDS_CLARIFICATION`. One critical condition — `no_developer_judgment_recorded`
— is computed mechanically from whether the Judgment Ledger is empty, not judged from content.
`READY_WITH_ACCEPTED_RISK` is never a scoring output: it exists only when the developer explicitly
chooses to accept a gap **and types a justification in their own words** — a menu choice, a
generated justification, or silence leaves the classification unchanged.

### The Judgment Ledger

A `{date, stage, kind, developer_words, effect}` entry for every contribution that could only
have come from the developer — a challenge, a cut, an asserted fact the AI had no way to know, a
Dragon Pass response, a Comprehension answer. **Approving AI-authored content is never an entry.**
It is the sole evidence for the `developer_judgment` rubric dimension and for the
`no_developer_judgment_recorded` critical condition — the mechanism that makes `READY` actually
require developer participation, not just a complete-looking document.

### The Dragon Pass, bounded

2-3 challenges on a Short Quest, 3-5 on a Full Quest — counted **inside** the interview's time
budget, never added on top (an unbounded Dragon Pass is how a 6-question Short Quest quietly
becomes 12). Every response is recorded verbatim, including a dismissal — a challenge with no
recorded response is a defect, not evidence the risk didn't matter.

### The Comprehension Checkpoint, round rule

Before the *first* Plan Integrity result for a given plan: exactly three questions (most likely
wrong / what you'd cut / what breaks first). Every subsequent re-run: exactly **one** further
question that differs from every question already asked, with earlier answers restated rather
than re-asked. Re-asking three questions every re-run is ceremony that gets routed around; asking
nothing on a re-run is a gate a developer can pass by pressing return. One new question keeps
both properties and accumulates real evidence across re-runs.

### Six-way Drift Classification

Every compared requirement, scope item, assumption, or technical decision gets exactly one label
— never a bare drift/no-drift binary:

| Classification | Means |
|---|---|
| `PRESERVED` | Unchanged in substance |
| `REFINED` | Reasonable elaboration of something the earlier artifact already intended |
| `CLARIFIED` | Ambiguity in the earlier artifact resolved, consistent with its intent |
| `DISCOVERED` | New, but a justified and in-spec consequence of what came before |
| `ACCEPTED_SCOPE_CHANGE` | New and out of scope, but a matching Questmaster Decision records the developer's explicit acceptance |
| `UNJUSTIFIED_DRIFT` | New, out of scope, and no acceptance is recorded |

`ACCEPTED_SCOPE_CHANGE` is *only* ever assigned when a matching Decision exists — acceptance is
never inferred from silence. Content is never classified `UNJUSTIFIED_DRIFT` solely for not being
verbatim in the earlier artifact; reasonable elaboration is `REFINED`/`CLARIFIED`. A complex
design element traceable to a stated requirement, constraint, or risk is never flagged as drift
for being complex.

### Reports are decision-first

Every Integrity report leads with a **Decision Worklist** (at most 3 items, highest severity
first; the remainder counted and named if more qualify; "No decision required." if none do),
then any carried-forward **Outstanding Accepted Risk**, then banded scores, then the full
findings (aggregated counts for `PRESERVED`/`REFINED`/`CLARIFIED`, full per-element table in an
appendix). Every report records a content digest of each source artifact — excluding
Questmaster's own record-keeping section — so staleness is a checkable fact, not an assertion.

### Retuning the rubric

Everything above is configuration, not code: `.specify/extensions/questmaster/
questmaster-config.yml` (project-editable; layered under a gitignored `local-config.yml` and
`SPECKIT_QUESTMASTER_<KEY>` environment variables) holds every dimension's weight and band
anchors, the story readiness threshold, and the critical-condition list. Changing what "STRONG"
means for a given dimension, or moving the readiness threshold, requires editing this one file —
never a command's behavior. A missing or malformed rubric falls back to the documented defaults
for the affected rubric only, with a one-line warning; the assessment never fails outright.

## The Golden Rule

Questmaster should never make the developer feel that the goal is to satisfy the AI.

The goal is to build the right thing, for the right reason, with evidence that it works.

The AI is the party's guide, adversary, analyst, and assistant.

The engineer remains the decision maker.
