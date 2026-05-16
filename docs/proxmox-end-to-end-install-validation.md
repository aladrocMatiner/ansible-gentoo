# Proxmox End-To-End Install Validation

Proxmox E2E validation runs the same Ansible installer used for network-reachable Gentoo live ISO targets. Proxmox is only the VM harness.

## Single Case

Check the Proxmox environment:

```sh
make proxmox-check
```

Create and start a case:

```sh
make proxmox-vm-create PROFILE=systemd FILESYSTEM=btrfs STAGE3_FLAVOR=musl
make proxmox-vm-start PROFILE=systemd FILESYSTEM=btrfs STAGE3_FLAVOR=musl
```

Bootstrap temporary root SSH inside the live ISO:

```sh
make proxmox-bootstrap-ssh PROFILE=systemd FILESYSTEM=btrfs STAGE3_FLAVOR=musl
make proxmox-ansible-ping PROFILE=systemd FILESYSTEM=btrfs STAGE3_FLAVOR=musl
```

Run the install:

```sh
ADMIN_USER=testadmin \
ENABLE_SSH=yes \
ADMIN_AUTHORIZED_KEYS_FILE=$HOME/.ssh/id_ed25519.pub \
ADMIN_SUDO_NOPASSWD=yes \
ENABLE_QEMU_GUEST_AGENT=yes \
INSTALL_DISK=/dev/sda \
I_UNDERSTAND_THIS_WIPES_DISK=yes \
I_UNDERSTAND_BOOTLOADER_CHANGES=yes \
make proxmox-e2e-install PROFILE=systemd FILESYSTEM=btrfs STAGE3_FLAVOR=musl
```

The target disk in the current Proxmox SCSI setup is `/dev/sda` inside the guest. Do not reuse this value for physical machines. Always run disk detection and pass the explicit disk for the active target.

## Installed-Disk Boot

After an install, boot the VM from the installed disk instead of the live ISO:

```sh
make proxmox-vm-start-installed PROFILE=systemd FILESYSTEM=btrfs STAGE3_FLAVOR=musl
```

This target changes only the Proxmox VM boot configuration for the project-owned VM. It removes the temporary live ISO kernel arguments and sets boot order to `scsi0`.

If recovery through the live ISO is needed:

```sh
make proxmox-vm-start PROFILE=systemd FILESYSTEM=btrfs STAGE3_FLAVOR=musl
```

That restores the live ISO kernel/initrd snippets, ISO media, and live ISO boot order.

## Matrix Run

Run the full 12-case matrix with controlled parallelism:

```sh
ADMIN_USER=testadmin \
ENABLE_SSH=yes \
ADMIN_AUTHORIZED_KEYS_FILE=$HOME/.ssh/id_ed25519.pub \
ADMIN_SUDO_NOPASSWD=yes \
ENABLE_QEMU_GUEST_AGENT=yes \
INSTALL_DISK=/dev/sda \
I_UNDERSTAND_THIS_WIPES_DISK=yes \
I_UNDERSTAND_BOOTLOADER_CHANGES=yes \
I_UNDERSTAND_CLEANUP_DELETE=DELETE \
PROXMOX_MATRIX_PARALLEL=4 \
make proxmox-e2e-matrix
```

The matrix creates or reuses only project-owned VMs for the generated case names. Each case shuts down after a successful install.

`ENABLE_QEMU_GUEST_AGENT=yes` installs `app-emulation/qemu-guest-agent` and enables the matching OpenRC/systemd service in the installed Gentoo guest. `make proxmox-vm-create` also enables the Proxmox guest-agent channel on the VM, so the installed guest service can integrate with Proxmox after first boot. Keep it enabled for Proxmox validation unless you are deliberately testing a non-Proxmox remote target profile.

## Cleanup

Destroy one disposable VM:

```sh
I_UNDERSTAND_CLEANUP_DELETE=DELETE \
make proxmox-vm-clean PROFILE=systemd FILESYSTEM=btrfs STAGE3_FLAVOR=musl
```

Cleanup refuses unrelated VMIDs and requires the expected project marker and generated VM name.

## Failure Modes

- `proxmox-check` fails on ISO: verify `PROXMOX_ISO` points to an existing Proxmox ISO volume, currently `local:iso/<file>.iso`.
- Live ISO SSH fails: rerun `make proxmox-vm-start`, then `make proxmox-bootstrap-ssh`, then `make proxmox-ansible-ping`.
- Install disk is not `/dev/sda`: run disk detection in the live ISO and pass the explicit guest disk. Do not guess.
- A VM boots back into dracut/live ISO after install: run `make proxmox-vm-start-installed` for the same case.
- Package compilation is slow: keep the controller-side command in `tmux` or `screen`; SSH keepalives are already configured by the shared wrapper.

## Boundary

The Proxmox wrapper may create, start, reset, shut down, and destroy disposable project-owned VMs. It must not introduce Proxmox-specific Ansible roles. The Ansible installer remains SSH-driven and reusable for Proxmox VMs, libvirt VMs, and physical network targets.
