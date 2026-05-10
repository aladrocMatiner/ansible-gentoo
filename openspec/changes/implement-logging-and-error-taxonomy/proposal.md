## Why

Makefile targets, scripts, and Ansible roles should fail consistently. A shared logging and error taxonomy makes failures actionable and makes audit bundles easier to interpret.

## What Changes

- Define common error codes/categories.
- Standardize log locations and run ids.
- Require clear operator-facing error messages.
- Require scripts and Ansible wrappers to use the taxonomy where practical.
- Keep logs secret-safe.

## Capabilities

### New Capabilities
- `logging-error-taxonomy`: Defines shared logging paths, run ids, and error categories for installer workflows.

### Modified Capabilities

## Impact

- Makefile wrappers, scripts, Ansible roles.
- Install state, audit bundle, config validation, final checks.
- Docs and skills.
