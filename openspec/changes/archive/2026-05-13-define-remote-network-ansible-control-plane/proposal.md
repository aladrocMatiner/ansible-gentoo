# Change: define-remote-network-ansible-control-plane

## Summary
Define the primary phase-2 Ansible execution model for `gentoo-ai-installer`: a reusable Ansible installer run from an operator/controller machine against a network-reachable target booted into the official Gentoo live ISO.

libvirt/virsh, VM disks, SSH bootstrap helpers, and local artifact directories remain local validation infrastructure. They must not become required production installer assumptions.

## Motivation
The project has grown useful local VM workflows for testing manual installation steps and read-only Ansible plans. Those workflows are valuable, but the final deliverable should be usable by other operators against real network targets, not only against the developer's libvirt VM.

The project needs an explicit OpenSpec rule that keeps future playbooks, roles, variables, inventories, Makefile targets, docs, and safety reviews centered on reusable Ansible.

## Problem Statement
Existing docs and proposals mix several execution models:

- host-to-libvirt-VM SSH for local validation,
- optional local execution from inside the live ISO,
- future reusable Ansible installer behavior.

Without a clear priority, future Ansible roles may accidentally depend on VM-only details such as libvirt domain names, local qcow2 paths, VM IP discovery, or `/dev/vda`. That would make the installer harder for other users to run on physical hosts or remote VMs.

## Scope
- Define the controller-to-target Ansible model.
- Define Makefile variables for explicit live ISO target selection.
- Keep libvirt as the local validation harness.
- Keep optional local live ISO execution as fallback or diagnostics only.
- Require reusable Ansible roles to remain inventory-driven.
- Update docs, agents, skills, and existing OpenSpec planning language to reflect the priority.

## Non-goals
- Do not implement destructive installer roles.
- Do not remove the libvirt workflow.
- Do not remove VM-based validation.
- Do not require a custom ISO.
- Do not define full SSH hardening, secret input, or real-hardware readiness here; those remain separate changes.

## Safety Considerations
- Network target support must not introduce a default install disk.
- `ANSIBLE_LIVE_HOST` must not default to a VM IP or physical host.
- `/dev/vda` is allowed only as an explicit VM guest disk example, never as a general default.
- Live ISO SSH host-key exceptions must remain scoped to official live ISO wrapper invocations.
- Destructive Ansible targets must still require explicit disk selection and confirmation.
- libvirt harness paths under `./var/libvirt/` must never be used by reusable roles.

## Acceptance Criteria
- The project docs state that reusable network Ansible is the primary phase-2 deliverable.
- `AGENTS.md` states that libvirt is a local validation harness.
- Ansible agent and skill docs describe the controller-to-live-ISO target model.
- Makefile docs describe `ANSIBLE_LIVE_HOST`, `ANSIBLE_LIVE_PORT`, and `ANSIBLE_LIVE_USER`.
- Existing architecture OpenSpec docs do not present local live ISO execution as the primary product path.
- OpenSpec validation passes for this change.
- `openspec validate --all --strict` passes.

## Affected Files
- `AGENTS.md`
- `README.md`
- `Makefile`
- `scripts/vm-libvirt-common.sh`
- `docs/ansible-architecture.md`
- `docs/ansible-live-preflight.md`
- `docs/ansible-install-plan.md`
- `docs/ansible-partition-plan.md`
- `docs/ansible-mount-plan.md`
- `docs/ansible-filesystem-plan.md`
- `docs/project-completion-roadmap.md`
- `agents/ansible-installer-agent.md`
- `agents/safety-review-agent.md`
- `skills/ansible-gentoo-installer.md`
- `skills/makefile-control-plane.md`
- Existing OpenSpec planning changes that mention local Ansible or VM-only execution
