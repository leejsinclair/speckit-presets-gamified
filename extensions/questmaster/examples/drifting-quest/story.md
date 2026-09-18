# Quest Story: Customer control over marketing email preferences (drifting-quest fixture)

<!-- Judgment-tier fixture (tests/extensions/questmaster/judgment/fixtures/). Paired with a
     spec.md and plan.md that each introduce unsupported scope, so this fixture exercises
     UNJUSTIFIED_DRIFT and ACCEPTED_SCOPE_CHANGE classification (SC-005). Intentionally the same
     underlying problem as examples/faithful-quest/ so the two pairs are directly comparable —
     the STORY here is deliberately narrow; the drift is introduced downstream, in spec.md/plan.md. -->

## 1. Quest Title

Customer control over marketing email preferences

## 2. Problem Statement

Customers receive marketing email they don't want and have no convenient way to control it.

## 3. Who Is Affected / Actors

Customers who receive marketing email.

## 4. Current Behaviour

All customers receive all marketing categories with no per-category opt-out.

## 5. Use Cases

1. **Customer disables one category.** A customer unchecks "Promotions" in account settings and
   stops receiving that category on the next send cycle.
2. **Customer disables all marketing email.** A customer turns off every category at once and
   confirms all three stop, while transactional email continues.

## 6. Desired Outcomes

Customers can disable marketing communications by category or entirely, and the change takes
effect for future sends.

## 7. Scope Boundaries

**In-Scope**: Per-category opt-out for the three existing marketing categories; an all-marketing
opt-out.

**Out-of-Scope / Non-Goals**: Transactional email. Any administrative tooling for support or
marketing to resend, override, or bulk-manage customer preferences on their behalf.

**Adjacent Concerns**: SMS preferences (not requested).

## 8. Success Criteria

- A customer who disables a category stops receiving it on the next send cycle.
- A customer who disables all marketing communications receives none of the three categories.

## 9. Assumptions & Known Unknowns

**Assumed**: Most complaints concern marketing email specifically, not transactional email.

**Unknown**: Whether SMS preferences will ever be requested.

## 10. Background / Context

N/A — Short Quest; no additional background beyond §2/§4 was material to this request.

## 11. Business Rules

Transactional and legal-notice email can never be disabled by this preference.

## 12. Constraints

Legal signed off on a 30-day retention window for preference-change history — this feature must
not retain that history longer than 30 days.

## 13. Proposed Solutions & Solution-Neutrality Assessment

None supplied.

## 14. Dragon's Questions

1. **Challenge** (category: `unsafe_assumption`): "Is a simple per-category boolean actually
   enough, or will marketing want to override a customer's preference for a one-time campaign?"
   **Response**: "No — if marketing ever wants that, it's a new, separate request. This quest is
   customer control, full stop; nothing here should let anyone else override a customer's own
   preference." **Disposition**: `answered`.

## Questmaster Record

### Judgment Ledger

- **2026-09-12** · story · asserted_constraint — "Legal signed off on a 30-day retention window
  for preference-change history, we can't keep it longer than that."
  *Effect*: Added to Constraints (§12).
- **2026-09-12** · dragon · dragon_response — "No — if marketing ever wants that, it's a new,
  separate request. This quest is customer control, full stop; nothing here should let anyone
  else override a customer's own preference."
  *Effect*: Confirmed §7's exclusion of administrative override tooling as deliberate, not an
  oversight.

### Comprehension

### Decisions

## 16. Story Readiness Assessment

**Classification**: `READY`
**Score**: 79/100 (threshold: 70)
**Unmet critical conditions**: none.

## 17. Story Integrity Assessment

| Dimension | Band | Score | Evidence |
|---|---|---|---|
| Problem definition | STRONG | 15/15 | §2 states the problem with no implementation noun |
| Actors and current state | ADEQUATE | 7/10 | §3 names the primary actor but current behavior in §4 is brief and support is not named as a secondary actor |
| Use cases | ADEQUATE | 10/15 | §5 has 2 meaningful cases with actor/goal/trigger/result, no failure path |
| Desired outcomes | STRONG | 15/15 | §6 stated as a resulting state, traceable to §2 |
| Scope and boundaries | STRONG | 10/10 | §7 explicitly excludes administrative override tooling as a non-goal |
| Success criteria | STRONG | 10/10 | §8's criteria are checkable without seeing the implementation |
| Assumptions and unknowns | ADEQUATE | 3/5 | §9 present and distinct but thin |
| Constraints and context | ADEQUATE | 3/5 | §12 specific and asserted; §10 explicitly marked N/A with a reason |
| Solution neutrality | STRONG | 5/5 | §13: "None supplied" — nothing to separate |
| Developer judgment | ADEQUATE | 10/10 | Judgment Ledger has 2 entries: an asserted constraint and a substantive Dragon response confirming a scope exclusion |

**Overall score**: 79/100 (technically ADEQUATE-heavy on use_cases/actors, so slightly lower than
the faithful-quest fixture — deliberate, so this fixture's story is not itself the thing under
test; the *spec/plan* drift downstream is).
