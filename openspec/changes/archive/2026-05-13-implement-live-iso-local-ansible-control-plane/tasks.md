# Tasks: implement-live-iso-local-ansible-control-plane

## OpenSpec
- [x] Create proposal.
- [x] Create design.
- [x] Create tasks.
- [x] Create spec delta.
- [x] Validate this change with `openspec validate implement-live-iso-local-ansible-control-plane --strict`.

## Implementation
- [x] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [x] Run `make ansible-check` and record syntax/lint result.
- [x] Add `ansible/inventory/local.yml`.
- [x] Add Makefile targets or execution-mode selection for optional local live ISO Ansible.
- [x] Integrate live ISO network/bootstrap hardening checks.
- [x] Integrate supported host requirements for host-driven validation mode.
- [x] Reuse existing playbooks where possible.
- [x] Ensure `INSTALL_DISK` still has no default.
- [x] Update docs and skills.
- [x] Ensure docs keep network Ansible as the primary product path and label local execution as fallback or diagnostics.
- [x] Run local syntax validation.
