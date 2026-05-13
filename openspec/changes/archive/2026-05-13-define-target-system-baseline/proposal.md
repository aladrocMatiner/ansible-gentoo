## Why

"Basic console install" needs a precise definition. Without a baseline, package/service/user/locale work can drift and different proposals may imply different final systems.

## What Changes

- Define the v1 target system baseline for OpenRC and systemd.
- Include installed time sync and installed SSH policy references.
- Identify required packages, services, files, and optional features.
- Separate shared baseline from init-specific choices.
- Define what is explicitly out of scope for the first usable milestone.

## Capabilities

### New Capabilities
- `target-system-baseline`: Defines the final installed Gentoo basic-console system contract.

### Modified Capabilities

## Impact

- Portage, packages/services, users/access, locale/timezone/hostname, final checks, install report, release docs.
- Ansible architecture and skills.
