<!--
Quest Story template (tasks.md T017, data-model.md § Quest Story Structure, FR-003).

17 sections in three groups:
  - Core (1-9): ALWAYS present, on both Short and Full quests.
  - Extended (10-13): REQUIRED on a Full Quest; on a Short Quest, included only where the
    developer's answers make one materially relevant — otherwise marked N/A with a one-line
    reason (never omitted or padded).
  - Recorded (14-17): produced by Questmaster itself, not by the interview.

A section genuinely not applicable is marked N/A with a one-line reason stating WHY, never
silently omitted and never padded with filler to look complete.

This file is rendered by name (net-new template, no `replaces:` needed) when
/speckit-questmaster-story writes story.md or pending-story.md. Comments like this one are
authoring guidance for whoever fills the template in (developer interview + Questmaster) and
MUST be removed from the final written artifact; the section headings themselves are the
contract other tooling (qm-digest.sh, qm-record.sh, check-spec/check-plan) reads by name.
-->
# Quest Story: <Quest Title>

<!-- ============================== CORE SECTIONS (always present) ============================== -->

## 1. Quest Title
<!-- Complete when: a reader unfamiliar with the request can identify the feature from the title
     alone. Storyteller question: "What would you call this in one line to a colleague?" -->



## 2. Problem Statement
<!-- Complete when: contains no implementation noun and would still be true if the eventual
     solution changed. Storyteller question: "What is undesirable about today's situation? If
     nothing changes, what stays wrong?" -->



## 3. Who Is Affected / Actors
<!-- Complete when: every actor referenced later in Use Cases/Success Criteria is named here.
     Storyteller question: "Who specifically experiences this? Is there more than one kind of
     affected party?" -->



## 4. Current Behaviour
<!-- Complete when: a reader could describe today's behavior without seeing the code.
     Storyteller question: "What actually happens today, step by step?" -->



## 5. Use Cases
<!-- Complete when: each functional requirement later in spec.md can point to a use case that
     motivates it. 2-4 cases; each with actor, goal, trigger, expected result, and any important
     alternate/failure path (FR-006). Storyteller question: "Walk me through the main way someone
     would use this. What triggers it? What could go wrong?" -->



## 6. Desired Outcomes
<!-- Complete when: stated as a resulting state, not an implementation action. Storyteller
     question: "If this is solved, what is different? What can someone now do or not experience?" -->



## 7. Scope Boundaries
<!-- Complete when: a reader can tell whether any given behavior is this quest's responsibility.
     Three DISTINCT lists (FR-007) — do not collapse or restate one as the negative of another. -->

**In-Scope**:

**Out-of-Scope / Non-Goals**:

**Adjacent Concerns**:

## 8. Success Criteria
<!-- Complete when: every criterion is checkable without reference to how it was implemented
     (FR-009). Storyteller question: "How will we know, after shipping, that this actually worked?" -->



## 9. Assumptions & Known Unknowns
<!-- Complete when: every assumption is phrased as a belief; every unknown, if resolved, would
     change a decision. Keep distinct from Known Facts (FR-008) — do not collapse into one list. -->

**Assumed**:

**Unknown**:

<!-- ====================== EXTENDED SECTIONS (Full Quest required; Short Quest where material) ====================== -->

## 10. Background / Context
<!-- Complete when: a reader with no prior context understands where this sits in the product.
     If not applicable on a Short Quest, write: "N/A — <one-line reason>". -->



## 11. Business Rules
<!-- Complete when: every rule is a domain constraint, not an implementation choice. Do not
     confuse with a technical constraint (see §12). If not applicable: "N/A — <one-line reason>". -->



## 12. Constraints
<!-- Complete when: each constraint is something the requester actually asserted, not inferred.
     If not applicable: "N/A — <one-line reason>". -->



## 13. Proposed Solutions & Solution-Neutrality Assessment
<!-- Complete when: every part of a supplied proposal is classified into exactly one of
     requirement / implementation choice / assumption / unnecessary constraint; "None supplied"
     when the developer offered no solution. Never silently adopt or reject a supplied proposal
     (FR-005). If the developer resists separating problem from solution, record the proposal
     anyway, note that neutrality could not be fully assessed and why, and continue. -->

**Proposal as stated**:

**Classification**:
- Requirement(s):
- Implementation detail:
- Assumption(s):
- Unnecessary constraint(s):

<!-- ============================== RECORDED SECTIONS (produced by Questmaster) ============================== -->

## 14. Dragon's Questions
<!-- Complete when: every challenge has a recorded response; challenges cite this story's own
     content, not generic risk categories (FR-034). A dismissal is recorded as dismissed, never
     dropped. 2-3 challenges on a Short Quest, 3-5 on a Full Quest. -->



## Questmaster Record
<!-- FR-027. Three subsections. Populated by qm-record.sh; never hand-edit the machine-readable
     trailers on a Decision entry. Present whenever any developer judgment, comprehension answer,
     or override exists; Decisions is empty until an override occurs. -->

### Judgment Ledger

### Comprehension

### Decisions

## 16. Story Readiness Assessment
<!-- Complete when: states the classification, the score, the threshold, and which critical
     conditions (if any) are unmet (FR-012). Computed by qm-readiness.sh, never assigned freely. -->



## 17. Story Integrity Assessment
<!-- Complete when: every one of the ten dimensions has a band and a specific evidence line
     (FR-010/FR-011/FR-036). Computed by qm-score.sh from bands the Storyteller assigns; a
     section's mere presence MUST NOT earn a band above ABSENT. -->

