## Why

Real hardware installation can destroy data. The project needs a hard readiness policy before docs or agents encourage running destructive targets outside libvirt.

## What Changes

- Define prerequisites for real hardware use.
- Require libvirt validation first where possible.
- Require explicit disk identity through stable paths such as `/dev/disk/by-id`.
- Require backups, UEFI confirmation, power/network readiness, and manual review checklist.
- Keep hardware guidance behind Makefile targets and safety confirmations.

## Capabilities

### New Capabilities
- `real-hardware-readiness`: Defines prerequisites and safety checks before running installer workflows on physical machines.

### Modified Capabilities

## Impact

- Safety docs, final release docs, agents, skills.
- Destructive safety gates and config validation report.
