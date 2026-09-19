# speckit-presets-gamified

A [Spec Kit](https://github.com/github/spec-kit) preset, **`questmaster-pending-story`**, bundled
with its companion extension, **Questmaster** — a quality and reasoning layer for AI-assisted
software development.

## How it fits into Spec Kit

Spec Kit's own lifecycle is `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` →
`/speckit-implement`, each producing an artifact the next stage consumes. Questmaster slots into
that lifecycle without changing any Spec Kit command itself:

| Stage | Runs | What happens |
|---|---|---|
| *(before any spec exists)* | You, manually | `/speckit-questmaster-story` — a Socratic interview + Dragon Pass produces `story.md`, capturing the problem before any solution |
| `/speckit-specify` | Spec Kit | If a story is pending, the preset's addendum makes `/speckit-specify` draft `spec.md` from it as primary input instead of a blank template |
| *(immediately after)* | Automatic (`after_specify` hook) | `/speckit-questmaster-check-spec` relocates the story into the feature directory, then assesses `spec.md` against it — banded Integrity score, Drift Classification, Decision Worklist |
| `/speckit-plan` | Spec Kit | Unmodified — Questmaster doesn't touch plan generation itself |
| *(immediately after)* | Automatic (`after_plan` hook) | `/speckit-questmaster-check-plan` runs the Comprehension Checkpoint (three questions the plan doesn't answer), then assesses `plan.md` against `story.md` + `spec.md` |
| `/speckit-tasks`, `/speckit-implement` | Spec Kit | Unmodified — Questmaster has no stage here in this release |

Every Questmaster step is advisory: nothing it produces blocks, edits, or is required by Spec Kit's
own commands. A Spec Kit project without Questmaster installed behaves identically at every one of
these stages.

## The preset

`preset.yml` (at the root of this repo) provides `questmaster-pending-story`: it prepends a
pending-story check onto Spec Kit's core `spec-template.md`, so that when a story produced by the
Questmaster extension's Storyteller is waiting to be consumed, `/speckit-specify` uses it as
primary input instead of starting from a blank template.

Install it into any Spec Kit project with:

```bash
specify preset add --from https://github.com/leejsinclair/speckit-presets-gamified/archive/refs/tags/v1.0.0.zip
```

or, for local development against a checkout of this repo:

```bash
specify preset add --dev /path/to/speckit-presets-gamified
```

On its own, this preset does nothing observable — the addendum only renders when
`.specify/extensions/questmaster/pending-story.md` exists, which only the Questmaster extension's
`/speckit-questmaster-story` command ever writes. It exists purely to carry that one addendum
through the one mechanism (a preset's `prepend` template strategy) capable of expressing it,
without editing any existing Spec Kit file (see `preset.yml` for why an extension-provided
template can't do this itself).

## The companion extension

The preset's real functionality — the reason to install it at all — is delivered separately, as a
full Spec Kit extension, in [`extensions/questmaster/`](extensions/questmaster/). It wraps Spec
Kit's Story → Specification → Plan → Tasks → Implementation lifecycle with a narrative structure
aimed at one question at every stage:

> Has the original intent survived?

Concretely, that means:

- **Socratic problem-framing** before any specification is written (the Storyteller), so a
  solution is never drafted before the problem is understood.
- **Banded Integrity scoring** (weak / adequate / strong, not false-precision numbers) across
  Story, Specification, and Plan, run independently from the conversation that produced the
  artifact wherever possible.
- **Drift Classification** that traces every element of a spec or plan back to a justified
  decision, distinguishing legitimate refinement from unjustified scope creep.
- **A Judgment Ledger and Dragon Pass** that track where a developer contributed something an AI
  could not have supplied on its own — so a well-scored artifact still fails readiness if no
  human judgment shows up in it.

Questmaster is entirely advisory: it never blocks, auto-simplifies, or rewrites Spec Kit's own
output. A project that doesn't invoke it behaves exactly as if it weren't installed.

Install the extension with:

```bash
specify extension add --dev ./extensions/questmaster
```

This registers three commands (`/speckit-questmaster-story`, `/speckit-questmaster-check-spec`,
`/speckit-questmaster-check-plan`), materializes `questmaster-config.yml` for rubric tuning, and
wires `after_specify` / `after_plan` hooks so integrity checks run automatically as part of the
normal Spec Kit flow. Installing both the preset and the extension together is the intended setup.

## Usage

A typical quest, end to end:

```bash
# 1. Install both (once per project)
specify preset add --from https://github.com/leejsinclair/speckit-presets-gamified/archive/refs/tags/v1.0.0.zip
specify extension add --dev ./extensions/questmaster

# 2. Frame the problem before writing any spec
/speckit-questmaster-story
# → Socratic interview, then a Dragon Pass (2-5 challenges depending on quest size)
# → produces story.md with a banded Story Integrity Assessment + readiness classification

# 3. Hand off to Spec Kit as normal — Questmaster's hooks do the rest automatically
/speckit-specify
# → the pending story becomes primary input to spec.md, via the preset's prepend addendum
# → after_specify auto-runs /speckit-questmaster-check-spec: relocates story.md into the
#   feature directory and reports Specification Integrity + drift from the story

/speckit-plan
# → after_plan auto-runs /speckit-questmaster-check-plan: asks the three Comprehension
#   Checkpoint questions, then reports Plan Integrity + drift from spec and story

/speckit-tasks
/speckit-implement
```

Any of the three commands can also be run manually at any time — `/speckit-questmaster-check-spec`
or `/speckit-questmaster-check-plan` to re-check an artifact you've since edited, or their short
aliases (`/speckit-quest-story`, `/speckit-quest-check-spec`, `/speckit-quest-check-plan`). Every
report leads with a Decision Worklist, so you know what to act on first rather than just a score.

Skipping step 2 changes nothing else: with no pending story, the preset's addendum contributes
nothing, and `/speckit-specify` behaves exactly as it would with Questmaster not installed.

## Documentation

- [`questmaster.md`](questmaster.md) — the full methodology: the narrative rationale plus the
  delivered mechanics (commands, scoring model, Judgment Ledger, Dragon Pass, Comprehension
  Checkpoint, Drift Classification, and how to retune the rubric via configuration).
- [`extensions/questmaster/README.md`](extensions/questmaster/README.md) — implementation notes
  for the extension package itself (manifest, helper script delivery).
- [`specs/001-questmaster-quest-layer/`](specs/001-questmaster-quest-layer/) — the spec, plan,
  tasks, and quickstart used to build this feature, including
  [`quickstart.md`](specs/001-questmaster-quest-layer/quickstart.md), an end-to-end validation
  walkthrough covering every scenario the extension supports.

## Repository layout

```
preset.yml                Root preset manifest: questmaster-pending-story
templates/                Preset-provided template overrides (spec-template.md)
extensions/questmaster/   The Questmaster extension: commands, scripts, config
specs/                    Spec-Kit-managed feature spec/plan/tasks for this project
tests/extensions/         Governance, deterministic, and judgment test tiers
questmaster.md            Full methodology reference
CHANGELOG.md              Version history
```

## Testing

```bash
tests/extensions/questmaster/run.sh
```

Runs all three test tiers: an independent governance self-check against the project
constitution, deterministic unit tests for scoring/config/digest logic, and judgment-tier evals
that measure agreement with human-labelled fixtures.

## License

MIT — see [LICENSE](LICENSE).
