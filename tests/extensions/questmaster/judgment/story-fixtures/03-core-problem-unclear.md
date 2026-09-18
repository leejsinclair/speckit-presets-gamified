# Quest Story: Notification preference table (story-fixtures/03-core-problem-unclear.md)

<!-- Story-rubric judgment-tier fixture (research.md §11). A finished document, not an interview
     transcript — exercises the story rubric's scoring and readiness-classification logic on its
     own, independent of any Drift Classification layered on top of it in later stages. Expected
     bands and classification are recorded in judgment/expected/story-fixtures.json. -->

## 1. Quest Title

Notification preference table

## 2. Problem Statement

We need a NotificationPreference table so customers can manage their settings.

## 3. Who Is Affected / Actors

Customers.

## 4. Current Behaviour

There is no preference table today.

## 5. Use Cases

1. A customer changes a row in the NotificationPreference table.

## 6. Desired Outcomes

The NotificationPreference table exists and is used by the send pipeline.

## 7. Scope Boundaries

**In-Scope**: building the table.
**Out-of-Scope**: not stated.
**Adjacent**: not stated.

## 8. Success Criteria

The table exists in the schema.

## 9. Assumptions & Known Unknowns

**Assumed**: nothing specific was raised.
**Unknown**: nothing specific was raised.

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

- **2026-09-12** · story · asserted_fact — "We already decided on a table, just capture that."
  *Effect*: Recorded, but flagged: the 'problem' as stated is only a solution.

### Comprehension

### Decisions

## 16. Story Readiness Assessment

**Classification**: `NOT_READY`
**Score**: 26/100 (threshold: 70)
**Unmet critical conditions**: core_problem_unclear, success_not_evaluable.

## 17. Story Integrity Assessment

| Dimension | Band | Score | Evidence |
|---|---|---|---|
| Problem Definition | ABSENT | 0/15 | fixture-assigned band for problem_definition |
| Actors And Current State | WEAK | 3/10 | fixture-assigned band for actors_and_current_state |
| Use Cases | WEAK | 5/15 | fixture-assigned band for use_cases |
| Desired Outcomes | WEAK | 5/15 | fixture-assigned band for desired_outcomes |
| Scope And Boundaries | WEAK | 3/10 | fixture-assigned band for scope_and_boundaries |
| Success Criteria | WEAK | 3/10 | fixture-assigned band for success_criteria |
| Assumptions And Unknowns | ABSENT | 0/5 | fixture-assigned band for assumptions_and_unknowns |
| Constraints And Context | ABSENT | 0/5 | fixture-assigned band for constraints_and_context |
| Solution Neutrality | ABSENT | 0/5 | fixture-assigned band for solution_neutrality |
| Developer Judgment | ADEQUATE | 7/10 | fixture-assigned band for developer_judgment |

**Overall score**: 26/100
