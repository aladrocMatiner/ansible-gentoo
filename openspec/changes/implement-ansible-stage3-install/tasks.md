# Tasks: implement-ansible-stage3-install

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate implement-ansible-stage3-install --strict`.

## Implementation
- [x] Apply Ansible quality standards: FQCN, named tasks, module-first behavior, guarded command-like tasks, idempotency, check/diff behavior, and secret handling.
- [x] Run `make ansible-check` and record syntax/lint result.
- [x] Add Makefile target(s).
- [x] Add shared `common/stage3`.
- [x] Implement OpenRC/systemd stage3 variant variables.
- [x] Map `PROFILE=openrc` to the official amd64 OpenRC stage3 variant.
- [x] Map `PROFILE=systemd` to the official amd64 systemd stage3 variant.
- [x] Prefer official stage3 metadata for variant and checksum selection where practical.
- [x] Implement the approved stage3 signature policy.
- [x] Implement the approved download cache and mirror policy.
- [x] Verify checksums before extraction.
- [x] Verify signatures where official metadata/tooling are available or fail with the approved policy.
- [x] Extract into verified `/mnt/gentoo`.
- [x] Record verification evidence in logs/audit output.
- [x] Update docs and skills.
- [x] Validate in VM.
