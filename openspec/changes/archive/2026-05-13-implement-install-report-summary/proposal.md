## Why

The audit bundle is technical. Operators also need a concise human-readable summary after an install or validation run that explains what was installed, where, and what to do next.

## What Changes

- Add an install report summary generated from state, audit, and final checks.
- Summarize selected profile, filesystem, stage3 flavor, disk, partitions, UUIDs, hostname, users, network, time sync, SSH when enabled, Portage update/config status, bootloader, boot command line status, and validation status.
- Summarize available evidence against the target system baseline.
- Include next steps after reboot and what was intentionally not automated.
- Keep secrets out of the report.

## Capabilities

### New Capabilities
- `install-report-summary`: Produces a concise human-readable install summary for completed or failed runs.

### Modified Capabilities

## Impact

- Final checks, audit bundle, release readiness, docs.
- Future Makefile target such as `make install-report`.
