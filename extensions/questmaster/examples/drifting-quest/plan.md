# Implementation Plan: Customer control over marketing email preferences (drifting-quest fixture)

<!-- Judgment-tier fixture. Introduces an untraceable component (a new "preference-sync-service")
     and DROPS story §12's 30-day retention constraint entirely, even though spec.md (REQ-004)
     carried it forward -- this is exactly the constraint_preservation failure mode data-model.md
     calls out as distinct from specification_coverage. Everything else stays proportionate so
     the fixture isolates these two findings rather than drowning them in unrelated noise. -->

**Branch**: `002-marketing-email-preferences-drift-fixture` | **Date**: 2026-09-14

## Summary

Add a `preference` boolean field per customer per marketing category to the existing customer
data store, exposed via a new internal API for the account-settings UI and the support tooling to
read/write. A new **preference-sync-service** publishes every preference change to three
downstream systems (the campaign sender, the analytics warehouse, and a partner data-sharing
feed) so each can independently decide whether to honor it.

## Technical Context

**Language/Version**: matches the existing account-service stack.
**Storage**: a new `customer_marketing_preference` table (customer_id, category, enabled).
**Testing**: unit tests for the preference read/write API; integration test for the sync service
publishing to all three downstream systems.

## Architecture

1. **Preference API** (in the existing account-service): `GET`/`PUT`
   `/customers/{id}/marketing-preferences`, backing Use Cases 1-2 from the story and REQ-001/
   REQ-002/REQ-010/REQ-011 from spec.md.
2. **Preference-sync-service** (NEW, standalone microservice): subscribes to preference-change
   events and pushes the current state to the campaign sender, the analytics warehouse, and a
   partner data-sharing feed, so each downstream consumer always has an up-to-date copy without
   querying the account-service directly.
3. **Support read view**: a thin read-only endpoint reusing the Preference API's `GET`, surfaced
   in the existing support console.

## Risk Management

- The batch-send race Dragon's Questions #1 accepted (story) is mitigated by keeping the campaign
  sender's batch window at 15 minutes, unchanged.

## Test Strategy

Unit tests for the Preference API; an integration test asserting the sync service delivers a
preference change to all three downstream systems within one polling interval.
