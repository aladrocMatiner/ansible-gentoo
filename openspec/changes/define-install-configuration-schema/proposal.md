## Why

Installer variables are currently documented across several agents, skills, docs, Makefile targets, and OpenSpec changes. Before destructive workflows grow, the project needs one authoritative configuration schema so Makefile variables and Ansible variables have consistent names, defaults, allowed values, and safety behavior.

## What Changes

- Define the canonical installer configuration schema.
- Document variable types, allowed values, defaults, and no-default rules.
- Map Makefile variables to Ansible variables.
- Define unsupported combinations and fail-closed behavior.
- Require future targets and roles to consume the schema instead of inventing new variable names.

## Capabilities

### New Capabilities
- `install-configuration-schema`: Defines the canonical operator/Ansible variable contract for installer workflows.

### Modified Capabilities

## Impact

- Future Makefile targets and help output.
- Future Ansible group vars, role defaults, and validation tasks.
- Config validation report.
- Docs and skills that describe variables.
