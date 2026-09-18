# Implementation Plan: Bulk user import via CSV

**Branch**: `022-bulk-user-import`

## Summary

Add a CSV upload endpoint that parses each row, creates an account, and collects a per-row result list to return to the admin.

## Architecture

1. **CSV upload + per-row account creation**: parses the uploaded CSV and creates one account per valid row — directly serves REQ-001.
2. **Per-row result reporting**: collects and returns a success/failure reason per row — directly serves REQ-002.
