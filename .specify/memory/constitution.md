<!--
Sync Impact Report
==================
Version change: 1.1.0 → 1.1.1
Rationale for bump: PATCH. Two stale command references corrected; no obligation
added, removed, or changed.

Driver: the 2026-09-13b revision of specs/001-questmaster-quest-layer established
that `/quest.story` cannot be a working command id — HookExecutor._skill_name_from_command
resolves an agent invocation only for a `speckit.<extension-id>.<command>`-shaped id,
so hooks registered against the original name would never fire. This document still
named the unworkable id in Principle I's rationale and in the Development Workflow
section. Since Governance requires a conflicting command be corrected to match this
document rather than the reverse, leaving the name here would have mandated a command
that cannot function.

Modified principles: none (Principle I's rationale text only)
Modified sections: Development Workflow & Quality Gates (command name only)
Removed sections: none

------------------------------------------------------------------------------

Version change: 1.0.0 → 1.1.0
Rationale for bump: MINOR. Three new principles added (XIII, XIV, XV) and three
existing principles materially expanded (VI, IX, XII). No principle was removed,
and no prior obligation was reversed or weakened, so this is not a MAJOR change.

Driver: a critical review (2026-09-13) of specs/001-questmaster-quest-layer found
that the 1.0.0 principle set could be — and in the feature's own plan.md was —
self-assessed as fully compliant while three of the project's stated goals had no
constitutional obligation behind them at all:
  1. Nothing required an assessment to be independent of the context that authored
     the artifact, so Questmaster would have graded its own homework by default.
  2. Nothing required any stage to elicit something only the developer could supply,
     so Principle VII ("Reward Engineering Judgment") had no enforceable expression —
     every proposed rubric dimension measured document completeness instead.
  3. Nothing required a developer to demonstrate comprehension of a plan before
     acting on it, which is the specific failure this project was created to address.

Added principles:
- XIII. Independent Assessment
- XIV. Developer Participation Is Mandatory
- XV. Comprehension Before Execution

Modified principles:
- VI. Explainable Scoring → VI. Explainable and Repeatable Scoring (adds a
  reproducibility obligation and banded judgment; an unreproducible score may not be
  presented as a number)
- IX. Minimise Process Overhead (adds proportionality: ceremony is measured in
  developer minutes and mandatory sections, not file count; a short path is required
  for small work)
- XII. Test the Methodology (adds that judgment behaviour requires evaluation against
  a labelled fixture corpus; arithmetic and control-flow tests alone do not satisfy it)

Modified sections:
- Scope & Technology Constraints (adds the process budget)
- Development Workflow & Quality Gates (adds the comprehension checkpoint and the
  independence requirement for assessments)
- Governance → Compliance review (a constitution check MUST NOT be self-assessed by
  the context that authored the artifact under review)

Removed sections: none
Deferred placeholders / TODOs: none
-->

# Questmaster Constitution

## Core Principles

### I. Intent Before Implementation

The problem and the desired outcome MUST be understood and documented before any
implementation approach is proposed. A proposed technical solution MUST NOT be treated
as evidence that the underlying problem has been understood — proposing an
implementation is not a substitute for the problem-framing that
`/speckit-questmaster-story` performs, and every downstream stage MUST be able to point
back to a stated problem and desired
outcome, not merely to a solution someone found convenient.

**Rationale**: Solutions are attractive and easy to generate, especially with AI
assistance; the failure mode Questmaster exists to prevent is skipping straight to "what
should we build" without first establishing "what problem are we solving and why."

### II. Traceability

Every significant requirement, architectural decision, implementation task, and quality
decision MUST be traceable to an earlier justified decision, artifact, or explicit
project principle. A decision that cannot be traced to something that justifies it MUST
be flagged rather than silently accepted.

**Rationale**: Traceability is what makes Quest Drift detectable at all — without a
chain from story to spec to plan to implementation, "faithfulness to intent" is not a
checkable property, only a slogan.

### III. Preserve Intent

Later artifacts (specification, plan, tasks, implementation, final review) MUST remain
faithful to the original quest story unless a change of intent is explicitly identified,
named as a change, and justified. Intent MUST NOT drift silently through a sequence of
individually-reasonable-looking edits.

**Rationale**: Most scope and intent drift is not a single bad decision; it is many
small, locally-reasonable changes that never get compared back to the original problem
statement.

### IV. Challenge Assumptions

The system MUST actively surface assumptions, ambiguity, unsupported scope, and
premature technical decisions rather than passively accepting them. This applies to
assumptions made by the developer, by prior artifacts, and by AI-generated proposals
alike.

**Rationale**: Assumptions left unchallenged become unreviewed decisions; naming them is
what allows a developer to accept or reject them deliberately instead of by default.

### V. Evidence Over Assertion

Every score and every alignment assessment MUST be supported by evidence drawn from the
relevant artifacts, the repository, tests, or the implementation itself. An assessment
that cannot point to specific evidence MUST NOT be presented as a finding.

**Rationale**: Evidence is what separates an assessment from an opinion, and is what
allows a developer to check Questmaster's reasoning rather than simply trust it.

### VI. Explainable and Repeatable Scoring

No score is meaningful without an explanation of why it was awarded. Every score MUST be
presented against the explicit criteria it was measured on, and MUST be communicated as
an assessment against those criteria — never as an objective measurement of engineering
ability or of an artifact's inherent worth.

A score MUST also be reproducible. Judgment MUST be exercised at a resolution it can
actually sustain: criteria MUST be judged as a small number of named, anchored bands,
and any numeric total MUST be a deterministic function of those bands rather than a
number chosen freely. Re-assessing an unchanged artifact MUST NOT materially change its
result. A criterion whose judgment cannot be reproduced MUST be reported as a band with
evidence and MUST NOT be reported as a number.

**Rationale**: A bare number invites either blind trust or blind dismissal; an explained
score invites scrutiny, which is the actual goal. But scrutiny requires stability — a
score that moves several points when the same artifact is assessed twice destroys trust
in every finding presented alongside it, including the drift findings that carry the real
value. Coarse, anchored judgment is both more honest about the precision available and
more actionable than a falsely precise number.

### VII. Reward Engineering Judgment

Questmaster MUST encourage understanding the problem, critical thinking, validating AI
output, architectural judgment, and responsible use of AI assistance. Questmaster MUST
NOT reward the volume of code generated, the volume or frequency of AI interactions, the
speed of producing output, or the act of accepting an AI recommendation without review.

**Rationale**: Optimizing for output volume or speed actively works against the
project's purpose, which is to keep engineering judgment — not generation throughput —
at the center of the workflow.

### VIII. Detect Quest Drift

The system MUST identify when scope, complexity, assumptions, architecture, or behaviour
in a later artifact diverges from the original intent recorded in earlier artifacts.
Quest Drift is an observation that requires engineering judgment to interpret, not proof
of a defect — a finding MUST be presented as something to be resolved by developer
judgment (accept as legitimate refinement, revise, or document as an intentional
change), never as an automatic rejection.

**Rationale**: Not all divergence is bad; treating every drift finding as a defect would
either be ignored (alert fatigue) or would punish legitimate, well-reasoned refinement.

### IX. Minimise Process Overhead

Questmaster MUST improve engineering quality without creating unnecessary ceremony.
Every required artifact, score, or quality gate MUST have a clear, statable purpose; a
step that does not observably improve problem understanding, traceability, or
faithfulness to intent MUST be removed or made optional rather than kept "for
completeness."

Overhead MUST be measured in developer minutes, mandatory sections, and words a
developer is expected to read — never in the number of files an implementation adds. Any
stage that imposes required structure MUST state its intended time cost and MUST provide
a proportionate short path for small work: applying a large feature's ceremony to a
two-day change is itself a violation of this principle. Output a developer is expected to
act on MUST lead with the decisions required of them, not with a complete enumeration of
everything assessed.

**Rationale**: A methodology that becomes bureaucratic will be routed around by the
engineers it is meant to help, defeating its purpose. The routine way this principle is
violated is not by adding files — it is by adding mandatory sections, rubric dimensions,
and generated prose while counting only the files, and by answering "developers do not
read the output" with more output.

### X. AI Is an Engineering Assistant

AI MAY propose, analyse, implement, challenge, and review at any stage of the quest
lifecycle. AI MUST NOT be treated as the final authority on any engineering decision.
Human developers remain responsible for the decisions Questmaster surfaces and for
final acceptance of any artifact, score, or finding.

**Rationale**: Questmaster's assessments (including its own scores) are inputs to
developer judgment, not verdicts — this principle applies the same standard to
Questmaster's own AI-driven output that Questmaster asks developers to apply to any
other AI-generated artifact.

### XI. Preserve Existing Spec Kit

Questmaster MUST extend and customise Spec Kit rather than unnecessarily replacing its
core workflow. Presets MUST be preferred for customising existing Spec Kit behaviour,
and extensions MUST be reserved for genuinely new capability that presets cannot
express. Existing Spec Kit commands MUST continue to function normally for a project
that has not adopted Questmaster.

**Rationale**: Forking or overriding Spec Kit's core would create a maintenance burden
and a divergent workflow; the smallest mechanism that achieves the goal keeps Questmaster
compatible with the ecosystem it extends.

### XII. Test the Methodology

Questmaster itself MUST be tested. Scoring logic, traceability logic, Quest Drift
detection, command behaviour, and artifact generation MUST have automated tests wherever
practical. A scoring or drift rule that cannot be exercised by a test MUST be treated as
a gap to be closed, not an acceptable permanent state.

Testing the deterministic parts alone MUST NOT be claimed as satisfying this principle.
Where behaviour depends on applied judgment — band assignment, readiness classification
from content, Drift Classification — it MUST be evaluated against a corpus of fixtures
carrying human-assigned expected results, reporting agreement rate and run-to-run
variance. Arithmetic, schema, and control-flow tests establish only that the scaffolding
works; they say nothing about whether the assessment is correct or stable, which is the
only property that matters to a developer relying on it.

**Rationale**: Questmaster asks every other artifact in the lifecycle to be
evidence-based and verifiable; it must hold its own scoring and detection logic to the
same standard, or its assessments of other work carry no credibility. A test suite that
checks only that rubric weights sum to 100 is evidence of nothing about the rubric.

### XIII. Independent Assessment

An artifact MUST NOT be assessed by the same context that authored it. Every Integrity
assessment MUST be performed with only the artifacts under comparison, the rubric
configuration, and the recorded decision history in scope — never with the conversation
that produced the artifact in scope. An assessment that cannot be performed independently
MUST say so and MUST be labelled as self-assessed rather than presented as a review.

**Rationale**: An AI asked to find fault in text it just wrote, with its own reasoning
still in context, will rate that text highly and will classify its own additions as
justified refinement. This is not a tuning problem to be solved with stronger wording in
a prompt; it is a property of the context. Every claim Questmaster makes about catching
silent drift depends on the assessor not having participated in creating the drift.

### XIV. Developer Participation Is Mandatory

Every stage MUST require at least one input that only the developer can supply and that
the AI cannot infer, generate, or default on their behalf. A stage that can be completed
end to end by pressing return does not involve the developer and MUST NOT be counted as a
quality gate.

Where a developer's judgment is invited, it MUST be recorded in their own words. Choosing
from a menu, accepting a generated justification, or silence MUST NOT be recorded as
judgment. Assessment MUST distinguish what the developer contributed from what the AI
produced, and MUST NOT allow a high result to be reached without developer contribution.

**Rationale**: Principle VII commits Questmaster to rewarding engineering judgment, but
judgment can only be rewarded if it can be observed, and it can only be observed if the
workflow demands something the AI cannot supply. Scoring the completeness of a document
that the AI wrote measures the AI. The distinguishing act of a developer using AI well is
deciding, challenging, and cutting — so those are the acts that must be required and
recorded.

### XV. Comprehension Before Execution

A developer MUST demonstrate comprehension of a plan, in their own words, before that
plan is executed. Demonstration MUST take the form of statements the artifacts do not
already contain — what is most likely to be wrong, what would be cut, what fails first —
and those statements MUST be recorded and carried forward so later stages can be checked
against them.

Comprehension MUST NOT be inferred from a developer having been shown an artifact, having
approved it, or having proceeded past it.

**Rationale**: The failure this project exists to address is not that AI-generated plans
are wrong — it is that they are accepted without being understood, and the acceptance is
indistinguishable from understanding. The only reliable evidence of comprehension is
information that had to come from a person who read the thing. Eliciting it is also what
converts a developer from a reviewer of AI output into a participant with a stake in the
outcome.

## Scope & Technology Constraints

Questmaster operates entirely within a normal Git repository and the installed Spec Kit
project structure. It MUST NOT require a web UI, a database, multiplayer functionality,
persistent XP storage, elaborate graphics, external SaaS integrations, or automated
developer performance measurement to deliver its core value. Any future feature that
would introduce one of these MUST be justified against a specific, evidenced gap in the
methodology — not added because it is available or expected of "gamified" tooling.

Gamified, fantasy/RPG framing (Storyteller, Architect, Seer, Judge, monsters, XP,
Victory, etc.) is a presentation layer over the underlying engineering assessments. It
MUST make the workflow more engaging without making the underlying engineering process
frivolous, and MUST NOT be prioritised over the substance of an assessment. The framing
MUST be either applied deliberately or omitted — carrying the vocabulary into reports
while delivering none of the engagement it promises incurs the credibility cost of
gamification without its benefit, and is the worse of the two positions.

**Process budget.** Questmaster's stages carry stated time targets, and an
implementation that routinely exceeds them is defective regardless of the quality of its
output: the Quest Story interview targets under 5 minutes and roughly 6 questions on a
short quest, and under 15 minutes and roughly 12 questions on a full quest. Assessment
output presented to a developer targets under 2 minutes of reading before they know what
is required of them. These are targets to design against, not gates to enforce.

## Development Workflow & Quality Gates

The quest lifecycle layers onto Spec Kit's existing workflow
(specify → clarify → plan → checklist → tasks → analyze → implement → converge) as
follows: `/speckit-questmaster-story` precedes specification and produces a scored
`story.md`;
specification and plan are each followed by an alignment assessment against the
artifacts that preceded them. Every score presented at any gate MUST include its
supporting evidence (Principle V, VI). Every alignment assessment MUST report Quest
Drift findings explicitly rather than omitting untraceable additions (Principle II,
VIII).

Every Integrity assessment MUST run independently of the context that authored the
artifact it assesses (Principle XIII), and MUST present the decisions it requires of the
developer before it presents its scores or its complete findings (Principle IX). Before a
plan is executed, the comprehension checkpoint MUST be offered and its result — answered
or explicitly declined — recorded (Principle XV).

Gates in this workflow are advisory, not blocking, except where a principle states
otherwise: a low story score MUST prompt an explicit developer choice to continue,
revise, or proceed deliberately (Principle I, IV); specification and plan alignment
findings MUST be surfaced but MUST NOT automatically modify, block, or reject an
artifact (Principle VIII, X). Scoring rubrics, weights, and thresholds MUST be
maintained as explicit, project-editable configuration rather than embedded in command
logic (Principle VI, IX).

Advisory does not mean costless. Where a developer knowingly proceeds past a gap, the
acceptance MUST carry a justification written by the developer (Principle XIV), and the
accepted gap MUST be re-surfaced at every subsequent stage until it is resolved or the
quest completes. An acceptance that is never seen again is indistinguishable from a gap
that was never surfaced, which defeats the purpose of recording it (Principle VIII).

## Governance

This constitution supersedes any conflicting guidance in Questmaster's templates,
presets, or command documentation; where a conflict is found, the template or command
MUST be corrected to match the constitution, not the reverse.

**Amendments**: Any change to a principle or to this document's required sections MUST
be proposed with a written rationale, MUST update the Sync Impact Report at the top of
this file, and MUST bump `CONSTITUTION_VERSION` per the versioning policy below before
being merged.

**Versioning policy** (semantic versioning applied to governance):
- **MAJOR**: Backward-incompatible removal or redefinition of a principle, or a change
  that reverses a principle's prior obligation (e.g., turning a MUST into a MAY).
- **MINOR**: A new principle or governance section is added, or an existing principle's
  guidance is materially expanded.
- **PATCH**: Wording clarifications, typo fixes, or other non-semantic refinements that
  do not change what is required or forbidden.

**Compliance review**: Every specification and plan alignment assessment produced by
Questmaster is also a compliance checkpoint against this constitution — a finding that
contradicts a principle here (e.g., a plan introducing scope with no traceable
justification) is a constitutional compliance issue, not merely a quality suggestion.
Complexity introduced anywhere in the lifecycle MUST be justifiable against a principle,
a requirement, or a documented constraint; unjustifiable complexity MUST be raised as a
Quest Drift finding (Principle VIII) rather than silently accepted or silently rejected.

A constitution check MUST NOT be self-assessed by the context that authored the artifact
under review (Principle XIII). A check performed by the authoring context MUST be
labelled self-assessed and MUST be re-run independently before the artifact is treated as
having passed. A principle MUST NOT be recorded as PASS on the strength of a restatement
of intent; a PASS requires naming the specific property of the artifact that satisfies
the principle and, where the principle sets a budget or threshold, the measured value.

**Version**: 1.1.1 | **Ratified**: 2026-09-12 | **Last Amended**: 2026-09-13
