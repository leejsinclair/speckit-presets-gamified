# Feature Specification: Export order history as CSV

**Feature Branch**: `013-csv-export-scheduled`

## Functional Requirements

- **REQ-001**: System MUST let a customer download their order history as a CSV file.
- **REQ-002**: System MUST let a customer schedule a recurring monthly email delivery of their order-history CSV.

## Questmaster Record

### Judgment Ledger

### Comprehension

### Decisions

- **2026-09-13** — Specification Integrity review flagged REQ-002 (scheduled monthly export) as scope not present in story.md. Developer chose to accept it. Their reason: *"Support asked for this in the same ticket thread; it reuses the exact same export logic so I'm folding it in rather than opening a second quest."* → Reclassify REQ-002 as `ACCEPTED_SCOPE_CHANGE` on the next run. **Status: outstanding.**
  <!-- qm-record:decision status=outstanding resolved_by=- resolved_date=- -->
