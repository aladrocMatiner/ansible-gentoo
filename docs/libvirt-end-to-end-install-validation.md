# Libvirt End-to-End Install Validation

Libvirt end-to-end validation runs the full installer against the disposable project VM before real hardware use. It uses the official Gentoo live ISO, a project-local qcow2 disk, SSH-driven Ansible, and first-boot validation from the installed disk.

## Plan Only

Always start with the read-only plan:

```sh
make vm-e2e-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda ADMIN_USER=<admin-user> ENABLE_SSH=yes
```

The plan:

- validates that the selected entry is supported,
- requires explicit `INSTALL_DISK=/dev/vda`,
- requires `ADMIN_USER` because first-boot validation needs an installed account,
- requires `ENABLE_SSH=yes` because first-boot validation connects over SSH,
- integrates the libvirt matrix planner,
- writes `logs/libvirt-e2e/<timestamp>/e2e-plan.json`,
- does not create disks, define domains, start VMs, partition, format, install, or reboot.

## Full Disposable VM Validation

Run this only when the VM is intended to be disposable:

```sh
make vm-e2e-install \
  PROFILE=openrc \
  FILESYSTEM=ext4 \
  INSTALL_DISK=/dev/vda \
  ADMIN_USER=<admin-user> \
  ENABLE_SSH=yes \
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
7. full shared basic-console install for the selected profile/filesystem
8. `vm-validate-first-boot`
9. `install-audit`

To reset generated VM artifacts before the run:

```sh
make vm-e2e-install \
  PROFILE=openrc \
  FILESYSTEM=ext4 \
  INSTALL_DISK=/dev/vda \
  ADMIN_USER=<admin-user> \
  ENABLE_SSH=yes \
  VM_E2E_RESET_DISK=yes \
  I_UNDERSTAND_CLEANUP_DELETE=DELETE \
  I_UNDERSTAND_THIS_WIPES_DISK=yes \
  I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

## Logs

The wrapper writes step logs under:

```text
logs/libvirt-e2e/<timestamp>-<profile>-<filesystem>/
```

The install itself writes normal state, audit, and report evidence under:

```text
var/state/
logs/install-runs/<run-id>/
```

These paths are ignored by git.

## Matrix Integration

`vm-e2e-plan` includes the OpenRC/systemd and ext4/Btrfs matrix planner. Current destructive execution validates the selected entry. Broader destructive matrix execution must be added by a later change and must use separate disposable qcow2 disks or equivalent reset logic per entry.

## Safety

- Host block devices are never valid VM disks.
- `VM_DISK` must remain a project-relative qcow2 path under `VM_DIR`.
- `INSTALL_DISK=/dev/vda` is valid only inside the libvirt guest.
- Full validation still requires `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- Bootloader validation still requires `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`.
- Installed SSH must be enabled with `ENABLE_SSH=yes` so first-boot validation can connect.
- Resetting generated VM artifacts requires `I_UNDERSTAND_CLEANUP_DELETE=DELETE`.
- The wrapper does not replace manual review before real hardware use.

## Failure Modes

- `VM_E2E_INVALID`: unsupported profile/filesystem, missing `ADMIN_USER`, or missing explicit `/dev/vda`.
- `DESTRUCTIVE_CONFIRMATION_MISSING`: required install or bootloader confirmation is missing.
- `CONFIRMATION_MISSING`: reset was requested without cleanup confirmation.
- VM bootstrap failure: open the console with `make vm-console` and inspect the live ISO.
- First-boot validation failure: inspect `logs/libvirt-e2e/` and `logs/install-runs/<run-id>/first-boot/`.

## Recovery

Use the generated logs to identify the failed phase. For disposable VM retries, use:

```sh
make vm-clean I_UNDERSTAND_CLEANUP_DELETE=DELETE
make vm-e2e-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda ADMIN_USER=<admin-user> ENABLE_SSH=yes
```

Then rerun `make vm-e2e-install` with the required confirmations.
