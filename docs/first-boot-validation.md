# First-Boot Validation

`make vm-validate-first-boot` validates a completed libvirt VM install after booting from the installed qcow2 disk.

This workflow is local libvirt test automation. It does not reboot the host and it does not run against real hardware.

## Preconditions

- The VM install completed through the Makefile-mediated flow.
- `var/state/current-install.json` points to a completed run whose last phase is `final-checks`, `install`, or `first-boot-validation`.
- The configured `VM_DISK` is a project-local qcow2 image.
- The installed system has SSH access for `FIRST_BOOT_USER` or `ADMIN_USER`.
- `ADMIN_USER` is set to the installed admin account.

Full validation requires SSH into the installed system. If SSH was not installed or keys were not configured, first-boot validation fails clearly instead of falling back to console automation.

Installed SSH behavior must follow `docs/installed-ssh-policy.md`.

## Run

```sh
make vm-validate-first-boot ADMIN_USER=<admin-user> FIRST_BOOT_USER=<ssh-user>
```

If `FIRST_BOOT_USER` is unset, the wrapper uses `ADMIN_USER`.

The target:

- stops the current project-owned VM if it is running,
- redefines the domain to boot from the installed qcow2 disk while preserving the per-VM OVMF NVRAM file,
- starts the VM without live ISO kernel/initrd boot,
- discovers the libvirt-managed IP address,
- waits for SSH,
- runs read-only Ansible checks against the installed system.

Run `make vm-define` later to restore the official live ISO boot definition.

## Checks

The playbook verifies:

- amd64 architecture,
- UEFI runtime evidence,
- hostname,
- root filesystem type and UUID,
- `/etc/fstab` root UUID entry,
- `/proc/cmdline` `root=UUID=` policy and Btrfs `rootflags=subvol=@` when applicable,
- running kernel,
- NetworkManager status,
- admin user presence,
- time-sync status where practical,
- SSH connectivity through the configured user.

## Evidence

On success, evidence is written to:

```text
logs/install-runs/<run-id>/first-boot/validation.json
```

`make install-report` includes first-boot status when this evidence exists.
`make install-audit` includes the first-boot evidence file in the audit bundle when it exists.

## Failure Modes

- State is not complete: rerun or point `INSTALL_STATE_FILE` at the completed run state.
- SSH timeout: confirm installed SSH was enabled and authorized keys were installed.
- No DHCP lease: inspect the VM console or libvirt network.
- Hostname, UUID, or boot command line mismatch: boot back into the live ISO with `make vm-define && make vm-start`, mount the target, and inspect final-check evidence.

## Recovery

First-boot validation may stop and redefine the disposable project VM, but it must not delete the qcow2 disk. Use `make vm-define` to return to live ISO boot mode for recovery.
