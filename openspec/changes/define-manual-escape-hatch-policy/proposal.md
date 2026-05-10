## Why

Gentoo installation can require manual intervention when automation fails. The project needs a policy for manual fixes that preserves auditability and prevents unsafe resume.

## What Changes

- Define when manual intervention is allowed.
- Require operators to record manual changes before resuming.
- Require revalidation after manual intervention.
- Prevent manual changes from bypassing safety gates or confirmations.

## Capabilities

### New Capabilities
- `manual-escape-hatch`: Defines how manual interventions are recorded, validated, and resumed safely.

### Modified Capabilities

## Impact

- Install state/resume, audit bundle, final checks, docs and agents.
