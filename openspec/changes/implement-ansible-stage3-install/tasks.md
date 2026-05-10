# Tasks: implement-ansible-stage3-install

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [ ] Validate with `openspec validate implement-ansible-stage3-install --strict`.

## Implementation
- [ ] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [ ] Run `make ansible-check` and record syntax/lint result.
- [ ] Add Makefile target(s).
- [ ] Add shared `common/stage3`.
- [ ] Implement OpenRC/systemd stage3 variant variables.
- [ ] Map `PROFILE=openrc` to the official amd64 OpenRC stage3 variant.
- [ ] Map `PROFILE=systemd` to the official amd64 systemd stage3 variant.
- [ ] Prefer official stage3 metadata for variant and checksum selection where practical.
- [ ] Implement the approved stage3 signature policy.
- [ ] Implement the approved download cache and mirror policy.
- [ ] Verify checksums before extraction.
- [ ] Verify signatures where official metadata/tooling are available or fail with the approved policy.
- [ ] Extract into verified `/mnt/gentoo`.
- [ ] Record verification evidence in logs/audit output.
- [ ] Update docs and skills.
- [ ] Validate in VM.
