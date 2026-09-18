# Implementation Plan: Optional two-factor authentication at login

**Branch**: `015-two-factor-auth-plan-drift`

## Summary

Add a `totp_secret` column to the existing account table, and check it in the existing login flow. Additionally stand up a new standalone "auth-gateway" microservice that proxies ALL login traffic (2FA and non-2FA alike) through a new service boundary, for "future flexibility."

## Architecture

1. **TOTP field + login-flow check**: existing login flow reads totp_secret and prompts for a code when set — directly serves REQ-001/REQ-002.
2. **auth-gateway microservice (NEW)**: proxies ALL login traffic, including customers with no 2FA enabled, through a new standalone service, for "future flexibility."
