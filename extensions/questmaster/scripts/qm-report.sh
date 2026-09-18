#!/bin/sh
# qm-report.sh — decision-first Integrity report renderer (FR-038, data-model.md § Integrity
# Assessment Report, tasks.md T010/T026's presentational contract).
#
# Takes ONE JSON "report spec" (judgment content: bands, drift classifications, findings — all
# supplied by the calling command, which is where that judgment belongs) and renders it into the
# exact normative section order, deterministically: header -> Decisions for you (>=3 capped, with
# remainder counted+named, or "No decision required.") -> Outstanding accepted risk -> Integrity
# (banded summary) -> Drift Classification summary (aggregate counts) -> Findings -> Appendix
# (full per-element table) -> Advisory note. This script owns ORDERING, CAPPING, and
# AGGREGATION — never the judgment calls (which band, which classification) that fill the JSON.
#
# Usage:
#   qm-report.sh <report-spec.json>
#
# Report spec schema (all judgment-derived fields; see the schema literal at the top of the
# embedded Python for the authoritative field list):
#   {
#     "artifact_type": "Specification"|"Plan", "assessed_date": "...", "against": "...",
#     "context": "INDEPENDENT"|"SELF-ASSESSED",
#     "digests": [{"artifact":..., "digest":...}], "digest_mismatch_notes": [...],
#     "decisions": [{"summary":..., "question":..., "classification":..., "severity":...,
#                     "finding_ref": <int, matches a findings[].id>}],
#     "outstanding_risk": [{"accepted_date":..., "stage":..., "score":.., "unmet_summary":...,
#                            "reason":..., "note":...}],
#     "dimension_bands": [{"name":..., "band":..., "score":.., "weight":.., "evidence":...}],
#     "drift_counts": {"PRESERVED":.., "REFINED":.., "CLARIFIED":.., "DISCOVERED":..,
#                       "ACCEPTED_SCOPE_CHANGE":.., "UNJUSTIFIED_DRIFT":..},
#     "findings": [{"id":.., "short_name":..., "source_artifact":..., "destination_artifact":...,
#                    "original_intent":..., "new_behaviour":..., "classification":...,
#                    "severity":..., "evidence":..., "question":...}],
#     "appendix": [{"element":..., "classification":..., "notes":...}],
#     "comprehension_cross_reference": "..."   (optional, Plan Integrity only),
#     "advisory_note": "..."   (optional; a documented default is used if absent)
#   }
#
# Output (stdout): the rendered Markdown report, ready to write verbatim to spec-integrity.md /
# plan-integrity.md and to present in the response (FR-038 requires both to match).

set -eu

SPEC_FILE="${1:?usage: qm-report.sh <report-spec.json>}"
if [ ! -f "$SPEC_FILE" ]; then
  echo "qm-report: report spec not found: $SPEC_FILE" >&2
  exit 1
fi

python3 - "$SPEC_FILE" <<'PY'
import sys, json

with open(sys.argv[1]) as f:
    spec = json.load(f)

def g(key, default):
    return spec.get(key, default)

lines = []
add = lines.append

artifact_type = g("artifact_type", "Specification")
add(f"# {artifact_type} Integrity Assessment")
add("")
add(f"**Assessed**: {g('assessed_date', '')} · **Against**: {g('against', '')}")
add(f"**Assessment context**: {g('context', 'SELF-ASSESSED')}")
digests = g("digests", [])
digest_str = ", ".join(f"{d['artifact']} `{d['digest']}`" for d in digests)
add(f"**Source digests**: {digest_str}")
for note in g("digest_mismatch_notes", []):
    add(f"> {note}")
add("")

# --- Decisions for you (cap 3, count+name remainder, or "No decision required.") ---
decisions = g("decisions", [])
add(f"## Decisions for you ({min(len(decisions), 3)})")
add("")
if not decisions:
    add("No decision required.")
else:
    shown = decisions[:3]
    remainder = decisions[3:]
    for idx, d in enumerate(shown, start=1):
        ref = d.get("finding_ref")
        finding_note = f" · see Finding {ref}" if ref is not None else ""
        add(
            f"{idx}. **{d.get('summary','')}** → *{d.get('question','')}* "
            f"`{d.get('classification','')}` · {d.get('severity','')}{finding_note}"
        )
    if remainder:
        names = ", ".join(str(r.get("element_id", r.get("summary", "?"))) for r in remainder)
        add("")
        add(f"{len(shown)} shown; {len(remainder)} further items require a decision ({names}) — see the full table below.")
add("")

# --- Outstanding accepted risk ---
risks = g("outstanding_risk", [])
add(f"## Outstanding accepted risk ({len(risks)})")
add("")
if not risks:
    add("No outstanding accepted risk.")
else:
    for r in risks:
        add(
            f"- **Accepted {r.get('accepted_date','')}, {r.get('stage','')} stage** — "
            f"proceeded at {r.get('score','?')}/100 with {r.get('unmet_summary','')}. "
            f"Developer's reason: *\"{r.get('reason','')}\"*. {r.get('note','Still unresolved.')}"
        )
add("")

# --- Integrity (banded dimension summary) ---
add("## Integrity")
add("")
bands = g("dimension_bands", [])
overall = sum(b.get("score", 0) for b in bands)
inline = " · ".join(f"{b['name']} **{b['band']}** {b['score']}/{b['weight']}" for b in bands)
add(f"{inline} → **{overall}/100**")
add("")
add("| Dimension | Band | Score | Evidence |")
add("|---|---|---|---|")
for b in bands:
    add(f"| {b['name']} | {b['band']} | {b['score']}/{b['weight']} | {b.get('evidence','')} |")
add("")

# --- Drift Classification summary (aggregate PRESERVED/REFINED/CLARIFIED; full table in appendix) ---
counts = g("drift_counts", {})
total = sum(counts.values())
order = ["PRESERVED", "REFINED", "CLARIFIED", "DISCOVERED", "ACCEPTED_SCOPE_CHANGE", "UNJUSTIFIED_DRIFT"]
count_str = ", ".join(f"**{counts.get(k,0)} {k}**" for k in order if counts.get(k, 0) or k in ("PRESERVED","REFINED","CLARIFIED"))
add("## Drift Classification summary")
add("")
add(f"{total} elements compared: {count_str}.")
add("Per-element table: appendix below.")
if g("comprehension_cross_reference", None):
    add("")
    add(g("comprehension_cross_reference", ""))
add("")

# --- Findings ---
for finding in g("findings", []):
    add(f"### Finding {finding['id']}: {finding.get('short_name','')}")
    add(f"- **Source artifact**: {finding.get('source_artifact','')}")
    add(f"- **Destination artifact**: {finding.get('destination_artifact','')}")
    add(f"- **Original intent**: {finding.get('original_intent','')}")
    add(f"- **New behaviour**: {finding.get('new_behaviour','')}")
    add(f"- **Classification**: {finding.get('classification','')} · **Severity**: {finding.get('severity','')}")
    add(f"- **Evidence**: {finding.get('evidence','')}")
    add(f"- **Question for the developer**: {finding.get('question','')}")
    add("")

# --- Appendix: full per-element classification ---
add("## Appendix — full per-element classification")
add("")
add("| Element | Classification | Notes |")
add("|---|---|---|")
for row in g("appendix", []):
    add(f"| {row.get('element','')} | {row.get('classification','')} | {row.get('notes','')} |")
add("")

# --- Advisory note ---
add("## Advisory note")
add("")
add(g("advisory_note", "This assessment does not block, modify, or reject the artifact (FR-022). All findings require developer judgment."))

print("\n".join(lines))
PY
