## Summary

Extend the libvirt validation matrix to cover Gentoo `standard`, `hardened`, and `musl` stage3 flavors across the existing OpenRC/systemd and ext4/Btrfs combinations.

## Motivation

The project already validates the standard amd64 OpenRC/systemd console installs with ext4 and Btrfs. Gentoo also publishes hardened and musl stage3 variants for both OpenRC and systemd. Supporting these variants in the planning and VM validation matrix gives the installer a broader compatibility target before real hardware use.

## Problem Statement

Current VM names, stage3 selection, Portage profile selection, SSH port assignments, matrix planners, and documentation only model `PROFILE` and `FILESYSTEM`. Adding hardened or musl cases ad hoc would either duplicate scripts or overload `PROFILE`, making stage3 flavor and init system ambiguous.

## Scope

- Add a `STAGE3_FLAVOR` selection with allowed values `standard`, `hardened`, and `musl`.
- Keep `PROFILE=openrc|systemd` as the init-system selector.
- Keep `FILESYSTEM=ext4|btrfs` as the filesystem selector.
- Extend the libvirt matrix to 12 cases: 2 init systems x 2 filesystems x 3 stage3 flavors.
- Preserve existing standard VM names such as `gentoo-test-amd64-openrc-ext4`.
- Name non-standard VMs with the flavor suffix, for example `gentoo-test-amd64-openrc-btrfs-hardened`.
- Select official Gentoo stage3 index files for each supported flavor/profile pair.
- Select matching Gentoo Portage profiles for standard, hardened, and musl installs.
- Update Makefile help, configuration validation, docs, skills, and OpenSpec tasks.

## Non-goals

- Do not add desktop, LLVM, SELinux, no-multilib, split-usr, or other stage3 variants.
- Do not change the root project name from `gentoo-test`.
- Do not build custom ISOs.
- Do not bypass shared Ansible roles or duplicate OpenRC/systemd logic.
- Do not relax destructive safety gates.
- Do not require running all 12 E2E installs as part of normal local development.

## Safety Considerations

- Matrix installs remain confined to disposable libvirt qcow2 disks under the project VM artifact directory.
- `INSTALL_DISK` remains unset by default and the matrix continues to use `/dev/vda` only inside the guest VM.
- Stage3 flavor must not change disk safety, partitioning, formatting, mounting, bootloader, user, SSH, or final-check gates.
- VM cleanup must still only remove generated artifacts for the selected case.
- Hardened and musl are install variants, not permission to run host commands with elevated privileges.

## Acceptance Criteria

- `STAGE3_FLAVOR ?= standard` is available through the Makefile and exported to scripts/Ansible.
- `config-check` validates `PROFILE`, `FILESYSTEM`, and `STAGE3_FLAVOR`.
- Stage3 install selects official Gentoo latest-stage3 files for `standard`, `hardened`, and `musl` flavors with OpenRC/systemd.
- Portage profile selection matches `PROFILE` and `STAGE3_FLAVOR`.
- Standard matrix VM names remain unchanged.
- Non-standard matrix VM names append `-hardened` or `-musl`.
- `make vm-list-cases`, `make vm-test-matrix-plan`, `make vm-e2e-plan`, and `make vm-e2e-matrix` include all 12 supported cases.
- The matrix assigns unique SSH host ports to all 12 cases.
- Documentation explains `STAGE3_FLAVOR`, the 12-case matrix, and the naming/port conventions.
- OpenSpec validates with `openspec validate extend-libvirt-matrix-stage3-flavors --strict`.
- `openspec validate --all --strict` passes.

## Affected Files

- `Makefile`
- `config/install-schema.yml`
- `scripts/config-check.sh`
- `scripts/vm-libvirt-common.sh`
- `scripts/vm-list-cases.sh`
- `scripts/vm-test-matrix-plan.py`
- `scripts/vm-e2e-plan.py`
- `scripts/vm-e2e-matrix.py`
- `scripts/ansible-*.sh` wrappers that pass profile/filesystem/stage3 flavor to Ansible
- `ansible/group_vars/*.yml`
- `ansible/playbooks/*.yml`
- `ansible/roles/common/stage3/`
- `ansible/roles/common/portage/`
- install state/report roles and scripts where case identity is recorded
- `docs/`
- `skills/`
- `agents/`
- `openspec/changes/*`
