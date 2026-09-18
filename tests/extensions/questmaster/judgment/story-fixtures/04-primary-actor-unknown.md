# Quest Story: Notification preference controls (story-fixtures/04-primary-actor-unknown.md)

<!-- Story-rubric judgment-tier fixture (research.md §11). A finished document, not an interview
     transcript — exercises the story rubric's scoring and readiness-classification logic on its
     own, independent of any Drift Classification layered on top of it in later stages. Expected
     bands and classification are recorded in judgment/expected/story-fixtures.json. -->

## 1. Quest Title

Notification preference controls

## 2. Problem Statement

Users receive marketing email they don't want and have no convenient way to control it.

## 3. Who Is Affected / Actors

Users.

## 4. Current Behaviour

All users receive all marketing categories with no per-category opt-out.

## 5. Use Cases

1. A user disables a category and stops receiving it, with a clear confirmation.
2. A user disables all marketing and confirms transactional mail still arrives.
3. A user re-enables a category and starts receiving it again on the next cycle.

## 6. Desired Outcomes

Users can disable marketing communications by category or entirely, and the change takes effect for future sends.

## 7. Scope Boundaries

**In-Scope**: per-category and all-marketing opt-out.
**Out-of-Scope**: transactional email; admin override tooling.
**Adjacent**: SMS preferences.

## 8. Success Criteria

A user who disables a category stops receiving it within one send cycle; a user who disables all marketing receives none of the three while transactional is unaffected.

## 9. Assumptions & Known Unknowns

**Assumed**: most complaints concern marketing, not transactional email.
**Unknown**: whether SMS preferences will ever be requested.

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

- **2026-09-12** · story · asserted_constraint — "Legal capped retention at 30 days last quarter."
  *Effect*: Added to Constraints.
- **2026-09-12** · dragon · dragon_response — "That race is fine, it's a single-row write on a 15-minute batch — not worth synchronizing for."
  *Effect*: Accepted as risk.

### Comprehension

### Decisions

## 16. Story Readiness Assessment

**Classification**: `NOT_READY`
**Score**: 89/100 (threshold: 70)
**Unmet critical conditions**: primary_actor_unknown.

## 17. Story Integrity Assessment

| Dimension | Band | Score | Evidence |
|---|---|---|---|
| Problem Definition | STRONG | 15/15 | fixture-assigned band for problem_definition |
| Actors And Current State | WEAK | 3/10 | fixture-assigned band for actors_and_current_state |
| Use Cases | STRONG | 15/15 | fixture-assigned band for use_cases |
| Desired Outcomes | STRONG | 15/15 | fixture-assigned band for desired_outcomes |
| Scope And Boundaries | STRONG | 10/10 | fixture-assigned band for scope_and_boundaries |
| Success Criteria | STRONG | 10/10 | fixture-assigned band for success_criteria |
| Assumptions And Unknowns | ADEQUATE | 3/5 | fixture-assigned band for assumptions_and_unknowns |
| Constraints And Context | ADEQUATE | 3/5 | fixture-assigned band for constraints_and_context |
| Solution Neutrality | STRONG | 5/5 | fixture-assigned band for solution_neutrality |
| Developer Judgment | STRONG | 10/10 | fixture-assigned band for developer_judgment |

**Overall score**: 89/100
