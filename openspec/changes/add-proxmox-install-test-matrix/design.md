# Design: add-proxmox-install-test-matrix

## 1. Position In The Project

Proxmox is a remote VM validation harness for the reusable SSH-driven Ansible installer.

It must not become a separate installer architecture. The install sequence remains:

1. boot the official Gentoo live ISO,
2. make the live ISO reachable over SSH,
3. run the existing Makefile-mediated Ansible installer over SSH,
4. validate first boot of the installed system.

Libvirt remains the local development harness. Proxmox adds a network virtualization harness that is closer to real remote targets.

## 2. Proxmox Tooling

The initial implementation should use Proxmox VE CLI tools on a Proxmox node:

- `qm` for VM lifecycle and configuration,
- `pvesm` for storage inspection where needed,
- `ssh` from the controller to the live ISO once the VM is booted,
- `make` as the public control plane.

The official Proxmox `qm` command supports VM creation, configuration, serial devices, cloud-init devices, start, shutdown, stop, and destroy operations. This project should use those primitives conservatively and only through documented Makefile targets.

The first version should not depend on the Proxmox REST API, Terraform, Packer, or Ansible Proxmox modules. Those may be evaluated later if they reduce risk and duplication.

## 3. Required Proxmox Variables

Required variables:

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `PROXMOX_NODE` | yes | none | Human-readable Proxmox node name for documentation/evidence. |
| `PROXMOX_STORAGE` | yes | none | Storage ID for generated VM disks and EFI vars. |
| `PROXMOX_BRIDGE` | yes | `vmbr0` may be documented, but implementation should require explicit confirmation for shared hosts | Bridge for VM network. |
| `PROXMOX_ISO` | yes | none | Proxmox ISO volume ID for the official Gentoo live ISO, for example `local:iso/install-amd64.iso`. |
| `PROXMOX_VMID_BASE` | yes | none | First VMID reserved for the generated matrix. |
| `PROXMOX_VMID` | single case only | none | Explicit VMID for one selected case. |
| `PROXMOX_DISK_SIZE` | no | `40G` | Virtual disk size. |
| `PROXMOX_RAM` | no | `4096` | VM memory in MB. |
| `PROXMOX_CPUS` | no | `2` | VM vCPU count. |
| `PROXMOX_BOOT_MODE` | no | `uefi` | Boot mode; v1 supports UEFI only. |
| `PROXMOX_VM_TAG` | no | `gentoo-ai-installer` | Ownership tag or description marker. |
| `PROXMOX_MATRIX_PARALLEL` | no | `4` | Maximum concurrent Proxmox E2E installs in the current lab. |
| `PROXMOX_IP_BASE` | no | `10.64.70.99` | First static live ISO IP for the 12-case matrix; current lab allocation uses `10.64.70.99-110` inside the requested `10.64.70.90-110` range because `.90-.92` were already occupied. |

Existing installer variables still apply:

- `PROFILE=openrc|systemd`
- `FILESYSTEM=ext4|btrfs`
- `STAGE3_FLAVOR=standard|hardened|musl`
- `INSTALL_DISK=<guest disk path>`
- `ADMIN_USER`
- `ENABLE_SSH=yes`
- `ADMIN_AUTHORIZED_KEYS_FILE`
- `ENABLE_QEMU_GUEST_AGENT=yes|no`
- `I_UNDERSTAND_THIS_WIPES_DISK=yes`
- `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`

`INSTALL_DISK` must not have a default. For Proxmox virtio/SCSI disk naming, `/dev/vda` or `/dev/sda` may be documented per configured controller, but the value must be explicit and verified inside the live ISO.

For Proxmox disposable validation, installed access should be optimized for repeatable SSH validation:

- `ADMIN_USER` is explicit and required for E2E install validation.
- `ENABLE_SSH=yes` should be set for Proxmox E2E validation.
- `ADMIN_AUTHORIZED_KEYS_FILE` defaults to the controller machine's public SSH key file, preferring `~/.ssh/id_ed25519.pub` and allowing an explicit override.
- The selected public key is copied into `/home/<ADMIN_USER>/.ssh/authorized_keys` in the installed target.
- Private keys, certificates containing private material, password hashes, and tokens must never be copied or logged.
- The installed admin account should be able to SSH in without a password after first boot. Disposable validation may continue to use `ADMIN_SUDO_NOPASSWD=yes`; real hardware workflows must not inherit that default.
- Proxmox E2E validation should set `ENABLE_QEMU_GUEST_AGENT=yes` so the installed Gentoo guest installs `app-emulation/qemu-guest-agent` and enables `qemu-guest-agent` for OpenRC or `qemu-guest-agent.service` for systemd. VM creation should also enable the Proxmox guest-agent channel with `qm set <vmid> --agent enabled=1` for project-owned VMs, including preserved existing VMs. Normal non-Proxmox installs should keep the default `ENABLE_QEMU_GUEST_AGENT=no`.

## 4. Matrix Cases

The Proxmox matrix should match the current libvirt matrix exactly:

| Case | Profile | Filesystem | Stage3 flavor |
| --- | --- | --- | --- |
| `amd64-openrc-ext4` | `openrc` | `ext4` | `standard` |
| `amd64-openrc-btrfs` | `openrc` | `btrfs` | `standard` |
| `amd64-systemd-ext4` | `systemd` | `ext4` | `standard` |
| `amd64-systemd-btrfs` | `systemd` | `btrfs` | `standard` |
| `amd64-openrc-ext4-hardened` | `openrc` | `ext4` | `hardened` |
| `amd64-openrc-btrfs-hardened` | `openrc` | `btrfs` | `hardened` |
| `amd64-systemd-ext4-hardened` | `systemd` | `ext4` | `hardened` |
| `amd64-systemd-btrfs-hardened` | `systemd` | `btrfs` | `hardened` |
| `amd64-openrc-ext4-musl` | `openrc` | `ext4` | `musl` |
| `amd64-openrc-btrfs-musl` | `openrc` | `btrfs` | `musl` |
| `amd64-systemd-ext4-musl` | `systemd` | `ext4` | `musl` |
| `amd64-systemd-btrfs-musl` | `systemd` | `btrfs` | `musl` |

VM names should follow:

```text
gentoo-test-amd64-<profile>-<filesystem>[-<stage3-flavor>]
```

If `VM_TEST_IMAGE_NAME` or a Proxmox-specific equivalent is provided, it may be inserted after `gentoo-test`:

```text
gentoo-test-<label>-amd64-<profile>-<filesystem>[-<stage3-flavor>]
```

The standard flavor omits the suffix, matching the libvirt naming policy.

## 5. VMID Mapping

The matrix must not guess arbitrary VMIDs.

For matrix runs:

- require `PROXMOX_VMID_BASE`,
- derive each case VMID by adding a stable case index,
- print the full VMID-to-case table before any VM creation,
- fail if any planned VMID already exists without the project ownership marker,
- fail if any planned VMID is outside a conservative numeric range accepted by Proxmox.

For single-case runs:

- require `PROXMOX_VMID` or derive it from `PROXMOX_VMID_BASE` plus the selected case index,
- print the selected VMID, VM name, storage, ISO, bridge, disk size, and expected guest disk before mutation.

## 6. VM Hardware Defaults

Suggested defaults:

- architecture: amd64/x86_64,
- machine: Proxmox default for Linux unless UEFI requires explicit machine configuration,
- RAM: `16384` for the current Proxmox lab profile,
- CPUs: `4` for the current Proxmox lab profile,
- disk size: `80G` for the current Proxmox lab profile,
- storage: `ceph_low_prio` for generated VM disks,
- VLAN: `1070` on `vmbr0`,
- static live ISO IP range: `10.64.70.99-110`,
- disk bus: prefer virtio-scsi or virtio block, but document the resulting guest disk name,
- network: `virtio` NIC attached to `PROXMOX_BRIDGE`,
- guest agent channel: enabled for project-owned Proxmox validation VMs,
- boot mode: UEFI only,
- display/console: serial console plus normal Proxmox console if practical,
- boot order: ISO first for live install, disk first for installed first boot.

The implementation should configure a serial console when possible so `qm terminal <VMID>` or the Proxmox console can be used for live ISO troubleshooting.

## 7. ISO Handling

`PROXMOX_ISO` must refer to an existing Proxmox ISO volume for the official Gentoo live ISO.

The workflow must:

- fail if `PROXMOX_ISO` is missing,
- validate that it points to ISO storage syntax accepted by Proxmox,
- document how operators upload or reference the ISO outside this project,
- not copy the ISO into git,
- not build or modify a custom ISO.

## 8. SSH Bootstrap

The Proxmox workflow should reuse the same live ISO SSH policy as libvirt where practical:

- boot the official live ISO,
- use serial console or documented manual console steps to install an authorized public key,
- start `sshd`,
- discover or configure the VM IP,
- run `make proxmox-ansible-ping` or equivalent.

The first implementation may require manual console bootstrap if fully automated serial interaction is unreliable on Proxmox. If manual bootstrap is required, it must be documented as an explicit step and not hidden as automation.

Installed-system SSH is separate from temporary live ISO SSH. Proxmox E2E installs should enable installed `sshd` when `ENABLE_SSH=yes`, generate missing target SSH host keys, install the controller public key for the explicit `ADMIN_USER`, and keep first-boot validation as a follow-up workflow unless implemented in the same change.

## 9. Makefile Targets

Proposed targets:

- `make proxmox-check`
- `make proxmox-list-cases`
- `make proxmox-test-matrix-plan`
- `make proxmox-vm-create`
- `make proxmox-vm-start`
- `make proxmox-vm-console`
- `make proxmox-vm-ip`
- `make proxmox-bootstrap-ssh`
- `make proxmox-ansible-ping`
- `make proxmox-e2e-install`
- `make proxmox-e2e-matrix`
- `make proxmox-vm-shutdown`
- `make proxmox-vm-clean`

All targets must have `make help` entries before implementation is considered complete.

## 10. Execution Flow

Single-case flow:

1. `make proxmox-check`
2. `make proxmox-list-cases`
3. `make proxmox-vm-create ...`
4. `make proxmox-vm-start ...`
5. `make proxmox-bootstrap-ssh ...`
6. `make proxmox-ansible-ping ...`
7. `make proxmox-e2e-install ... INSTALL_DISK=...`
8. `make proxmox-vm-shutdown ...`
9. optional installed-disk boot with `make proxmox-vm-start-installed ...`

Matrix flow:

1. `make proxmox-list-cases`
2. `make proxmox-test-matrix-plan PROXMOX_VMID_BASE=...`
3. `make proxmox-e2e-matrix PROXMOX_VMID_BASE=... PROXMOX_MATRIX_PARALLEL=4 ...`

The current lab default matrix parallelism is `4`, matching the operator request for four concurrent Proxmox installs. Operators may lower it if storage or network contention appears.

## 11. Safety Gates

Create/start safety:

- refuse missing `PROXMOX_ISO`,
- refuse missing `PROXMOX_STORAGE`,
- refuse missing VMID,
- refuse unsupported BIOS mode,
- refuse existing VMID unless it is project-owned and explicitly reset,
- refuse ambiguous disk bus-to-guest-device mapping.

Install safety:

- no default `INSTALL_DISK`,
- destructive install still requires `I_UNDERSTAND_THIS_WIPES_DISK=yes`,
- bootloader work still requires `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`,
- selected install disk must be detected inside the live ISO before partitioning.

Cleanup safety:

- require `I_UNDERSTAND_CLEANUP_DELETE=DELETE`,
- print VMID, name, storage volumes, and ownership marker before deletion,
- operate only on expected project-owned VMIDs,
- delete only volumes attached to the selected project-owned VM,
- never delete ISO volumes,
- never delete templates or unrelated VMIDs,
- never use wildcard `qm destroy` or broad storage deletion.

## 12. Logs And Evidence

Proxmox workflows should write:

```text
logs/proxmox-matrix/<timestamp>/matrix-plan.json
logs/proxmox-e2e/<timestamp>-<profile>-<filesystem>[-<stage3-flavor>]/
logs/proxmox-e2e-matrix/<timestamp>/matrix-e2e.json
```

Evidence should include:

- VMID,
- VM name,
- Proxmox node,
- storage,
- ISO volume,
- bridge,
- disk bus,
- expected guest disk,
- live ISO IP,
- install run ID,
- first boot result,
- QEMU guest agent enablement when requested,
- cleanup status when applicable.

## 13. Documentation Requirements

Implementation must update:

- `README.md` with concise Proxmox entry points,
- `docs/proxmox-install-test-matrix.md`,
- `docs/proxmox-end-to-end-install-validation.md`,
- an indexed Proxmox matrix document covering all 12 cases,
- `docs/supported-host-requirements.md` or a Proxmox-specific requirements page,
- `AGENTS.md` to mention Proxmox as a remote VM validation harness,
- relevant skills and agents for Makefile, Ansible, and safety behavior.

Proxmox docs must clearly state what is implemented versus planned.

## 14. Failure Modes

- Proxmox CLI tools unavailable: run on a Proxmox node or configure a documented remote execution path in a later change.
- `PROXMOX_ISO` missing: upload or reference the official Gentoo live ISO in Proxmox storage.
- VMID collision: choose another `PROXMOX_VMID` or `PROXMOX_VMID_BASE`; do not reuse unrelated VMIDs.
- Bridge misconfiguration: fix Proxmox networking before booting the VM.
- Live ISO has no SSH: use console bootstrap or documented manual bootstrap.
- Guest disk appears under a different device path: rerun disk detection and pass explicit `INSTALL_DISK`.
- DNS or mirror failures inside the live ISO/chroot: use existing mirror/cache policy and retry/resume guidance.

## 15. Alignment With Existing Work

This change aligns with existing rules:

- Makefile remains the operator-facing control plane.
- OpenSpec controls the change.
- Ansible over SSH remains the product path.
- VM harness details stay outside reusable Ansible roles.
- UEFI remains default and required for v1.
- No custom ISO is introduced.
- No host block devices are touched.
- The official Gentoo AMD64 Handbook remains the installation baseline.
