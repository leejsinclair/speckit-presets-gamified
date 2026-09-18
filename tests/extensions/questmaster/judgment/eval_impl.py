#!/usr/bin/env python3
"""eval_impl.py — implementation behind eval.sh (tasks.md T051).

Runs real `claude -p` assessments N times per fixture, across both judgment corpora, and reports
agreement rate against the human-assigned expected labels plus run-to-run band/score variance
(FR-036/SC-009: >=90% of bands stable, score within 5 points; SC-016: >=80% agreement rate per
corpus). See judgment/eval.sh for the CLI contract.
"""
import argparse
import json
import re
import subprocess
import sys
import tempfile
import os
import statistics

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
SCRIPTS = os.path.join(REPO_ROOT, "extensions", "questmaster", "scripts")
STORY_FIXTURES_DIR = os.path.join(REPO_ROOT, "tests", "extensions", "questmaster", "judgment", "story-fixtures")
EXPECTED_DIR = os.path.join(REPO_ROOT, "tests", "extensions", "questmaster", "judgment", "expected")


def sh(*args, input_text=None):
    result = subprocess.run(["sh"] + list(args), capture_output=True, text=True, input=input_text)
    if result.returncode != 0:
        raise RuntimeError(f"command failed: sh {' '.join(args)}\n{result.stderr}")
    return result.stdout


def load_config():
    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
        config_path = f.name
    out = sh(os.path.join(SCRIPTS, "qm-config.sh"),
             os.path.join(REPO_ROOT, "extensions", "questmaster", "config", "questmaster-config.template.yml"),
             "/dev/null")
    with open(config_path, "w") as f:
        f.write(out)
    return config_path, json.loads(out)


def claude_json(prompt, schema):
    result = subprocess.run(
        ["claude", "-p", "--output-format", "json", "--json-schema", json.dumps(schema), prompt],
        capture_output=True, text=True, timeout=600,
    )
    if result.returncode != 0:
        raise RuntimeError(f"claude -p failed: {result.stderr}")
    envelope = json.loads(result.stdout)
    structured = envelope.get("structured_output")
    if structured is None:
        raise RuntimeError(f"claude -p returned no structured_output: {result.stdout[:500]}")
    return structured


def strip_recorded_sections(story_text):
    """Remove the recorded assessment (Story Readiness/Integrity Assessment, §16-17) so the
    fixture's own answer key is never shown to the assessor being evaluated. Keeps everything
    through Dragon's Questions and the Questmaster Record (Judgment Ledger is real input)."""
    m = re.search(r'\n## 16\. Story Readiness Assessment', story_text)
    return story_text[:m.start()] if m else story_text


# ---------------------------------------------------------------------------
# Story-rubric tier
# ---------------------------------------------------------------------------

STORY_BAND_SCHEMA = {
    "type": "object",
    "properties": {
        "bands": {
            "type": "object",
            "properties": {d: {"type": "string", "enum": ["ABSENT", "WEAK", "ADEQUATE", "STRONG"]}
                            for d in [
                "problem_definition", "actors_and_current_state", "use_cases", "desired_outcomes",
                "scope_and_boundaries", "success_criteria", "assumptions_and_unknowns",
                "constraints_and_context", "solution_neutrality", "developer_judgment",
            ]},
            "required": [
                "problem_definition", "actors_and_current_state", "use_cases", "desired_outcomes",
                "scope_and_boundaries", "success_criteria", "assumptions_and_unknowns",
                "constraints_and_context", "solution_neutrality", "developer_judgment",
            ],
        },
        "unmet_critical_conditions": {
            "type": "array",
            "items": {"type": "string", "enum": [
                "core_problem_unclear", "primary_actor_unknown", "desired_outcome_absent",
                "critical_use_cases_missing", "scope_unbounded", "critical_assumptions_unresolved",
                "success_not_evaluable",
            ]},
        },
    },
    "required": ["bands", "unmet_critical_conditions"],
}


def run_story_tier(config_path, config, n, limit, out_dir):
    with open(os.path.join(EXPECTED_DIR, "story-fixtures.json")) as f:
        expected = json.load(f)
    if limit:
        expected = expected[:limit]

    dims = list(STORY_BAND_SCHEMA["properties"]["bands"]["properties"].keys())
    anchors = {d["name"]: d.get("anchors", {}) for d in config["story_rubric"]["dimensions"]}
    threshold = config["story_rubric"]["readiness_threshold"]

    band_matches, band_total = 0, 0
    status_matches, status_total = 0, 0
    per_fixture_scores = {}
    per_fixture_band_stability = {}
    results = []

    for e in expected:
        fixture_path = os.path.join(STORY_FIXTURES_DIR, e["fixture"])
        with open(fixture_path) as f:
            full_text = f.read()
        stripped = strip_recorded_sections(full_text)

        rubric_desc = "\n".join(
            f"- {d}: STRONG={anchors[d].get('STRONG','')} | ADEQUATE={anchors[d].get('ADEQUATE','')} | "
            f"WEAK={anchors[d].get('WEAK','')} | ABSENT={anchors[d].get('ABSENT','')}"
            for d in dims
        )
        prompt = (
            "You are assessing a Quest Story (a structured problem-framing document) against a "
            "ten-dimension rubric. Band EACH dimension as exactly one of ABSENT/WEAK/ADEQUATE/"
            "STRONG using the anchors below, and separately list which critical conditions (from "
            "the closed list given) are unmet based on the story's CONTENT. Do not invent "
            "conditions outside that list. `developer_judgment` must be banded from the "
            "Questmaster Record's Judgment Ledger ALONE, never from the quality of the rest of "
            "the document.\n\n"
            f"RUBRIC ANCHORS:\n{rubric_desc}\n\n"
            f"STORY DOCUMENT:\n{stripped}\n"
        )

        run_scores = []
        run_bands_list = []
        for run_idx in range(n):
            try:
                result = claude_json(prompt, STORY_BAND_SCHEMA)
            except Exception as ex:
                print(f"  [{e['fixture']}] run {run_idx+1}: ERROR: {ex}", file=sys.stderr)
                continue

            bands = result["bands"]
            with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as bf:
                json.dump(bands, bf)
                bands_path = bf.name
            score_out = json.loads(sh(os.path.join(SCRIPTS, "qm-score.sh"), config_path, "story_rubric", bands_path))
            os.remove(bands_path)
            overall = score_out["overall_score"]

            with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as uf:
                json.dump(result["unmet_critical_conditions"], uf)
                unmet_path = uf.name
            readiness_out = json.loads(sh(
                os.path.join(SCRIPTS, "qm-readiness.sh"), fixture_path, str(overall), str(threshold), unmet_path
            ))
            os.remove(unmet_path)

            run_scores.append(overall)
            run_bands_list.append(bands)

            dim_matches = sum(1 for d in dims if bands.get(d) == e["expected_bands"].get(d))
            band_matches += dim_matches
            band_total += len(dims)

            status_ok = readiness_out["status"] == e["expected_status"]
            status_matches += 1 if status_ok else 0
            status_total += 1

            results.append({
                "fixture": e["fixture"], "run": run_idx + 1, "bands": bands, "overall_score": overall,
                "status": readiness_out["status"], "expected_status": e["expected_status"],
                "dim_matches": dim_matches, "dim_total": len(dims),
            })
            print(f"  [{e['fixture']}] run {run_idx+1}: score={overall} (expected {e['expected_overall_score']}) "
                  f"status={readiness_out['status']} (expected {e['expected_status']}) "
                  f"bands {dim_matches}/{len(dims)} match")

        if run_scores:
            per_fixture_scores[e["fixture"]] = run_scores
        if len(run_bands_list) > 1:
            stable = 0
            for d in dims:
                values = {b.get(d) for b in run_bands_list}
                if len(values) == 1:
                    stable += 1
            per_fixture_band_stability[e["fixture"]] = stable / len(dims)

    with open(os.path.join(out_dir, "story_tier_results.json"), "w") as f:
        json.dump(results, f, indent=2)

    band_agreement = band_matches / band_total if band_total else 0.0
    status_agreement = status_matches / status_total if status_total else 0.0
    score_variance = {
        fx: (max(scores) - min(scores)) for fx, scores in per_fixture_scores.items()
    }
    max_score_range = max(score_variance.values()) if score_variance else 0
    avg_band_stability = statistics.mean(per_fixture_band_stability.values()) if per_fixture_band_stability else None

    return {
        "corpus": "story-fixtures",
        "fixtures_evaluated": len(expected),
        "runs_per_fixture": n,
        "band_agreement_rate": round(band_agreement, 4),
        "status_agreement_rate": round(status_agreement, 4),
        "max_score_range_within_a_fixture": max_score_range,
        "avg_band_stability_across_runs": round(avg_band_stability, 4) if avg_band_stability is not None else None,
        "per_fixture_score_range": score_variance,
    }


# ---------------------------------------------------------------------------
# Cross-artifact tier
# ---------------------------------------------------------------------------

def _match_element(expected_key, got_by_element):
    """Match a fixture's expected element key against the model's free-text element labels.

    The model is asked to key elements by their document ID (e.g. "REQ-001") when the
    document gives one, but it often returns a fuller descriptive label with the ID embedded
    (e.g. "REQ-001: generate a short link..."), so exact-string equality alone matches almost
    nothing even when the model's classification is correct. Falls back to a whole-word ID
    search, then to significant-word overlap for descriptive (non-ID) expected keys such as
    "auth-gateway microservice"."""
    if expected_key in got_by_element:
        return got_by_element[expected_key]
    if re.match(r'^[A-Za-z]+-\d+$', expected_key):
        for k, v in got_by_element.items():
            if re.search(r'\b' + re.escape(expected_key) + r'\b', k):
                return v
        return None
    exp_words = set(re.findall(r'[a-z]{4,}', expected_key.lower()))
    if not exp_words:
        return None
    best, best_overlap = None, 0
    for k, v in got_by_element.items():
        k_words = set(re.findall(r'[a-z]{4,}', k.lower()))
        overlap = len(exp_words & k_words)
        if overlap > best_overlap and overlap >= max(1, len(exp_words) // 2):
            best_overlap, best = overlap, v
    return best


DRIFT_SCHEMA = {
    "type": "object",
    "properties": {
        "elements": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "element": {"type": "string"},
                    "classification": {"type": "string", "enum": [
                        "PRESERVED", "REFINED", "CLARIFIED", "DISCOVERED",
                        "ACCEPTED_SCOPE_CHANGE", "UNJUSTIFIED_DRIFT",
                    ]},
                },
                "required": ["element", "classification"],
            },
        },
        "dimension_bands": {
            "type": "object",
            "additionalProperties": {"type": "string", "enum": ["ABSENT", "WEAK", "ADEQUATE", "STRONG"]},
        },
    },
    "required": ["elements", "dimension_bands"],
}


def run_cross_tier(n, limit, out_dir):
    with open(os.path.join(EXPECTED_DIR, "fixtures.json")) as f:
        expected = json.load(f)
    if limit:
        expected = expected[:limit]

    element_matches, element_total = 0, 0
    band_in_range, band_range_total = 0, 0
    results = []

    for e in expected:
        fdir = os.path.join(REPO_ROOT, e.get("dir", f"tests/extensions/questmaster/judgment/fixtures/{e['fixture']}"))
        story_path = os.path.join(fdir, "story.md")
        spec_path = os.path.join(fdir, "spec.md")
        plan_path = os.path.join(fdir, "plan.md") if e.get("has_plan") else None

        with open(story_path) as f:
            story_text = f.read()
        with open(spec_path) as f:
            spec_text = f.read()
        plan_text = None
        if plan_path and os.path.exists(plan_path):
            with open(plan_path) as f:
                plan_text = f.read()

        id_instruction = (
            "Set each element's `element` field to EXACTLY its document ID label (e.g. "
            "\"REQ-001\", \"FR-003\"), verbatim and with no extra words, whenever the document "
            "gives the item such a label. Only fall back to a short (<=6 word) descriptive slug "
            "for items the document does not label with an ID."
        )
        if plan_text:
            prompt = (
                "Compare plan.md against BOTH story.md and spec.md below. For every named "
                "component/requirement/element, assign exactly one Drift Classification: "
                "PRESERVED, REFINED, CLARIFIED, DISCOVERED, ACCEPTED_SCOPE_CHANGE, or "
                "UNJUSTIFIED_DRIFT. Consult each artifact's Questmaster Record -> Decisions "
                "before ever using ACCEPTED_SCOPE_CHANGE. " + id_instruction + " Also band "
                "plan_integrity_rubric dimensions you have evidence for (intent_preservation, "
                "specification_coverage, constraint_preservation, proportionality, legibility) "
                "as ABSENT/WEAK/ADEQUATE/STRONG.\n\n"
                f"STORY.MD:\n{story_text}\n\nSPEC.MD:\n{spec_text}\n\nPLAN.MD:\n{plan_text}\n"
            )
        else:
            prompt = (
                "Compare spec.md against story.md below. For every requirement/scope item/"
                "assumption, assign exactly one Drift Classification: PRESERVED, REFINED, "
                "CLARIFIED, DISCOVERED, ACCEPTED_SCOPE_CHANGE, or UNJUSTIFIED_DRIFT. Consult "
                "spec.md's Questmaster Record -> Decisions before ever using "
                "ACCEPTED_SCOPE_CHANGE; otherwise an out-of-story-scope element is "
                "UNJUSTIFIED_DRIFT. Never classify content UNJUSTIFIED_DRIFT solely for not "
                "being verbatim in the story. " + id_instruction + " Also band "
                "specification_integrity_rubric dimensions you have evidence for "
                "(story_fidelity, scope_discipline) as ABSENT/WEAK/ADEQUATE/STRONG.\n\n"
                f"STORY.MD:\n{story_text}\n\nSPEC.MD:\n{spec_text}\n"
            )

        for run_idx in range(n):
            try:
                result = claude_json(prompt, DRIFT_SCHEMA)
            except Exception as ex:
                print(f"  [{e['fixture']}] run {run_idx+1}: ERROR: {ex}", file=sys.stderr)
                continue

            got_by_element = {el["element"]: el["classification"] for el in result["elements"]}
            fixture_matches = 0
            for expected_el in e["elements"]:
                element_total += 1
                got = _match_element(expected_el["element"], got_by_element)
                if got == expected_el["expected_classification"]:
                    element_matches += 1
                    fixture_matches += 1

            for dim, allowed in e.get("expected_band_ranges", {}).items():
                got_band = result.get("dimension_bands", {}).get(dim)
                if got_band is not None:
                    band_range_total += 1
                    if got_band in allowed:
                        band_in_range += 1

            results.append({
                "fixture": e["fixture"], "run": run_idx + 1,
                "elements_matched": fixture_matches, "elements_total": len(e["elements"]),
                "got": got_by_element,
            })
            print(f"  [{e['fixture']}] run {run_idx+1}: {fixture_matches}/{len(e['elements'])} elements matched")

    with open(os.path.join(out_dir, "cross_tier_results.json"), "w") as f:
        json.dump(results, f, indent=2)

    return {
        "corpus": "cross-artifact fixtures",
        "fixtures_evaluated": len(expected),
        "runs_per_fixture": n,
        "element_classification_agreement_rate": round(element_matches / element_total, 4) if element_total else 0.0,
        "band_in_expected_range_rate": round(band_in_range / band_range_total, 4) if band_range_total else None,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--n", type=int, default=3)
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument("--story-only", action="store_true")
    parser.add_argument("--cross-only", action="store_true")
    parser.add_argument("--out", default=None)
    args = parser.parse_args()

    out_dir = args.out or tempfile.mkdtemp(prefix="qm-eval-")
    os.makedirs(out_dir, exist_ok=True)

    config_path, config = load_config()

    summary = {}
    if not args.cross_only:
        print("== Story-rubric tier ==")
        summary["story"] = run_story_tier(config_path, config, args.n, args.limit, out_dir)
    if not args.story_only:
        print("== Cross-artifact tier ==")
        summary["cross"] = run_cross_tier(args.n, args.limit, out_dir)

    print("\n== Summary ==")
    print(json.dumps(summary, indent=2))
    with open(os.path.join(out_dir, "summary.json"), "w") as f:
        json.dump(summary, f, indent=2)
    print(f"\nRaw results written to {out_dir}")

    ok = True
    if "story" in summary:
        if summary["story"]["status_agreement_rate"] < 0.80:
            print("FAIL: story-fixtures status agreement below 80% target (SC-016)", file=sys.stderr)
            ok = False
        if summary["story"]["avg_band_stability_across_runs"] is not None and summary["story"]["avg_band_stability_across_runs"] < 0.90:
            print("FAIL: story-fixtures band stability below 90% target (FR-036)", file=sys.stderr)
            ok = False
    if "cross" in summary:
        if summary["cross"]["element_classification_agreement_rate"] < 0.80:
            print("FAIL: cross-artifact element classification agreement below 80% target (SC-016)", file=sys.stderr)
            ok = False

    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
