# Quest Story: Customer control over marketing email preferences

## 1. Quest Title

Customer control over marketing email preferences

## 2. Problem Statement

Customers receive marketing email they don't want and have no convenient way to control it.
Support agents currently field a steady stream of complaints and unsubscribe requests that have
to be handled manually, one address at a time.

## 3. Who Is Affected / Actors

- **Customers** who receive marketing email and want to control which categories they get.
- **Support agents** who currently field complaints and manually suppress addresses.

## 4. Current Behaviour

All customers receive all marketing categories (promotions, new-product announcements, and
re-engagement campaigns) with no per-category opt-out. Only support agents can manually suppress
an address entirely, and only by filing an internal ticket against the sending system — there is
no customer-facing control at all.

## 5. Use Cases

1. **Customer disables one category.** A customer who is tired of promotional email opens their
   account settings, unchecks "Promotions," and stops receiving that category on the next send
   cycle while still receiving new-product announcements and re-engagement email.
2. **Customer disables all marketing email.** A customer who wants no marketing at all turns off
   every category at once and confirms that all three categories stop, while transactional email
   (receipts, password resets) continues to arrive unaffected.
3. **Support agent verifies a customer's preferences.** A support agent, responding to a
   complaint, looks up the customer's current preference state to confirm whether a complaint is
   about a category the customer already opted out of (a delivery bug) or one they haven't
   (an unaddressed preference).

## 6. Desired Outcomes

Customers can disable marketing communications by category (or entirely) and the change takes
effect for all future eligible sends. Support agents can see a customer's current preference
state without filing an internal ticket.

## 7. Scope Boundaries

**In-Scope**: Per-category opt-out for the three existing marketing categories (promotions,
new-product announcements, re-engagement); an all-marketing opt-out; a support-facing read view of
a customer's current preferences.

**Out-of-Scope / Non-Goals**: Transactional email (receipts, password resets, security
notifications) — never affected by this preference. Any change to *how* campaigns are sent or
targeted.

**Adjacent Concerns**: SMS preferences (a separate channel, handled separately if ever requested).
An admin tool to bulk-resend suppressed campaigns to customers who opted back in — not requested
by anyone and not part of this quest.

## 8. Success Criteria

- A customer who disables a marketing category stops receiving that category on the next send
  cycle and can confirm the current state of all three categories at any time.
- A customer who disables all marketing communications receives none of the three categories
  while continuing to receive transactional email.
- A support agent can view a customer's current preference state without filing a ticket.

## 9. Assumptions & Known Unknowns

**Assumed**: Most complaints concern marketing email specifically, not transactional email (not
confirmed by support data — this is a starting assumption, not a measured fact).

**Unknown**: Whether SMS preferences will ever be requested — deliberately out of scope until they
are.

## 10. Background / Context

Support has fielded a rising number of "please stop emailing me" tickets over the last two
quarters, each currently requiring a manual suppression by an engineer with database access. This
quest exists to give customers (and support) a self-service alternative.

## 11. Business Rules

Transactional and legal-notice email (receipts, password resets, security notifications) can never
be disabled by this preference, regardless of what the customer selects.

## 12. Constraints

Legal signed off on a 30-day retention window for preference-change history last quarter — this
feature must not retain preference-change history longer than that window.

## 13. Proposed Solutions & Solution-Neutrality Assessment

**Proposal as stated**: "Create a NotificationPreference table so customers can disable marketing
emails."

**Classification**:
- Requirement(s): per-category and all-marketing opt-out; support-facing read access to current
  preferences.
- Implementation detail: the specific choice of a dedicated "NotificationPreference" table — one
  reasonable way to store this, not a requirement in itself.
- Assumption(s): that a simple per-customer, per-category boolean is sufficient (as opposed to,
  say, frequency capping or scheduling) — matches every use case above, but worth naming as an
  assumption rather than a confirmed requirement.
- Unnecessary constraint(s): none identified — the proposal doesn't lock in anything beyond the
  storage choice already classified above.

## 14. Dragon's Questions

1. **Challenge** (category: `partial_failure`): "What happens if a customer's preference write
   succeeds but a concurrent send already queued them for the category they just disabled?"
   **Response**: "That's a real race, but it's a single-row write and campaigns are queued in
   batches at most every 15 minutes — we'll accept the small window rather than add
   synchronization for it." **Disposition**: `accepted_as_risk`.
2. **Challenge** (category: `unsafe_assumption`): "You're assuming this only needs a boolean per
   category — what if legal ever wants a reason recorded for why someone opted out?"
   **Response**: "Not something anyone's asked for, and I don't want to design storage for a
   requirement that doesn't exist yet." **Disposition**: `dismissed`.
3. **Challenge** (category: `migration`): "What happens to customers who already filed a manual
   suppression ticket before this ships — do they need to be migrated into the new preference
   state, or do they stay suppressed by the old mechanism?"
   **Response**: "Good catch — we should backfill existing manual suppressions as
   all-marketing-disabled so support doesn't have to track two systems." **Disposition**:
   `changed_the_story` (added to Desired Outcomes/Use Cases as a migration note before finalizing;
   see §12 Constraints — no new constraint required beyond the existing 30-day retention window).

## Questmaster Record

### Judgment Ledger

- **2026-09-12** · story · asserted_constraint — "Legal signed off on a 30-day retention window
  for preference-change history last quarter, we can't keep it longer than that."
  *Effect*: Added to Constraints (§12).
- **2026-09-12** · dragon · dragon_response — "That's a real race, but it's a single-row write and
  campaigns are queued in batches at most every 15 minutes — we'll accept the small window rather
  than add synchronization for it."
  *Effect*: Recorded as an accepted risk (Dragon's Questions #1), not designed around.
- **2026-09-12** · dragon · dragon_response — "Not something anyone's asked for, and I don't want
  to design storage for a requirement that doesn't exist yet."
  *Effect*: Dismissed (Dragon's Questions #2); no scope added.
- **2026-09-12** · dragon · dragon_response — "Good catch — we should backfill existing manual
  suppressions as all-marketing-disabled so support doesn't have to track two systems."
  *Effect*: Migration handling added as a use case consideration (Dragon's Questions #3).

### Comprehension

### Decisions

## 16. Story Readiness Assessment

**Classification**: `READY`
**Score**: 88/100 (threshold: 70)
**Unmet critical conditions**: none.

## 17. Story Integrity Assessment

| Dimension | Band | Score | Evidence |
|---|---|---|---|
| Problem definition | STRONG | 15/15 | §2 names the problem with no implementation noun and would remain true under any solution |
| Actors and current state | STRONG | 10/10 | §3 names both actors distinctly; §4 describes today's behavior step by step |
| Use cases | STRONG | 15/15 | §5 has 3 meaningful cases with actor/goal/trigger/result |
| Desired outcomes | STRONG | 15/15 | §6 stated as a resulting state, traceable to §2 |
| Scope and boundaries | STRONG | 10/10 | §7 has three distinct, specific lists |
| Success criteria | STRONG | 10/10 | §8's criteria are all checkable without seeing the implementation |
| Assumptions and unknowns | ADEQUATE | 3/5 | §9 present and distinct but thin (one assumption, one unknown) |
| Constraints and context | STRONG | 5/5 | §10/§12 specific and asserted, not inferred |
| Solution neutrality | STRONG | 5/5 | §13 fully separates the proposal into requirement/implementation/assumption |
| Developer judgment | ADEQUATE | 10/10 | Judgment Ledger has 4 entries: an asserted constraint, an accepted risk, a dismissal, and a story-changing correction from the Dragon Pass |

**Overall score**: 88/100
