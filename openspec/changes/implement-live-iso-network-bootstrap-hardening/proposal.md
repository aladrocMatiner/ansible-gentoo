## Why

Ansible depends on stable access to the official Gentoo live ISO environment. Network and SSH bootstrap failures should be detected early with actionable errors instead of surfacing later as vague Ansible failures.

## What Changes

- Harden live ISO network checks before Ansible handoff.
- Validate IP discovery, DNS, time, routing, SSH availability, known_hosts handling, and project sync path.
- Keep behavior Makefile-mediated.
- Distinguish explicit network live ISO targets, controller-to-VM test access, and optional local live ISO execution.
- Avoid configuring the installed target system in this change.

## Capabilities

### New Capabilities
- `live-iso-network-bootstrap`: Hardens network and SSH/bootstrap validation for the official Gentoo live ISO environment.

### Modified Capabilities

## Impact

- Existing network live ISO and VM bootstrap/Ansible ping workflows.
- Remote network Ansible control-plane proposal.
- Optional live ISO local Ansible control-plane proposal.
- Docs for troubleshooting connection issues.
