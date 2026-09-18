# Feature Specification: Customer control over marketing email preferences

**Feature Branch**: `001-marketing-email-preferences`
**Created**: 2026-09-13
**Status**: Draft

## User Scenarios & Testing

### User Story 1 — Customer disables one marketing category (Priority: P1)

A customer who is tired of promotional email disables just the "Promotions" category and
continues to receive the other two categories.

**Acceptance Scenarios**:
1. **Given** a customer with all three marketing categories enabled, **When** they disable
   "Promotions" in account settings, **Then** they stop receiving promotional email starting with
   the next send cycle while continuing to receive new-product and re-engagement email.

### User Story 2 — Customer disables all marketing email (Priority: P1)

A customer who wants no marketing email at all disables every category at once.

**Acceptance Scenarios**:
1. **Given** a customer with any combination of categories enabled, **When** they disable all
   marketing categories, **Then** they stop receiving all three categories while continuing to
   receive transactional email (receipts, password resets, security notifications).

### User Story 3 — Support agent views a customer's preference state (Priority: P2)

A support agent responding to a complaint looks up whether the customer has already opted out of
the category in question.

**Acceptance Scenarios**:
1. **Given** a customer with a mix of enabled/disabled categories, **When** a support agent looks
   up that customer's preferences, **Then** the agent sees the current state of all three
   categories without filing an internal ticket.

### Edge Cases

- A preference change that lands in the same batch window as an already-queued send may not take
  effect until the following batch (REFINED from story §14 Dragon's Questions #1 — an accepted,
  bounded risk, not a defect).
- A customer who previously had a manual support-filed suppression is backfilled as
  all-marketing-disabled rather than left in an ambiguous dual state (traces to story §14 Dragon's
  Questions #3).

## Functional Requirements

- **REQ-001**: System MUST allow a customer to independently enable/disable each of the three
  marketing categories (promotions, new-product announcements, re-engagement).
- **REQ-002**: System MUST allow a customer to disable all marketing categories in a single
  action.
- **REQ-003**: A disabled category MUST take effect no later than the next scheduled send batch
  (target: within 15 minutes, matching the existing batch cadence — REFINED from story's
  "accepted, bounded risk" framing into a concrete target).
- **REQ-004**: Transactional and legal-notice email (receipts, password resets, security
  notifications) MUST NOT be affected by any marketing preference, regardless of what a customer
  selects.
- **REQ-005**: System MUST provide a support-facing read view of a customer's current preference
  state across all three categories.
- **REQ-006**: Preference-change history MUST NOT be retained longer than 30 days (CLARIFIED from
  story §12's legal constraint into a specific, testable retention rule).
- **REQ-007**: A customer with a pre-existing, manually-filed support suppression MUST be
  backfilled as all-marketing-disabled at migration time, so support does not need to track two
  separate suppression mechanisms (PRESERVED from story §14 Dragon's Questions #3).

## Success Criteria

- **SC-001**: A customer who disables a category stops receiving it within one send cycle and can
  confirm the state of all three categories at any time.
- **SC-002**: A customer who disables all marketing communications receives none of the three
  categories while transactional email is unaffected.
- **SC-003**: A support agent can view a customer's preference state without filing a ticket.
- **SC-004**: No preference-change history record persists longer than 30 days.

## Assumptions

- A simple per-customer, per-category enabled/disabled flag is sufficient; no frequency-capping or
  scheduling requirement has been identified (PRESERVED from story §13's Solution-Neutrality
  Assessment).

## Out of Scope

- SMS preferences (story §7 Adjacent Concerns — unchanged, still adjacent).
- Any bulk-resend or re-send tooling for customers who change their preferences (story §7
  Adjacent Concerns — unchanged, still adjacent; not introduced anywhere in this spec).

## Questmaster Record

### Judgment Ledger

### Comprehension

### Decisions
