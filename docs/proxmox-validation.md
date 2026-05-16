# Proxmox Validation Harness

The Proxmox targets create and operate project-owned disposable VMs for validating the same Ansible installer used against network-reachable Gentoo live ISO targets.

The selected case is derived from fixed platform `amd64`, `PROFILE`, `FILESYSTEM`, `STAGE3_FLAVOR`, and optional `VM_TEST_IMAGE_NAME`. Use `make proxmox-list-cases` before creating or operating VMs to inspect VMIDs, names, IPs, storage, bridge, VLAN, and the expected install disk.

See `docs/proxmox-install-test-matrix.md` for the full 12-case matrix and `docs/proxmox-end-to-end-install-validation.md` for single-case and matrix E2E install commands.

## Targets

- `make proxmox-check` verifies controller SSH access to Proxmox, required Proxmox tools, storage, bridge, and ISO path. It is read-only.
- `make proxmox-vm-create PROFILE=... FILESYSTEM=... STAGE3_FLAVOR=...` creates one project-owned VM that boots the official Gentoo live ISO through extracted kernel/initrd snippets.
- `make proxmox-vm-create-all` creates all supported matrix VMs.
- `make proxmox-vm-start` configures one VM for live ISO mode, including ISO media, boot order, and temporary kernel arguments, then starts it. If the VM is already running, it stops and starts the VM so live ISO media changes take effect.
- `make proxmox-vm-start-installed` switches one project-owned VM to boot from installed disk `scsi0`, detaches the live ISO media, deletes the temporary live ISO kernel arguments, and starts it. If the VM is already running, it stops and starts the VM so disk boot and ISO-detach changes take effect.
- `make proxmox-vm-start-installed-all` switches all project-owned matrix VMs to boot from installed disk `scsi0`.
- `make proxmox-ensure-installed-access` boots one project-owned VM through the live ISO, mounts the installed target, ensures `ADMIN_USER` exists with sudo privileges, installs the controller public key into `authorized_keys`, enables installed `sshd`, configures the deterministic Proxmox IP, boots the installed disk, and verifies SSH plus passwordless sudo. For OpenRC targets it also installs `local.d` and `inittab` fallbacks that start `sshd` if normal service ordering does not leave it listening.
- `make proxmox-ensure-installed-access-all` runs the installed-access workflow for all supported Proxmox matrix VMs. It defaults to `ADMIN_USER=aladroc`, `ADMIN_AUTHORIZED_KEYS_FILE=~/.ssh/id_ed25519.pub`, and `PROXMOX_ACCESS_INSTALL_DISK=/dev/sda`.
- `make proxmox-verify-installed-access` verifies SSH and passwordless sudo for one installed Proxmox VM.
- `make proxmox-verify-installed-access-all` verifies SSH and passwordless sudo for all installed Proxmox matrix VMs.
- `make proxmox-vm-ip` prints the deterministic case IP.
- `make proxmox-bootstrap-ssh` configures temporary root SSH inside the live ISO through the Proxmox serial terminal.
- `make proxmox-ansible-ping` validates Ansible SSH to the live ISO target.
- `make proxmox-e2e-install` runs a destructive install inside the selected disposable VM.
- `make proxmox-e2e-matrix` runs the destructive install matrix.
- `make proxmox-vm-shutdown` requests a clean guest shutdown.
- `make proxmox-vm-clean I_UNDERSTAND_CLEANUP_DELETE=DELETE` destroys only the matching project-owned VM.

## Variables

Defaults are shown by `make help`.

- `PROXMOX_HOST`, `PROXMOX_NODE`, `PROXMOX_STORAGE`, `PROXMOX_BRIDGE`, and `PROXMOX_VLAN` select the Proxmox target environment.
- `PROXMOX_ISO` points to the official Gentoo live ISO on Proxmox storage and must currently use `local:iso/<file>.iso`.
- `PROXMOX_VMID_BASE` plus the selected matrix case derives VMIDs unless `PROXMOX_VMID` is set.
- `PROXMOX_IP_BASE`, `PROXMOX_GATEWAY`, `PROXMOX_NETMASK`, and `PROXMOX_DNS` define deterministic live ISO networking.
- `PROXMOX_DISK_SIZE`, `PROXMOX_RAM`, and `PROXMOX_CPUS` define disposable VM resources.
- `ADMIN_USER`, `ADMIN_AUTHORIZED_KEYS_FILE`, `ENABLE_SSH`, and `ADMIN_SUDO_NOPASSWD` are passed into E2E installs. Proxmox installed-access repair defaults empty `ADMIN_USER` to `aladroc` and empty `ADMIN_AUTHORIZED_KEYS_FILE` to `~/.ssh/id_ed25519.pub`.
- `ENABLE_QEMU_GUEST_AGENT` defaults to `yes` for Proxmox E2E installs so the installed Gentoo guest integrates with Proxmox through `qemu-guest-agent`.
- `INSTALL_DISK` is still required for E2E installs. The current Proxmox SCSI setup uses `/dev/sda` inside the guest, but the value must remain explicit.
- `PROXMOX_ACCESS_INSTALL_DISK` defaults to `/dev/sda` for installed-access repair. It is used only to mount the existing installed target from the live ISO and must be `/dev/sda` or `/dev/vda`.

## Safety And Failure Modes

Proxmox cleanup and E2E install targets require explicit confirmations because they can destroy data inside project-owned disposable VMs. They must not be pointed at non-project VMs; the script checks the VM name and project marker before shutdown, installed-disk boot switching, and cleanup.

When `ENABLE_QEMU_GUEST_AGENT=yes`, the shared installer installs `app-emulation/qemu-guest-agent` and enables `qemu-guest-agent` for OpenRC or `qemu-guest-agent.service` for systemd. `make proxmox-vm-create` and `make proxmox-vm-create-all` also enable the Proxmox guest-agent channel on project-owned VMs with `qm set <vmid> --agent enabled=1`, including existing project-owned VMs that are preserved instead of recreated. This is Proxmox validation integration, not a requirement for physical installs.

Installed-access repair is persistent target mutation. It does not partition, format, wipe, install GRUB, or delete disks, but it changes the installed OS user database, sudoers policy, SSH host keys, admin authorized keys, NetworkManager connection profile, OpenRC SSH fallbacks when applicable, and init service enablement. It refuses private key material and uses only the selected public SSH key. Run it only on project-owned disposable Proxmox VMs.

If a VM shows dracut live ISO messages or a `root@livecd` prompt after an E2E install, check whether it is still configured with live ISO kernel arguments or attached ISO media. Use `make proxmox-vm-start-installed PROFILE=... FILESYSTEM=... STAGE3_FLAVOR=...` to detach live ISO media and boot the installed disk. This target changes Proxmox VM boot configuration and may reset a running VM, but it does not partition, format, or modify the guest disk contents.

If installed-disk boot needs recovery through the live ISO, use `make proxmox-vm-start PROFILE=... FILESYSTEM=... STAGE3_FLAVOR=...` to restore live ISO boot configuration and reset the VM into the live environment.
