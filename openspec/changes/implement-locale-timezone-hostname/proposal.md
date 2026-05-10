## Why

Hostname, timezone, locale, and keymap are core Handbook system-configuration steps and should be implemented as a shared role instead of being hidden inside Portage or package installation.

## What Changes

- Add a shared target system configuration role for hostname, timezone, locale, and keymap.
- Validate configuration variables through the install configuration schema.
- Keep OpenRC/systemd differences explicit only where file/service behavior differs.
- Add final checks and install report evidence for these settings.

## Capabilities

### New Capabilities
- `locale-timezone-hostname`: Configures target hostname, timezone, locale, and keymap through a shared workflow.

### Modified Capabilities

## Impact

- Ansible roles and playbooks.
- Target system baseline and final checks.
- Docs and skills.
