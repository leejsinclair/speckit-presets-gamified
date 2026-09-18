# Feature Specification: Customer control over marketing email preferences (drifting-quest fixture)

<!-- Judgment-tier fixture. Introduces TWO unsupported additions relative to story.md:
     REQ-010 (admin bulk-resend tool) has NO matching Decision -> expected UNJUSTIFIED_DRIFT.
     REQ-011 (re-engagement win-back nudge) DOES have a matching Decision below -> expected
     ACCEPTED_SCOPE_CHANGE. Everything else mirrors examples/faithful-quest/spec.md's fidelity
     to the story, so this fixture isolates drift classification rather than re-testing every
     other dimension from scratch. -->

**Feature Branch**: `002-marketing-email-preferences-drift-fixture`
**Created**: 2026-09-13
**Status**: Draft

## User Scenarios & Testing

### User Story 1 — Customer disables one marketing category (Priority: P1)

**Acceptance Scenarios**:
1. **Given** a customer with all three marketing categories enabled, **When** they disable
   "Promotions," **Then** they stop receiving that category on the next send cycle.

### User Story 2 — Customer disables all marketing email (Priority: P1)

**Acceptance Scenarios**:
1. **Given** a customer with any categories enabled, **When** they disable all marketing
   categories, **Then** they stop receiving all three while transactional email is unaffected.

## Functional Requirements

- **REQ-001**: System MUST allow a customer to independently enable/disable each of the three
  marketing categories. (PRESERVED — direct carry-over of story §5/§6.)
- **REQ-002**: System MUST allow a customer to disable all marketing categories at once.
  (PRESERVED — direct carry-over of story §6/§8.)
- **REQ-003**: Transactional and legal-notice email MUST NOT be affected by any marketing
  preference. (PRESERVED — direct carry-over of story §11.)
- **REQ-004**: Preference-change history MUST NOT be retained longer than 30 days. (CLARIFIED —
  story §12's constraint made into a specific, testable rule.)
- **REQ-010**: System MUST provide an internal admin tool allowing support or marketing staff to
  bulk re-send a suppressed marketing campaign to customers who have since re-enabled that
  category. *(No story antecedent: story §7 explicitly lists "any administrative tooling for
  support or marketing to resend, override, or bulk-manage customer preferences on their behalf"
  as Out-of-Scope, and §14's Dragon Pass response explicitly rejected letting anyone override a
  customer's own preference. Expected classification: UNJUSTIFIED_DRIFT — no story antecedent, no
  Decision recorded below.)*
- **REQ-011**: System MUST allow the marketing team to send a single opt-in "we miss you" nudge
  email to customers who disabled the re-engagement category more than 90 days ago, inviting them
  to reconsider — this nudge is itself subject to the same preference system (a customer who
  disables it entirely will not receive it). *(No story antecedent either, but see this
  document's own Questmaster Record → Decisions below: the developer explicitly accepted this as
  a deliberate, scoped widening rather than an oversight. Expected classification:
  ACCEPTED_SCOPE_CHANGE.)*

## Success Criteria

- **SC-001**: A customer who disables a category stops receiving it within one send cycle.
- **SC-002**: A customer who disables all marketing communications receives none of the three
  categories while transactional email is unaffected.
- **SC-003**: No preference-change history record persists longer than 30 days.

## Out of Scope

- SMS preferences (story §7 Adjacent Concerns — unchanged).

## Questmaster Record

### Judgment Ledger

### Comprehension

### Decisions

- **2026-09-13** — Specification Integrity review flagged REQ-011 (the re-engagement win-back
  nudge) as scope not present in story.md. Developer chose to accept it as a deliberate widening.
  Their reason: *"Marketing asked for this in the same planning thread as the original request —
  I'm deliberately widening the quest to include it rather than opening a second one, since it
  reuses the exact same preference mechanism."* → Reclassify REQ-011 as `ACCEPTED_SCOPE_CHANGE`
  on the next Specification Integrity run. **Status: outstanding.**
  <!-- qm-record:decision status=outstanding resolved_by=- resolved_date=- -->
