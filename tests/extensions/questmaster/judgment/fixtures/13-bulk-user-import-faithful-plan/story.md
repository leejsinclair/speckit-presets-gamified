# Quest Story: Bulk user import via CSV

## Quest Title

Bulk user import via CSV

## Problem Statement

Admins adding many users must create each account manually, one at a time.

## Who Is Affected / Actors

Admins provisioning accounts for a new team or organization.

## Current Behaviour

Account creation is a one-at-a-time form with no bulk option.

## Use Cases

1. Admin uploads a CSV of new users and each row becomes an account.
2. Admin sees which rows failed (e.g. duplicate email) and why.

## Desired Outcomes

Admins can create many accounts at once from a CSV file.

## Scope Boundaries

**In-Scope**: CSV upload, per-row success/failure reporting.
**Out-of-Scope**: importing from formats other than CSV.
**Adjacent Concerns**: importing existing users' historical data — not requested.

## Success Criteria

Uploading a valid CSV creates one account per row and reports any row that failed, with a reason.

## Assumptions & Known Unknowns

**Assumed**: nothing beyond what's stated above.
**Unknown**: nothing material identified.

## Questmaster Record

### Judgment Ledger

### Comprehension

### Decisions
