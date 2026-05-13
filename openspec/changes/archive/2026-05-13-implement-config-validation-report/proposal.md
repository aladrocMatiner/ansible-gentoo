## Why

Operators need a fast read-only check that validates the entire intended configuration before any plan or apply workflow. This prevents confusing failures later in Ansible and reduces the chance of running destructive targets with invalid assumptions.

## What Changes

- Add a Makefile-mediated configuration validation report.
- Validate variables against the install configuration schema.
- Check unsupported combinations, missing required variables, unsafe paths, and misplaced secrets.
- Print actionable errors using the shared error taxonomy.
- Remain read-only.

## Capabilities

### New Capabilities
- `config-validation-report`: Produces a read-only operator report that validates installer configuration before plan/apply workflows.

### Modified Capabilities

## Impact

- Future `make config-check` or equivalent target.
- Makefile and Ansible variable validation.
- Secret input policy and logging/error taxonomy.
- Docs and skills.
