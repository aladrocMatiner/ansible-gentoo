## Why

The live ISO preflight checks system time, but the installed Gentoo system also needs a documented time synchronization policy after reboot. Without this, OpenRC and systemd variants may choose different tools or skip time sync entirely.

## What Changes

- Define the installed-system time synchronization policy for v1.
- Keep OpenRC and systemd differences explicit.
- Require final checks and install report output to include time-sync status.
- Require package/service work to install and enable the selected time-sync mechanism.

## Capabilities

### New Capabilities
- `installed-time-sync`: Defines installed target time synchronization requirements for OpenRC and systemd.

### Modified Capabilities

## Impact

- Target system baseline.
- Package/service installation.
- Final checks.
- Install report summary.
- Docs and skills.
