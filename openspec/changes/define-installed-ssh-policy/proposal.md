## Why

SSH is optional but important for validation and post-install management. The project needs a clear installed-system SSH policy before users/access and service enablement are implemented.

## What Changes

- Define whether OpenSSH is installed and enabled by default.
- Define `ENABLE_SSH` behavior.
- Forbid passwordless root SSH by default.
- Require authorized keys to come from secret-safe channels.
- Require final checks and install report output when SSH is enabled.

## Capabilities

### New Capabilities
- `installed-ssh-policy`: Defines installed target SSH package, service, authentication, and validation behavior.

### Modified Capabilities

## Impact

- Users/access.
- Package/service installation.
- Secret input policy.
- Final checks.
- First-boot validation.
- Docs and skills.
