## Why

After stage3 extraction, the installer must decide whether to sync Portage, update `@world`, and handle config file updates. This policy prevents the first installer from becoming an unbounded system upgrade while still keeping the target coherent.

## What Changes

- Define v1 policy for `emerge --sync`.
- Define whether `emerge -avuDN @world` runs in v1.
- Define handling for `etc-update`/`dispatch-conf` equivalent behavior.
- Define failure behavior for pending config updates.
- Require logs/audit evidence for Portage operations.

## Capabilities

### New Capabilities
- `portage-world-update`: Defines Portage sync, world update, and config file update policy.

### Modified Capabilities

## Impact

- Portage baseline.
- Package installation.
- Final checks.
- Audit bundle.
- Docs and skills.
