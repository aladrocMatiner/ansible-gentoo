# Tasks: implement-case-specific-libvirt-vms

## 1. OpenSpec

- [x] 1.1 Create proposal, design, tasks, and spec delta for case-specific libvirt VMs.
- [x] 1.2 Validate with `openspec validate implement-case-specific-libvirt-vms --strict`.
- [x] 1.3 Validate the full project with `openspec validate --all --strict`.

## 2. Case Selection Model

- [x] 2.1 Add shared validation for `PROFILE=openrc|systemd` and `FILESYSTEM=ext4|btrfs` in the VM helper layer.
- [x] 2.2 Derive a canonical case key as `amd64-<profile>-<filesystem>`.
- [x] 2.3 Derive a case VM name as `<VM_NAME>-amd64-<profile>-<filesystem>`.
- [x] 2.4 Support optional `VM_TEST_IMAGE_NAME` in generated names as `<VM_NAME>-<VM_TEST_IMAGE_NAME>-amd64-<profile>-<filesystem>`.
- [x] 2.5 Derive case-specific qcow2, XML, OVMF vars, log, and SSH known-host artifact paths.
- [x] 2.6 Derive case-specific local install-state paths for VM validation runs.
- [x] 2.7 Validate that generated case names remain within libvirt name length and character limits.
- [x] 2.8 Validate `VM_TEST_IMAGE_NAME` as a conservative label and reject paths, shell metacharacters, and secret-like values.
- [x] 2.9 Add project ownership metadata that records optional `VM_TEST_IMAGE_NAME`, platform `amd64`, the selected profile, filesystem, and case name in generated domain XML.

## 3. Makefile Integration

- [x] 3.1 Add a read-only `vm-list-cases` or equivalent target that prints supported cases and generated artifacts.
- [x] 3.2 Update existing VM targets to select platform-aware case-specific libvirt domains from `PROFILE` and `FILESYSTEM`.
- [x] 3.3 Keep operator-facing actions behind Makefile targets.
- [x] 3.4 Do not add explicit case aliases; if added later, they must delegate to the shared case-selection logic.
- [x] 3.5 Update Makefile help text for case-specific VM selection.
- [x] 3.6 Ensure default `make vm-*` behavior maps clearly to the `amd64-openrc-ext4` case and is documented as such.

## 4. Script Integration

- [x] 4.1 Update `scripts/vm-libvirt-common.sh` to expose safe case-name and artifact-path helpers.
- [x] 4.2 Update VM create/start/SSH/discovery/cleanup scripts to use selected case artifacts.
- [x] 4.3 Preserve remote Ansible workflows when `ANSIBLE_LIVE_HOST` is explicitly provided.
- [x] 4.4 Ensure local VM discovery targets the selected case VM when no explicit SSH host is provided.
- [x] 4.5 Ensure VM targets print selected case, domain, disk, network mode, and libvirt URI before mutating artifacts or connecting.
- [x] 4.6 Ensure case VMs use unique generated MAC addresses or safe libvirt-generated MAC behavior.
- [x] 4.7 Ensure user-mode SSH forwarding uses explicit or per-case unique host ports if user-mode networking is selected.

## 5. Safety

- [x] 5.1 Reject unsupported profiles, filesystems, unsafe names, unsafe paths, parent traversal, symlink escapes, and `/dev/*` host-side disk paths.
- [x] 5.2 Require `I_UNDERSTAND_CLEANUP_DELETE=DELETE` before deleting selected case artifacts.
- [x] 5.3 Ensure cleanup deletes only validated artifacts for the selected case.
- [x] 5.4 Refuse to overwrite or redefine existing libvirt domains unless they are verified as project-owned.
- [x] 5.5 Keep destructive install confirmations unchanged for work inside the VM.
- [x] 5.6 Refuse existing domains whose project metadata conflicts with the selected image-name/amd64 profile/filesystem case.
- [x] 5.7 Ensure manual `VM_DISK` overrides cannot be reused accidentally across matrix cases.

## 6. Matrix Alignment

- [x] 6.1 Update `make vm-test-matrix-plan` output to match executable case VM naming.
- [x] 6.2 Ensure the four matrix cases are `amd64-openrc-ext4`, `amd64-openrc-btrfs`, `amd64-systemd-ext4`, and `amd64-systemd-btrfs`.
- [x] 6.3 Keep full destructive matrix execution out of scope unless a later change explicitly implements it.
- [x] 6.4 Ensure future matrix cleanup behavior, if added, lists each case artifact explicitly before deletion.

## 7. Documentation

- [x] 7.1 Update `docs/libvirt-manual-install-test.md` with case-specific VM examples.
- [x] 7.2 Update `docs/libvirt-install-test-matrix.md` with concrete case VM names and disk paths.
- [x] 7.3 Update `docs/libvirt-end-to-end-install-validation.md` with per-case examples.
- [x] 7.4 Update `docs/ansible-architecture.md` to keep libvirt case VMs isolated from reusable Ansible roles.
- [x] 7.5 Update relevant `agents/` and `skills/` files if the implementation changes their responsibilities.
- [x] 7.6 Document migration from the old generic `gentoo-ai-installer` VM name without auto-deleting old artifacts.
- [x] 7.7 Update documentation maintenance checklist if new VM state, cleanup, or ownership rules are added.
- [x] 7.8 Add per-case quickstarts under `docs/quickstarts/` and link them from `README.md`.
- [x] 7.9 After automatic case derivation is implemented, update quickstarts to remove transitional explicit variables where appropriate.
- [x] 7.10 Document `VM_TEST_IMAGE_NAME` in quickstarts, Makefile docs, matrix docs, and safety review notes.

## 8. Verification

- [x] 8.1 Run the safe case listing target and confirm all four generated names include platform, profile, and filesystem.
- [x] 8.2 Run `make vm-test-matrix-plan`.
- [x] 8.3 Run `make vm-check PROFILE=openrc FILESYSTEM=ext4` and one additional non-default case if host tools are available.
- [x] 8.4 Run `make ansible-check`.
- [x] 8.5 Run `make secret-check`.
- [x] 8.6 Run `openspec validate implement-case-specific-libvirt-vms --strict`.
- [x] 8.7 Run `openspec validate --all --strict`.
