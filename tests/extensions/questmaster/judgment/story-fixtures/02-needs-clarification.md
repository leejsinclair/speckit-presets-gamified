# Quest Story: Basic search filters for the product catalog (story-fixtures/02-needs-clarification.md)

<!-- Story-rubric judgment-tier fixture (research.md §11). A finished document, not an interview
     transcript — exercises the story rubric's scoring and readiness-classification logic on its
     own, independent of any Drift Classification layered on top of it in later stages. Expected
     bands and classification are recorded in judgment/expected/story-fixtures.json. -->

## 1. Quest Title

Basic search filters for the product catalog

## 2. Problem Statement

Customers browsing the catalog can't narrow results by anything other than category, so they scroll through long lists to find what they want.

## 3. Who Is Affected / Actors

Customers browsing the catalog.

## 4. Current Behaviour

The catalog page lists all products in a category with no further filtering.

## 5. Use Cases

1. Customer filters by price range and sees only matching products.

## 6. Desired Outcomes

Customers can narrow catalog results using a small set of filters.

## 7. Scope Boundaries

**In-Scope**: price-range and in-stock filters.
**Out-of-Scope**: full-text search.
**Adjacent**: not identified.

## 8. Success Criteria

Customers can apply a filter and see a narrowed result set.

## 9. Assumptions & Known Unknowns

**Assumed**: price and stock are the two filters customers want most.
**Unknown**: whether other filters (brand, rating) matter — not asked about.

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

- **2026-09-12** · story · cut — "Drop brand filtering, nobody asked for it yet."
  *Effect*: Removed from scope.

### Comprehension

### Decisions

## 16. Story Readiness Assessment

**Classification**: `NEEDS_CLARIFICATION`
**Score**: 48/100 (threshold: 70)
**Unmet critical conditions**: none.

## 17. Story Integrity Assessment

| Dimension | Band | Score | Evidence |
|---|---|---|---|
| Problem Definition | ADEQUATE | 10/15 | fixture-assigned band for problem_definition |
| Actors And Current State | WEAK | 3/10 | fixture-assigned band for actors_and_current_state |
| Use Cases | WEAK | 5/15 | fixture-assigned band for use_cases |
| Desired Outcomes | ADEQUATE | 10/15 | fixture-assigned band for desired_outcomes |
| Scope And Boundaries | WEAK | 3/10 | fixture-assigned band for scope_and_boundaries |
| Success Criteria | WEAK | 3/10 | fixture-assigned band for success_criteria |
| Assumptions And Unknowns | WEAK | 2/5 | fixture-assigned band for assumptions_and_unknowns |
| Constraints And Context | ABSENT | 0/5 | fixture-assigned band for constraints_and_context |
| Solution Neutrality | STRONG | 5/5 | fixture-assigned band for solution_neutrality |
| Developer Judgment | ADEQUATE | 7/10 | fixture-assigned band for developer_judgment |

**Overall score**: 48/100
