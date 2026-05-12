# Tasks: extend-libvirt-matrix-stage3-flavors

## OpenSpec
- [x] Create proposal/design/tasks/spec.
- [x] Validate with `openspec validate extend-libvirt-matrix-stage3-flavors --strict`.
- [x] Validate with `openspec validate --all --strict`.

## Implementation
- [x] Add and export `STAGE3_FLAVOR ?= standard`.
- [x] Add configuration validation for `STAGE3_FLAVOR`.
- [x] Extend libvirt case naming, metadata, disk/state paths, and SSH port selection.
- [x] Extend matrix planning to all 12 cases.
- [x] Extend E2E matrix execution to all 12 cases.
- [x] Pass `stage3_flavor` through relevant Ansible wrapper scripts.
- [x] Update stage3 role to select standard, hardened, and musl official autobuilds.
- [x] Update Portage role to select matching standard, hardened, and musl profiles.
- [x] Update final checks to validate the Portage profile matching `PROFILE` and `STAGE3_FLAVOR`.
- [x] Record `stage3_flavor` in install plans, install state, and matrix evidence.
- [x] Update resume safety checks to compare recorded `stage3_flavor`.
- [x] Preserve existing standard case names.
- [x] Add docs for the extended matrix and selector.
- [x] Add or update quick starts for hardened and musl cases.
- [x] Update agents and skills for the stage3 flavor selector.
- [x] Run syntax/config checks for updated scripts and playbooks.
- [x] Review for safety and stale documentation.
