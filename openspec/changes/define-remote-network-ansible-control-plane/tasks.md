# Tasks: define-remote-network-ansible-control-plane

## OpenSpec
- [x] Create proposal.
- [x] Create design.
- [x] Create tasks.
- [x] Create spec delta.
- [x] Validate this change with `openspec validate define-remote-network-ansible-control-plane --strict`.
- [x] Validate all changes with `openspec validate --all --strict`.

## Documentation
- [x] Update `AGENTS.md`.
- [x] Update `README.md`.
- [x] Update `docs/ansible-architecture.md`.
- [x] Update live ISO and planning docs.
- [x] Update Ansible agent and skill docs.
- [x] Update Makefile control plane skill.
- [x] Update existing architecture and roadmap OpenSpec language.

## Implementation Boundary
- [x] Add Makefile variables for explicit live ISO SSH target selection.
- [x] Allow Ansible wrapper target discovery through `ANSIBLE_LIVE_HOST` before falling back to local libvirt VM discovery.
- [x] Keep all current Ansible planning workflows read-only.
- [x] Preserve no-default-disk behavior.
