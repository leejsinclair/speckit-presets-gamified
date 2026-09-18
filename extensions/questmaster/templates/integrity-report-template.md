<!--
Shared decision-first report skeleton for spec-integrity.md and plan-integrity.md
(tasks.md T010, data-model.md § Integrity Assessment Report, FR-038).

Section order below is NORMATIVE — do not reorder when a command skill renders a real report:
  1. Header (assessment context label + source digests)
  2. Decisions for you (at most 3, highest severity first)
  3. Outstanding accepted risk
  4. Integrity (banded dimension summary)
  5. Drift Classification summary (aggregate counts; full per-element table in the Appendix)
  6. Findings (one full finding per DISCOVERED / ACCEPTED_SCOPE_CHANGE / UNJUSTIFIED_DRIFT element)
  7. Appendix — full per-element classification
  8. Advisory note

Placeholders in ALL_CAPS or <angle brackets> are filled in by the command that renders this
report; comments like this one are instructions to the renderer and MUST NOT appear in the
written report file.
-->
# <Specification|Plan> Integrity Assessment

**Assessed**: <ISO date> · **Against**: <story.md | story.md, spec.md>
**Assessment context**: <INDEPENDENT|SELF-ASSESSED>   <!-- FR-037 -->
**Source digests**: <artifact> `sha256:<hex>`, <artifact> `sha256:<hex>`   <!-- FR-040 -->
<!-- If any digest no longer matches the previous report's recorded digest, state here which
     upstream artifact changed and that previous findings were based on a different version. -->

## Decisions for you (<N>)
<!--
  At most 3 items, highest severity first. Each item MUST name its classification, severity, and
  point to the Finding below it. If more than 3 qualify: "<N> shown; <M> further items require a
  decision (<ids>) — see the full table below." If none qualify: "No decision required."
-->

1. **<one-line summary of what needs a developer decision>.** <context sentence.> →
   *<the specific question the developer should answer>*
   `<CLASSIFICATION>` · <Severity> · see Finding <n>

## Outstanding accepted risk (<N>)                     <!-- FR-039 -->
<!-- One bullet per still-outstanding accepted risk carried from an earlier stage, restated
     ahead of this run's own findings, with its acceptance date and the developer's own reason.
     Include any risk THIS run auto-resolved, marked as such with its resolution_evidence and
     reported as reopenable. If none: "No outstanding accepted risk." -->

- **Accepted <date>, <stage> stage** — proceeded at <score>/100 with <what was weak/unmet>.
  Developer's reason: *"<verbatim>"*. Still unresolved.

## Integrity

<dimension_1> **<BAND>** <score>/<weight> · <dimension_2> **<BAND>** <score>/<weight> · … →
**<overall_score>/100**

| Dimension | Band | Score | Evidence |
|---|---|---|---|
| <Dimension name> | <BAND> | <score>/<weight> | <specific evidence citing the artifact> |

## Drift Classification summary

<N> elements compared: **<n> PRESERVED**, **<n> REFINED**, **<n> CLARIFIED**, **<n> DISCOVERED**,
**<n> ACCEPTED_SCOPE_CHANGE**, **<n> UNJUSTIFIED_DRIFT**.
Per-element table: appendix below.

### Finding <n>: <short name>
- **Source artifact**: <artifact>
- **Destination artifact**: <artifact> (<element id, if any>)
- **Original intent**: <what the source artifact intended>
- **New behaviour**: <what the destination artifact actually does/says>
- **Classification**: <CLASSIFICATION> · **Severity**: <High|Medium|Low>
- **Evidence**: <specific citation from both artifacts>
- **Question for the developer**: <the specific question to resolve this finding>

## Appendix — full per-element classification

| Element | Classification | Notes |
|---|---|---|
| <element id> | <CLASSIFICATION> | <one-line note> |

## Advisory note

This assessment does not block, modify, or reject the artifact (FR-022). All findings require
developer judgment.
