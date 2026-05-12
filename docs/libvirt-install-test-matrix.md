# Libvirt Install Test Matrix

The libvirt install test matrix keeps amd64 OpenRC/systemd, ext4/Btrfs, and standard/hardened/musl stage3 flavor validation from drifting. It uses the local libvirt harness as disposable test infrastructure for the reusable network Ansible installer.

`make vm-test-matrix-plan` is the safe planning target. It does not create disks, define domains, start VMs, partition, format, mount, or install Gentoo. Full validation of one selected entry is exposed through `make vm-e2e-plan` and `make vm-e2e-install`; full validation of all 12 disposable cases is exposed through `make vm-e2e-matrix`. See `docs/libvirt-end-to-end-install-validation.md`.

## Matrix Entries

The required entries are:

| Entry | Platform | Profile | Filesystem | Stage3 flavor | SSH port |
| --- | --- | --- | --- | --- | --- |
| `amd64-openrc-ext4` | `amd64` | `openrc` | `ext4` | `standard` | `2222` |
| `amd64-openrc-btrfs` | `amd64` | `openrc` | `btrfs` | `standard` | `2223` |
| `amd64-systemd-ext4` | `amd64` | `systemd` | `ext4` | `standard` | `2224` |
| `amd64-systemd-btrfs` | `amd64` | `systemd` | `btrfs` | `standard` | `2225` |
| `amd64-openrc-ext4-hardened` | `amd64` | `openrc` | `ext4` | `hardened` | `2226` |
| `amd64-openrc-btrfs-hardened` | `amd64` | `openrc` | `btrfs` | `hardened` | `2227` |
| `amd64-systemd-ext4-hardened` | `amd64` | `systemd` | `ext4` | `hardened` | `2228` |
| `amd64-systemd-btrfs-hardened` | `amd64` | `systemd` | `btrfs` | `hardened` | `2229` |
| `amd64-openrc-ext4-musl` | `amd64` | `openrc` | `ext4` | `musl` | `2230` |
| `amd64-openrc-btrfs-musl` | `amd64` | `openrc` | `btrfs` | `musl` | `2231` |
| `amd64-systemd-ext4-musl` | `amd64` | `systemd` | `ext4` | `musl` | `2232` |
| `amd64-systemd-btrfs-musl` | `amd64` | `systemd` | `btrfs` | `musl` | `2233` |

Each entry uses the same naming rules as executable `vm-*` targets:

```text
VM_NAME-amd64-<profile>-<filesystem>[-<stage3-flavor>]
VM_DIR/VM_NAME-amd64-<profile>-<filesystem>[-<stage3-flavor>].qcow2
```

`STAGE3_FLAVOR=standard` omits the suffix to preserve existing names. `hardened` and `musl` append the flavor explicitly.

If `VM_TEST_IMAGE_NAME` is set, it is inserted between the base VM name and the platform segment:

```text
VM_NAME-VM_TEST_IMAGE_NAME-amd64-<profile>-<filesystem>[-<stage3-flavor>]
VM_DIR/VM_NAME-VM_TEST_IMAGE_NAME-amd64-<profile>-<filesystem>[-<stage3-flavor>].qcow2
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
| `amd64-openrc-ext4-hardened` | [amd64 OpenRC + ext4 + hardened](quickstarts/openrc-ext4-hardened.md) |
| `amd64-openrc-btrfs-hardened` | [amd64 OpenRC + Btrfs + hardened](quickstarts/openrc-btrfs-hardened.md) |
| `amd64-systemd-ext4-hardened` | [amd64 systemd + ext4 + hardened](quickstarts/systemd-ext4-hardened.md) |
| `amd64-systemd-btrfs-hardened` | [amd64 systemd + Btrfs + hardened](quickstarts/systemd-btrfs-hardened.md) |
| `amd64-openrc-ext4-musl` | [amd64 OpenRC + ext4 + musl](quickstarts/openrc-ext4-musl.md) |
| `amd64-openrc-btrfs-musl` | [amd64 OpenRC + Btrfs + musl](quickstarts/openrc-btrfs-musl.md) |
| `amd64-systemd-ext4-musl` | [amd64 systemd + ext4 + musl](quickstarts/systemd-ext4-musl.md) |
| `amd64-systemd-btrfs-musl` | [amd64 systemd + Btrfs + musl](quickstarts/systemd-btrfs-musl.md) |

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

The target still does not run destructive install steps.

## Full E2E Matrix Validation

Run this only when all 12 case VMs are disposable:

```sh
make vm-e2e-matrix \
  ADMIN_USER=<admin-user> \
  ENABLE_SSH=yes \
  ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file> \
  VM_E2E_RESET_DISK=yes \
  I_UNDERSTAND_CLEANUP_DELETE=DELETE \
  I_UNDERSTAND_THIS_WIPES_DISK=yes \
  I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

`vm-e2e-matrix` invokes `make vm-e2e-install` for each matrix entry. It does not implement a separate installation path. It uses parallelism `4` by default; set `VM_E2E_MATRIX_PARALLEL=1` through `12` to control concurrency.

Each E2E child defaults to `VM_E2E_ADMIN_SUDO_NOPASSWD=yes`, so the installed admin user can run `sudo su -` without a password in the disposable test VM. Override with `ADMIN_SUDO_NOPASSWD=no` if a matrix run should validate password-requiring sudo.

Matrix execution derives the unique user-mode SSH host port for each case from the table above. Do not pass a manual `VM_SSH_HOST_PORT` override to `make vm-list-cases` or `make vm-e2e-matrix`; those targets fail if the value is not the default `2222`, because one shared override would collide across parallel cases.

The target writes:

```text
logs/libvirt-e2e-matrix/<timestamp>/matrix-e2e.json
logs/libvirt-e2e-matrix/<timestamp>/<entry>/vm-e2e-install.log
```

Each child still writes normal single-case logs under `logs/libvirt-e2e/`, `logs/install-runs/`, and `var/state/libvirt/<case-domain>/`.

## Variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `VM_TEST_MATRIX_LOG_DIR` | `logs/libvirt-matrix` | Project-local report directory. |
| `VM_TEST_MATRIX_INSTALL_DISK` | `/dev/vda` | Guest disk path for disposable libvirt matrix entries. |
| `VM_TEST_MATRIX_RUN_TARGET_PLANS` | `no` | Set to `yes` only after a live ISO target is booted and SSH-enabled. |
| `VM_E2E_MATRIX_LOG_DIR` | `logs/libvirt-e2e-matrix` | Project-local full E2E matrix report directory. |
| `VM_E2E_MATRIX_PARALLEL` | `4` | Number of concurrent full E2E case installs, from `1` to `12`. |
| `VM_E2E_ADMIN_SUDO_NOPASSWD` | `yes` | Disposable E2E default that enables admin `NOPASSWD: ALL` unless `ADMIN_SUDO_NOPASSWD` overrides it. |
| `VM_NAME` | `gentoo-test` | Base name for generated matrix domains; do not pass a full case name. |
| `VM_TEST_IMAGE_NAME` | empty | Optional manual test image label inserted into generated domain and disk names. |
| `VM_DIR` | `var/libvirt` | Base artifact directory for planned qcow2 disk names. |
| `VM_SSH_HOST_PORT` | `2222` | Leave at the default for matrix/list targets so each case can derive its unique port. |

## Safety

- Matrix planning never uses host block devices.
- Planned disks stay under `VM_DIR`.
- Planned domains use conservative names.
- Manual `VM_DISK` overrides are rejected for matrix planning so one disk cannot be reused across cases by accident.
- Manual `VM_SSH_HOST_PORT` overrides are rejected for matrix/list targets so user-mode networking cannot assign the same host port to multiple cases.
- The target does not create or delete disks or domains.
- Full E2E matrix execution is available only through `make vm-e2e-matrix`.
- Full E2E matrix execution requires `VM_E2E_RESET_DISK=yes`, `I_UNDERSTAND_CLEANUP_DELETE=DELETE`, `I_UNDERSTAND_THIS_WIPES_DISK=yes`, and `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`.
- Full E2E matrix execution reuses the same shared safety gates as single-variant installs.
- Passwordless sudo in E2E VMs is a test convenience only; do not copy that policy into real installs unless it is explicitly desired.

## Failure Modes

- Unsafe `VM_NAME`, `VM_TEST_IMAGE_NAME`, `VM_DIR`, or `VM_TEST_MATRIX_LOG_DIR`: choose conservative project-relative values.
- `VM_TEST_MATRIX_INSTALL_DISK` is not `/dev/vda`: keep matrix planning scoped to the disposable libvirt guest disk.
- `VM_SSH_HOST_PORT` is not the default `2222`: unset it for matrix/list targets so per-case ports can be derived.
- Config validation fails for an entry: inspect that entry's `config-check.txt`.
- Target plan validation fails: ensure the live ISO VM is running, SSH is enabled, and `make vm-ansible-ping` passes first.
- Full E2E matrix entry fails: inspect `logs/libvirt-e2e-matrix/<timestamp>/<entry>/vm-e2e-install.log` and rerun that case individually with `make vm-e2e-install`.

## Recovery

Fix the reported variable or VM connectivity issue and rerun:

```sh
make vm-test-matrix-plan
```

For target plan validation failures, rerun `make vm-check`, `make vm-start`, `make vm-bootstrap-ssh`, and `make vm-ansible-ping` before rerunning the matrix with `VM_TEST_MATRIX_RUN_TARGET_PLANS=yes`.
