# Design: implement-case-specific-libvirt-vms

## Context

The current project distinguishes reusable Ansible execution over SSH from the local libvirt validation harness. The v1 platform is `amd64`, and the install matrix identifies amd64 cases from init profile, filesystem, and stage3 flavor:

| Case | Platform | Profile | Filesystem | Stage3 flavor |
| --- | --- | --- | --- | --- |
| `amd64-openrc-ext4` | `amd64` | `openrc` | `ext4` | `standard` |
| `amd64-openrc-btrfs` | `amd64` | `openrc` | `btrfs` | `standard` |
| `amd64-systemd-ext4` | `amd64` | `systemd` | `ext4` | `standard` |
| `amd64-systemd-btrfs` | `amd64` | `systemd` | `btrfs` | `standard` |
| `amd64-openrc-ext4-hardened` | `amd64` | `openrc` | `ext4` | `hardened` |
| `amd64-openrc-btrfs-hardened` | `amd64` | `openrc` | `btrfs` | `hardened` |
| `amd64-systemd-ext4-hardened` | `amd64` | `systemd` | `ext4` | `hardened` |
| `amd64-systemd-btrfs-hardened` | `amd64` | `systemd` | `btrfs` | `hardened` |
| `amd64-openrc-ext4-musl` | `amd64` | `openrc` | `ext4` | `musl` |
| `amd64-openrc-btrfs-musl` | `amd64` | `openrc` | `btrfs` | `musl` |
| `amd64-systemd-ext4-musl` | `amd64` | `systemd` | `ext4` | `musl` |
| `amd64-systemd-btrfs-musl` | `amd64` | `systemd` | `btrfs` | `musl` |

Today the matrix planner can name entries, but executable VM operations still center on a generic configured VM unless overridden manually. This change defines a project rule and implementation plan for case-specific libvirt domains and artifacts.

The final installer remains Ansible over SSH for network-reachable official Gentoo live ISO targets. Case-specific libvirt VMs are disposable local validation objects only.

## Goals / Non-Goals

**Goals:**

- Provide one stable libvirt domain identity per supported case.
- Include `amd64`, `openrc` or `systemd`, and `ext4` or `btrfs` in every case VM name.
- Allow an optional conservative manual test image label to distinguish separate manually tested images or test lines.
- Derive project-local qcow2 disks, per-VM OVMF variables, XML, logs, SSH known-host files, and audit references from the case identity.
- Derive local VM install-state paths from the case identity so test runs do not share one mutable state pointer by accident.
- Expose case selection through Makefile variables and targets.
- Keep all VM artifacts under approved project-local directories such as `./var/libvirt/` and `./logs/`.
- Keep VM case behavior out of reusable Ansible roles.
- Keep remote/network Ansible workflows independent of libvirt and VM names.

**Non-Goals:**

- Do not implement new Ansible installer roles in this change.
- Do not automate the full Gentoo installation beyond existing approved targets.
- Do not add custom ISO generation.
- Do not make libvirt required for remote or physical installs.
- Do not introduce a default `INSTALL_DISK` for real targets.
- Do not run destructive full-matrix installs without the existing destructive confirmations.

## Decisions

### Case Identity

Use a canonical case key:

```text
amd64-<profile>-<filesystem>
```

Allowed case keys:

- `amd64-openrc-ext4`
- `amd64-openrc-btrfs`
- `amd64-systemd-ext4`
- `amd64-systemd-btrfs`

The case key is derived only from the fixed v1 platform `amd64` plus validated `PROFILE` and `FILESYSTEM` values. The implementation must reject any profile or filesystem outside the approved set. Future support for another platform must be introduced by a separate OpenSpec change before it appears in VM naming.

Do not add a second primary selector unless implementation proves it reduces ambiguity. `PROFILE` and `FILESYSTEM` are already used by Ansible and should remain the source of truth. If a future `VM_CASE` convenience variable is added, it must expand to the same two values and must fail when it conflicts with explicit `PROFILE` or `FILESYSTEM`.

### Domain Naming

Use a base VM name plus the platform-aware case key:

```text
<VM_NAME>-amd64-<profile>-<filesystem>
```

If the operator sets `VM_TEST_IMAGE_NAME`, insert it between the base name and platform:

```text
<VM_NAME>-<VM_TEST_IMAGE_NAME>-amd64-<profile>-<filesystem>
```

`VM_TEST_IMAGE_NAME` names the manually tested image, build, or test line. It is not the ISO path and must not contain directories, spaces, shell metacharacters, or secrets. Use `VM_ISO` for the official Gentoo live ISO path.

Default examples:

```text
gentoo-test-amd64-openrc-ext4
gentoo-test-amd64-openrc-btrfs
gentoo-test-amd64-systemd-ext4
gentoo-test-amd64-systemd-btrfs
```

`VM_NAME` remains a conservative base name, not a full case name. Operators may override the base name, but generated case names must still include the case key.

The standard base VM name is `gentoo-test`; the project name remains `gentoo-ai-installer`.

The generated case name must be validated after suffixing. A base name plus optional manual image label that becomes too long after appending `-amd64-<profile>-<filesystem>` must fail with a clear error instead of truncating or silently producing duplicate names.

### Artifact Naming

For a case VM named `<case-vm-name>`, generated artifacts should use:

```text
var/libvirt/<case-vm-name>.qcow2
var/libvirt/<case-vm-name>.xml
var/libvirt/<case-vm-name>-OVMF_VARS.fd
logs/libvirt/<case-vm-name>/
var/state/libvirt/<case-vm-name>/current-install.json
```

If the current implementation uses different intermediate paths, it must preserve the same safety boundary and document the final paths.

The implementation must prevent accidental disk sharing between cases. The default disk path must be case-specific. If an operator supplies `VM_DISK` manually, the workflow must still validate the path, print it before use, and ensure matrix workflows do not reuse that override for multiple cases.

Generated libvirt metadata should include the project ownership marker plus optional `VM_TEST_IMAGE_NAME`, platform `amd64`, the selected `PROFILE`, `FILESYSTEM`, `STAGE3_FLAVOR`, and case name. Existing domains with matching names but missing or conflicting metadata must be refused for normal start, SSH bootstrap, and cleanup paths unless a recovery path explicitly proves they are safe project artifacts.

If deterministic MAC addresses are generated, they must be unique per case. If libvirt generates MAC addresses automatically, IP discovery must still filter by the selected case domain rather than a generic VM name.

### Makefile Interface

Existing VM targets should accept `PROFILE`, `FILESYSTEM`, and later approved selectors such as `STAGE3_FLAVOR`, then compute case-specific VM values before calling scripts:

```sh
make vm-list-cases
make vm-check PROFILE=openrc FILESYSTEM=ext4
make vm-disk PROFILE=openrc FILESYSTEM=ext4
make vm-define PROFILE=openrc FILESYSTEM=ext4
make vm-start PROFILE=openrc FILESYSTEM=ext4
make vm-bootstrap-ssh PROFILE=openrc FILESYSTEM=ext4
make vm-ansible-ping PROFILE=openrc FILESYSTEM=ext4
make vm-e2e-plan PROFILE=openrc FILESYSTEM=ext4
make vm-e2e-install PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda ADMIN_USER=<admin-user> ENABLE_SSH=yes ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file> I_UNDERSTAND_THIS_WIPES_DISK=yes I_UNDERSTAND_BOOTLOADER_CHANGES=yes
make vm-clean PROFILE=openrc FILESYSTEM=ext4 I_UNDERSTAND_CLEANUP_DELETE=DELETE
```

`make vm-list-cases` should be read-only. It should print all currently supported cases, generated VM names, qcow2 paths, state paths, derived user-mode SSH ports, and whether the corresponding domain currently exists.

`VM_TEST_IMAGE_NAME=<image-name>` should be accepted by list and matrix targets as an optional label. It must be printed in the selected configuration when set. It must not be required for normal validation.

All VM targets that operate on a selected case must print the selected case key, generated domain name, disk path, network mode, and libvirt URI before mutating VM artifacts or connecting to the VM.

The Makefile may also introduce explicit aliases if they reduce operator mistakes, for example:

```sh
make vm-amd64-openrc-ext4-start
make vm-amd64-systemd-btrfs-start
```

Aliases must delegate to the same shared case-selection logic. They must not duplicate script command chains.

The no-override default `make vm-start` may map to `PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard`, because those defaults already exist. Documentation must make clear that this now means the `amd64-openrc-ext4` standard stage3 case VM, not a generic domain named only `gentoo-ai-installer`.

### Matrix Integration

`make vm-test-matrix-plan` must report the same case-specific VM names and disk paths used by executable VM targets. If a future matrix runner creates or starts domains, it must create separate case VMs and disks rather than reusing one mutable domain for all cases.

If a future matrix cleanup target is added, it must list each case artifact before deletion and require `I_UNDERSTAND_CLEANUP_DELETE=DELETE`. It must not infer or delete arbitrary domains matching broad globs.

### Remote Ansible Boundary

Ansible wrappers may discover a case VM when `ANSIBLE_LIVE_HOST` is empty and the operator is running a local validation target. Reusable Ansible roles must not depend on:

- libvirt domain names,
- `VM_NAME`,
- `VM_DIR`,
- project-local qcow2 paths,
- libvirt network discovery,
- `/dev/vda` except when explicitly passed in a local VM workflow.

Remote or physical install workflows must continue to use explicit SSH target variables and explicit `INSTALL_DISK`.

Local VM wrappers may set case-specific default `INSTALL_STATE_FILE` values for validation runs. Reusable Ansible roles must treat the state file as an input path from the wrapper and must not derive it from libvirt facts.

### Safety Rules

- Generated VM disks must remain under the approved project-local `VM_DIR`.
- Scripts must reject `/dev/*` as host-side VM disk paths.
- Scripts must reject parent traversal, symlink escape, command-option separators, and unsafe characters in generated paths.
- Scripts must validate `VM_TEST_IMAGE_NAME` with the same conservative name rules used for generated domain names.
- User-mode SSH host ports must not collide if multiple case VMs are expected to run together. The default managed-network mode avoids this; if user-mode forwarding is used, ports must be explicit or derived uniquely per case.
- Cleanup must target only the selected case VM artifacts and require `I_UNDERSTAND_CLEANUP_DELETE=DELETE`.
- Cleanup must not remove artifacts for other cases unless a future matrix-clean target explicitly lists and confirms those cases.
- Existing libvirt domains with a generated case name must be treated carefully. The implementation must either prove they are project-owned or refuse to overwrite/redefine them.
- Destructive install execution inside the VM must still require `INSTALL_DISK=/dev/vda` and the normal destructive confirmation variables.

### Documentation Updates

Update:

- `README.md` with links to all supported per-case quickstarts.
- `docs/quickstarts/openrc-ext4.md`, `docs/quickstarts/openrc-btrfs.md`, `docs/quickstarts/systemd-ext4.md`, and `docs/quickstarts/systemd-btrfs.md` with commands for one-case VM validation.
- `docs/libvirt-manual-install-test.md` with case selection examples.
- `docs/libvirt-install-test-matrix.md` with concrete case VM names.
- `docs/libvirt-end-to-end-install-validation.md` with per-case e2e examples.
- `docs/ansible-architecture.md` to reinforce that case VMs are local harness objects.
- `docs/documentation-maintenance-checklist.md` if the VM documentation checklist needs the new case-specific state, domain, or cleanup rules.
- `skills/makefile-control-plane.md` if new targets or variables are added.
- `skills/ansible-gentoo-installer.md` if local VM discovery behavior changes.
- `agents/safety-review-agent.md` if cleanup or VM ownership safety rules change.
- `openspec/changes/implement-case-specific-libvirt-vms/tasks.md` as documentation work is completed.

Quickstarts must use `PROFILE` and `FILESYSTEM` as the normal case selectors, show the derived domain/disk/state paths as expected output, and avoid requiring operators to hand-build `VM_NAME`, `VM_DISK`, or `INSTALL_STATE_FILE` for normal VM workflows.

Quickstarts must describe how to include a manual test image label with `VM_TEST_IMAGE_NAME=<label>` and must state that this label is not an ISO path or secret-bearing value.

## Risks / Trade-offs

- Case-specific names add more local domains to manage. Mitigation: provide clear `vm-clean` and future matrix cleanup behavior with explicit confirmation.
- Operators may confuse `/dev/vda` VM examples with real hardware. Mitigation: keep `/dev/vda` labeled as VM-only in docs and require explicit `INSTALL_DISK`.
- Existing generic VM workflows could break if the migration is abrupt. Mitigation: preserve compatibility aliases where practical and document the case-specific default.
- If cleanup is too broad, unrelated VM artifacts could be deleted. Mitigation: cleanup must target configured case artifacts only and validate paths before deletion.
- If all supported case VMs are run at the same time, shared SSH ports, state files, or domain MACs could collide. Mitigation: default to managed networking, derive per-case state paths, and validate unique case identity before defining domains.
- Existing generic domains or disks may remain after migration. Mitigation: do not auto-delete them; document how to inspect and clean them separately after confirmation.
