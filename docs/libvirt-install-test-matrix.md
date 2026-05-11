# Libvirt Install Test Matrix

The libvirt install test matrix keeps amd64 OpenRC/systemd and ext4/Btrfs validation from drifting. It uses the local libvirt harness as disposable test infrastructure for the reusable network Ansible installer.

The current matrix target is a safe planning target. It does not create disks, define domains, start VMs, partition, format, mount, or install Gentoo. Full validation of one selected entry is exposed separately through `make vm-e2e-plan` and `make vm-e2e-install`; see `docs/libvirt-end-to-end-install-validation.md`.

## Matrix Entries

The required entries are:

| Entry | Platform | Profile | Filesystem |
| --- | --- | --- | --- |
| `amd64-openrc-ext4` | `amd64` | `openrc` | `ext4` |
| `amd64-openrc-btrfs` | `amd64` | `openrc` | `btrfs` |
| `amd64-systemd-ext4` | `amd64` | `systemd` | `ext4` |
| `amd64-systemd-btrfs` | `amd64` | `systemd` | `btrfs` |

Each entry uses the same naming rules as executable `vm-*` targets:

```text
VM_NAME-amd64-<profile>-<filesystem>
VM_DIR/VM_NAME-amd64-<profile>-<filesystem>.qcow2
```

If `VM_TEST_IMAGE_NAME` is set, it is inserted between the base VM name and the platform segment:

```text
VM_NAME-VM_TEST_IMAGE_NAME-amd64-<profile>-<filesystem>
VM_DIR/VM_NAME-VM_TEST_IMAGE_NAME-amd64-<profile>-<filesystem>.qcow2
```

`VM_TEST_IMAGE_NAME` is a conservative label for the manually tested image or test line. It is not an ISO path; use `VM_ISO` for the official Gentoo live ISO path.

The planned guest install disk is `/dev/vda`, which is valid only inside the libvirt VM. Do not copy `/dev/vda` into real hardware workflows.

## Per-Case Quickstarts

Use the case quickstarts when validating one case at a time:

| Case | Quickstart |
| --- | --- |
| `amd64-openrc-ext4` | [amd64 OpenRC + ext4](quickstarts/openrc-ext4.md) |
| `amd64-openrc-btrfs` | [amd64 OpenRC + Btrfs](quickstarts/openrc-btrfs.md) |
| `amd64-systemd-ext4` | [amd64 systemd + ext4](quickstarts/systemd-ext4.md) |
| `amd64-systemd-btrfs` | [amd64 systemd + Btrfs](quickstarts/systemd-btrfs.md) |

## Run The Plan

```sh
make vm-list-cases
make vm-test-matrix-plan
```

`make vm-list-cases` shows current generated artifacts and domain status. `make vm-test-matrix` is an alias for `make vm-test-matrix-plan`.

The target writes:

```text
logs/libvirt-matrix/<timestamp>/matrix-plan.json
logs/libvirt-matrix/<timestamp>/<entry>/entry.json
logs/libvirt-matrix/<timestamp>/<entry>/config-check.txt
```

Logs are ignored by git.

## Optional Target Plan Validation

After a live ISO VM is booted and SSH-enabled, the matrix can run the implemented read-only Ansible plan targets for each entry:

```sh
make vm-test-matrix-plan VM_TEST_MATRIX_RUN_TARGET_PLANS=yes
```

This attempts read-only:

- `install-plan`,
- `partition-plan`,
- `mount-plan`,
- `filesystem-plan`.

The target still does not run destructive install steps. Full destructive matrix runs are planned for a later change and must use disposable qcow2 disks plus normal destructive confirmations.

## Variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `VM_TEST_MATRIX_LOG_DIR` | `logs/libvirt-matrix` | Project-local report directory. |
| `VM_TEST_MATRIX_INSTALL_DISK` | `/dev/vda` | Guest disk path for disposable libvirt matrix entries. |
| `VM_TEST_MATRIX_RUN_TARGET_PLANS` | `no` | Set to `yes` only after a live ISO target is booted and SSH-enabled. |
| `VM_NAME` | `gentoo-test` | Base name for generated matrix domains; do not pass a full case name. |
| `VM_TEST_IMAGE_NAME` | empty | Optional manual test image label inserted into generated domain and disk names. |
| `VM_DIR` | `var/libvirt` | Base artifact directory for planned qcow2 disk names. |

## Safety

- Matrix planning never uses host block devices.
- Planned disks stay under `VM_DIR`.
- Planned domains use conservative names.
- Manual `VM_DISK` overrides are rejected for matrix planning so one disk cannot be reused across cases by accident.
- The target does not create or delete disks or domains.
- Destructive matrix execution is not implemented by this target.
- Future destructive matrix runs must require `I_UNDERSTAND_THIS_WIPES_DISK=yes` and use the same shared safety gates as single-variant installs.

## Failure Modes

- Unsafe `VM_NAME`, `VM_TEST_IMAGE_NAME`, `VM_DIR`, or `VM_TEST_MATRIX_LOG_DIR`: choose conservative project-relative values.
- `VM_TEST_MATRIX_INSTALL_DISK` is not `/dev/vda`: keep matrix planning scoped to the disposable libvirt guest disk.
- Config validation fails for an entry: inspect that entry's `config-check.txt`.
- Target plan validation fails: ensure the live ISO VM is running, SSH is enabled, and `make vm-ansible-ping` passes first.

## Recovery

Fix the reported variable or VM connectivity issue and rerun:

```sh
make vm-test-matrix-plan
```

For target plan validation failures, rerun `make vm-check`, `make vm-start`, `make vm-bootstrap-ssh`, and `make vm-ansible-ping` before rerunning the matrix with `VM_TEST_MATRIX_RUN_TARGET_PLANS=yes`.
