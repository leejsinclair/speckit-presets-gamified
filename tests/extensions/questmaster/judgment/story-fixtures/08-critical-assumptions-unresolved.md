# Quest Story: Per-category email opt-out (story-fixtures/08-critical-assumptions-unresolved.md)

<!-- Story-rubric judgment-tier fixture (research.md §11). A finished document, not an interview
     transcript — exercises the story rubric's scoring and readiness-classification logic on its
     own, independent of any Drift Classification layered on top of it in later stages. Expected
     bands and classification are recorded in judgment/expected/story-fixtures.json. -->

## 1. Quest Title

Per-category email opt-out

## 2. Problem Statement

Customers receive marketing email they don't want and have no convenient way to control it.

## 3. Who Is Affected / Actors

Customers who receive marketing email.

## 4. Current Behaviour

All customers receive all marketing categories with no per-category opt-out.

## 5. Use Cases

1. Customer disables a category and stops receiving it.
2. Customer disables all marketing and confirms transactional mail still arrives.

## 6. Desired Outcomes

Customers can disable marketing communications by category or entirely, and the change takes effect for future sends.

## 7. Scope Boundaries

**In-Scope**: per-category and all-marketing opt-out.
**Out-of-Scope**: transactional email.
**Adjacent**: SMS preferences.

## 8. Success Criteria

Customers can disable a category and it takes effect.

## 9. Assumptions & Known Unknowns

**Assumed**: we're assuming the existing customer ID is stable and globally unique across every system that needs to read this preference — this hasn't been checked, and if it's wrong, the whole per-customer storage design is wrong.
**Unknown**: not stated.

## 10. Background / Context

N/A — Short Quest; no additional background was material to this fixture.

## 11. Business Rules

N/A — no domain rule beyond what §11's problem framing already states was material to this fixture.

## 12. Constraints

N/A — no explicit constraint was asserted by the requester in this fixture.

## 13. Proposed Solutions & Solution-Neutrality Assessment

None supplied.

## 14. Dragon's Questions

1. **Challenge** (category: `unsafe_assumption`): "Is a single boolean per category actually enough?"
   **Response**: "Yes — nothing here needs more granularity than on/off per category." **Disposition**: `answered`.

## Questmaster Record

### Judgment Ledger

- **2026-09-12** · story · asserted_fact — "We've never actually checked whether customer IDs are unique across every downstream system."
  *Effect*: Recorded as an unresolved, load-bearing assumption.

### Comprehension

### Decisions

## 16. Story Readiness Assessment

**Classification**: `NOT_READY`
**Score**: 68/100 (threshold: 70)
**Unmet critical conditions**: critical_assumptions_unresolved.

## 17. Story Integrity Assessment

| Dimension | Band | Score | Evidence |
|---|---|---|---|
| Problem Definition | STRONG | 15/15 | fixture-assigned band for problem_definition |
| Actors And Current State | ADEQUATE | 7/10 | fixture-assigned band for actors_and_current_state |
| Use Cases | ADEQUATE | 10/15 | fixture-assigned band for use_cases |
| Desired Outcomes | ADEQUATE | 10/15 | fixture-assigned band for desired_outcomes |
| Scope And Boundaries | ADEQUATE | 7/10 | fixture-assigned band for scope_and_boundaries |
| Success Criteria | WEAK | 3/10 | fixture-assigned band for success_criteria |
| Assumptions And Unknowns | WEAK | 2/5 | fixture-assigned band for assumptions_and_unknowns |
| Constraints And Context | WEAK | 2/5 | fixture-assigned band for constraints_and_context |
| Solution Neutrality | STRONG | 5/5 | fixture-assigned band for solution_neutrality |
| Developer Judgment | ADEQUATE | 7/10 | fixture-assigned band for developer_judgment |

**Overall score**: 68/100
