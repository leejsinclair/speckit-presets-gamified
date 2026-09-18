# Questmaster

A quest layer for Spec Kit: Socratic problem-framing before specification, banded Integrity
scoring, developer-judgment tracking, and Drift Classification across Story → Spec → Plan.

See `/questmaster.md` at the repository root for the full delivered methodology (commands, the
band-based scoring model, the Judgment Ledger and Dragon Pass, the Comprehension Checkpoint round
rule, the six-way Drift Classification, and how to retune the rubric through configuration alone).

## Helper script delivery (tasks.md T004)

**CORRECTED 2026-09-13e (research.md §14)**: an earlier version of this section claimed no
`provides.scripts` mechanism exists in the manifest schema. That was wrong — confirmed wrong by
actually running `specify extension add --dev ./extensions/questmaster`, which installs the whole
extension source tree verbatim (including `scripts/`) to `.specify/extensions/questmaster/`, and
by `ExtensionManager` genuinely validating a `provides.scripts` section
(`_validate_provided_artifacts(scripts, section="scripts", ...)`). `extension.yml` now declares
all eight scripts under `provides.scripts` accordingly, so every adopting project does get a
guaranteed, known-path copy at `.specify/extensions/questmaster/scripts/*.sh` for free.

**Decision (kept, now for a different reason)**: `extensions/questmaster/scripts/*.sh` are
**still inlined as heredocs** inside the command skill markdown file that uses them
(`commands/speckit.questmaster.*.md`), in addition to being declared in `provides.scripts`. This
is no longer a workaround for a missing mechanism — both delivery paths now work. It is a
deliberate simplicity/robustness choice: a command skill that carries its own script bodies
verbatim keeps working even if an agent invokes it in a mode that never resolves
`.specify/extensions/<id>/scripts/` (e.g. reading the skill file directly rather than through a
fully-installed project layout), at the cost of the two copies needing to be kept in sync by hand.

**How the two copies stay in sync**: `extensions/questmaster/scripts/*.sh` is the **tested source
of truth** — every deterministic test (`tests/extensions/questmaster/deterministic/`) invokes
these files directly, never a copy embedded in a command skill. Each command skill
(`commands/speckit.questmaster.*.md`) embeds the exact same script content verbatim as a heredoc
the agent writes to a temp file and executes in place, at the step that needs it. A change to a
helper's logic MUST be made in `scripts/` first (where the tests can catch a regression), then
`extension.yml`'s `provides.scripts` entry picks it up automatically on the next install, and the
heredoc copy in every command skill that inlines it must be regenerated (via the assembly scripts
under the build tooling, not hand-edited) to match.

**Consequence for this repository specifically**: because this repository is both Questmaster's
own development repo and (per `quickstart.md`) the project it is installed into via
`specify extension add --dev ./extensions/questmaster`, `extensions/questmaster/scripts/` is also
reachable at a stable relative path from the repository root regardless of installation.
