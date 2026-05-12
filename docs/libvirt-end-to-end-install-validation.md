# Libvirt End-to-End Install Validation

Libvirt end-to-end validation runs the full installer against the disposable project VM before real hardware use. It uses the official Gentoo live ISO, a project-local qcow2 disk, SSH-driven Ansible, and first-boot validation from the installed disk.

## Plan Only

Always start with the read-only plan:

```sh
make vm-list-cases
make vm-e2e-plan PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard INSTALL_DISK=/dev/vda ADMIN_USER=<admin-user> ENABLE_SSH=yes ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file>
```

The plan:

- validates that the selected entry is supported,
- uses the case-specific VM identity derived from `PROFILE`, `FILESYSTEM`, and `STAGE3_FLAVOR`,
- requires explicit `INSTALL_DISK=/dev/vda`,
- requires `ADMIN_USER` because first-boot validation needs an installed account,
- requires `ENABLE_SSH=yes` because first-boot validation connects over SSH,
- requires `ADMIN_AUTHORIZED_KEYS_FILE` containing public keys so first-boot validation can authenticate,
- integrates the libvirt matrix planner,
- writes `logs/libvirt-e2e/<timestamp>-<profile>-<filesystem>[-<stage3-flavor>]/e2e-plan.json`,
- does not create disks, define domains, start VMs, partition, format, install, or reboot.

## Full Disposable VM Validation

Run this only when the VM is intended to be disposable:

```sh
make vm-e2e-install \
  PROFILE=openrc \
  FILESYSTEM=ext4 \
  STAGE3_FLAVOR=standard \
  INSTALL_DISK=/dev/vda \
  ADMIN_USER=<admin-user> \
  ENABLE_SSH=yes \
  ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file> \
  I_UNDERSTAND_THIS_WIPES_DISK=yes \
  I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

The wrapper runs:

1. `vm-e2e-plan`
2. `vm-check`
3. `vm-disk`
4. `vm-start`
5. `vm-bootstrap-ssh`
6. `vm-ansible-ping`
7. full shared basic-console install for the selected profile/filesystem/stage3 flavor
8. `vm-shutdown` to let the live ISO flush and unmount the installed filesystems cleanly
9. `vm-validate-first-boot`
10. `install-audit`

Disposable E2E installs default to passwordless sudo for the installed admin account:

```text
VM_E2E_ADMIN_SUDO_NOPASSWD=yes
```

This makes `ssh <admin>@<vm-ip>` followed by `sudo su -` work without a password in test VMs. Override with `ADMIN_SUDO_NOPASSWD=no` if the test should keep password-requiring sudo.

To reset generated VM artifacts and the selected case state pointer before the run:

```sh
make vm-e2e-install \
  PROFILE=openrc \
  FILESYSTEM=ext4 \
  STAGE3_FLAVOR=standard \
  INSTALL_DISK=/dev/vda \
  ADMIN_USER=<admin-user> \
  ENABLE_SSH=yes \
  ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file> \
  VM_E2E_RESET_DISK=yes \
  I_UNDERSTAND_CLEANUP_DELETE=DELETE \
  I_UNDERSTAND_THIS_WIPES_DISK=yes \
  I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

## Logs

The wrapper writes step logs under:

```text
logs/libvirt-e2e/<timestamp>-<profile>-<filesystem>[-<stage3-flavor>]/
```

The install itself writes normal state, audit, and report evidence under:

```text
var/state/libvirt/<case-domain>/current-install.json
logs/install-runs/<run-id>/
```

These paths are ignored by git.

## Matrix Integration

`vm-e2e-plan` includes the OpenRC/systemd, ext4/Btrfs, and standard/hardened/musl matrix planner. Single-case destructive execution validates the selected entry.

To reset and validate all 12 disposable libvirt cases through the same single-case workflow, run:

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

`vm-e2e-matrix` runs every supported combination:

- `amd64-openrc-ext4`
- `amd64-openrc-btrfs`
- `amd64-systemd-ext4`
- `amd64-systemd-btrfs`
- `amd64-openrc-ext4-hardened`
- `amd64-openrc-btrfs-hardened`
- `amd64-systemd-ext4-hardened`
- `amd64-systemd-btrfs-hardened`
- `amd64-openrc-ext4-musl`
- `amd64-openrc-btrfs-musl`
- `amd64-systemd-ext4-musl`
- `amd64-systemd-btrfs-musl`

The target runs cases in parallel by default. Use `VM_E2E_MATRIX_PARALLEL=1..12` to change concurrency. The target requires `VM_E2E_RESET_DISK=yes` so every case starts from a fresh qcow2 and case state pointer.

Matrix logs are written under:

```text
logs/libvirt-e2e-matrix/<timestamp>/matrix-e2e.json
logs/libvirt-e2e-matrix/<timestamp>/<case>/vm-e2e-install.log
```

## Safety

- Host block devices are never valid VM disks.
- The generated `VM_DISK` must remain a project-relative qcow2 path under `VM_DIR`.
- `VM_NAME` is a base name; VM targets derive `<base>[-VM_TEST_IMAGE_NAME]-amd64-<profile>-<filesystem>[-<stage3-flavor>]`.
- `INSTALL_DISK=/dev/vda` is valid only inside the libvirt guest.
- Full validation still requires `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- Bootloader validation still requires `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`.
- Installed SSH must be enabled with `ENABLE_SSH=yes`, and `ADMIN_AUTHORIZED_KEYS_FILE` must contain public keys so first-boot validation can connect without a password.
- Disposable E2E validation defaults to `ADMIN_SUDO_NOPASSWD=yes` through `VM_E2E_ADMIN_SUDO_NOPASSWD=yes`; real installs keep password-requiring sudo unless explicitly changed.
- The live ISO VM is cleanly shut down before first-boot validation. This avoids booting from a qcow2 whose target filesystems still have pending writes.
- Resetting generated VM artifacts and the selected case state pointer requires `I_UNDERSTAND_CLEANUP_DELETE=DELETE`.
- Matrix validation requires `VM_E2E_RESET_DISK=yes` and rejects manual `VM_DISK` overrides so cases cannot share one qcow2 by accident.
- The wrapper does not replace manual review before real hardware use.

## Failure Modes

- `VM_E2E_INVALID`: unsupported profile/filesystem/stage3 flavor, missing `ADMIN_USER`, missing `ADMIN_AUTHORIZED_KEYS_FILE`, or missing explicit `/dev/vda`.
- `DESTRUCTIVE_CONFIRMATION_MISSING`: required install or bootloader confirmation is missing.
- `CONFIRMATION_MISSING`: reset was requested without cleanup confirmation.
- VM bootstrap failure: open the selected case console with `make vm-console PROFILE=<profile> FILESYSTEM=<filesystem>` and inspect the live ISO.
- Clean shutdown timeout: inspect the console and rerun `make vm-shutdown PROFILE=<profile> FILESYSTEM=<filesystem> VM_SHUTDOWN_TIMEOUT=<seconds>` before first-boot validation.
- First-boot validation failure: inspect `logs/libvirt-e2e/` and `logs/install-runs/<run-id>/first-boot/`.
- Matrix failure: inspect `logs/libvirt-e2e-matrix/<timestamp>/<case>/vm-e2e-install.log`, then rerun only the failed case with `make vm-e2e-install PROFILE=<profile> FILESYSTEM=<filesystem> ...`.

## Recovery

Use the generated logs to identify the failed phase. For disposable VM retries, use:

```sh
make vm-clean I_UNDERSTAND_CLEANUP_DELETE=DELETE
make vm-e2e-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda ADMIN_USER=<admin-user> ENABLE_SSH=yes ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file>
```

Then rerun `make vm-e2e-install` with the required confirmations.
