# Quest Story: Optional two-factor authentication at login

## Quest Title

Optional two-factor authentication at login

## Problem Statement

Accounts can be taken over with a stolen password alone, with no second factor available.

## Who Is Affected / Actors

Customers who want stronger account protection.

## Current Behaviour

Login requires only a password; no second factor exists.

## Use Cases

1. Customer enables 2FA and is prompted for a code from their authenticator app on next login.
2. Customer without 2FA enabled logs in with just a password, unaffected.

## Desired Outcomes

Customers can opt into a second authentication factor at login.

## Scope Boundaries

**In-Scope**: TOTP-based second factor, opt-in per account.
**Out-of-Scope**: mandatory 2FA for all accounts; SMS-based codes.
**Adjacent Concerns**: hardware security keys — not requested.

## Success Criteria

A customer with 2FA enabled cannot complete login with password alone; a customer without it is unaffected.

## Assumptions & Known Unknowns

**Assumed**: nothing beyond what's stated above.
**Unknown**: nothing material identified.

## Questmaster Record

### Judgment Ledger

### Comprehension

### Decisions
