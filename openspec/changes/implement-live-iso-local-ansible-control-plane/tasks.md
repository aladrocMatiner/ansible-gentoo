# Tasks: implement-live-iso-local-ansible-control-plane

## OpenSpec
- [x] Create proposal.
- [x] Create design.
- [x] Create tasks.
- [x] Create spec delta.
- [ ] Validate this change with `openspec validate implement-live-iso-local-ansible-control-plane --strict`.

## Implementation
- [ ] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [ ] Run `make ansible-check` and record syntax/lint result.
- [ ] Add `ansible/inventory/local.yml`.
- [ ] Add Makefile targets or execution-mode selection for optional local live ISO Ansible.
- [ ] Integrate live ISO network/bootstrap hardening checks.
- [ ] Integrate supported host requirements for host-driven validation mode.
- [ ] Reuse existing playbooks where possible.
- [ ] Ensure `INSTALL_DISK` still has no default.
- [ ] Update docs and skills.
- [ ] Ensure docs keep network Ansible as the primary product path and label local execution as fallback or diagnostics.
- [ ] Run local syntax validation.
