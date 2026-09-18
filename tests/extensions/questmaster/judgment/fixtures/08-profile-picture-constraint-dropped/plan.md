# Implementation Plan: Upload a profile picture

**Branch**: `017-profile-picture-plan-drops-constraint`

## Summary

Add an avatar upload endpoint that stores the image and updates the account's avatar reference. No file-size validation is mentioned anywhere in this plan.

## Architecture

1. **Avatar upload endpoint**: accepts an image upload and stores it, updating the account's avatar reference.
