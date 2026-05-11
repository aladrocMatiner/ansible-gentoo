# libvirt Manual Install Test

The project uses libvirt/virsh to boot the official Gentoo live ISO in a local VM with a project-local qcow2 disk. This VM is the local validation harness for manual installation testing and Ansible workflow testing. It is not the final installer architecture and it does not install Gentoo automatically.

## ISO Location

Place the official Gentoo live ISO in one of these supported locations:

```text
./gentoo.iso
./gentoo.iso/<official-live-iso-file>.iso
```

`gentoo.iso` is ignored by git because it is a large local release artifact. If your ISO is somewhere else, pass `VM_ISO=path/to/file.iso`.

## Targets

Validate tools, libvirt connectivity, ISO resolution, UEFI firmware, network mode, and path safety:

```sh
make vm-check
```

`vm-check` is read-only. It does not create domains, disks, NVRAM files, or artifact directories. It verifies OVMF/UEFI firmware is available and refuses an existing project domain that is not configured for OVMF UEFI boot.

`vm-start` validates ISO resolution, UEFI firmware, libvirt networking, and path safety before it creates a missing disk or defines a missing domain. If those prerequisites are unavailable, it fails without creating new VM artifacts. When a matching inactive domain already exists, `vm-start` also verifies that the configured qcow2 disk, per-VM NVRAM, extracted kernel, and extracted initrd are present before asking libvirt to start it.

Create the sparse qcow2 disk:

```sh
make vm-disk
```

Define the libvirt domain. The domain uses OVMF UEFI firmware with a per-VM NVRAM file under `./var/libvirt/`, boots the official ISO by extracting the official kernel and initrd from the ISO, and passes serial console kernel arguments; the ISO remains attached as the live root media.

```sh
make vm-define
```

Start the VM:

```sh
make vm-start
```

Access the VM:

```sh
make vm-console
make vm-viewer
```

`vm-console` uses `virsh console`. The default VM definition passes `console=tty0 console=ttyS0,115200n8`, so the official live ISO should show boot output and a root shell on the serial console. The kernel command line uses the `__VM_ISO_LABEL__` placeholder by default; `vm-define` resolves it from the selected ISO volume id before writing the domain XML.

Bootstrap SSH access by installing the operator public key into the temporary live ISO and starting `sshd` through the serial console:

```sh
make vm-bootstrap-ssh
```

The target uses `VM_SSH_PUBLIC_KEY` if set. Otherwise it reads `~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`. It writes only the public key into the temporary live ISO session.

`vm-bootstrap-ssh` refuses to operate unless the configured libvirt domain is marked as project-owned, running, UEFI-configured, and still matches the generated project artifacts. The public key must be a single-line OpenSSH public key with supported key type and encoded key material; private keys, multiline values, and malformed key text are rejected.

SSH, rsync, and Ansible validation are available after SSH is enabled inside the live ISO:

```sh
make vm-ip
make vm-ssh
make vm-rsync
make vm-ansible-ping
make ansible-live-ping
make ansible-live-preflight
make detect-disks
make install-plan PROFILE=openrc
make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

The default network mode is the libvirt managed `default` network. `make vm-ip` discovers the live ISO address from libvirt domain interface data or DHCP leases filtered by the configured domain MAC address. The project does not commit passwords, tokens, or private keys.

`make vm-ssh`, `make vm-rsync`, and the Ansible live ISO wrappers treat SSH host keys as temporary live-session keys. They disable strict host-key persistence for these VM-only connections and keep the global `ansible.cfg` host-key policy unchanged.

`make vm-rsync` copies the repository to `/root/gentoo-ai-installer/` by default. If `VM_RSYNC_DEST` is overridden, it must remain under `/root/gentoo-ai-installer/`; this prevents `rsync --delete` from targeting unrelated guest paths. The rsync filter excludes `.env`, `.ssh`, private key patterns, token/credential files, ISO artifacts, runtime artifacts, logs, and temporary files.

`make ansible-live-ping` and `make ansible-live-preflight` are the first project Ansible handoff targets. In this VM workflow, they use the local libvirt target discovered by the wrappers. In the reusable network workflow, pass `ANSIBLE_LIVE_HOST=...` to target a non-libvirt live ISO. They validate SSH connectivity, root access, global IP addressing, default route, DNS, clock sanity, UEFI evidence, and read-only live ISO facts. They do not install Gentoo, select an install disk, partition, format, mount target filesystems, or modify `/dev/vda`.

`make detect-disks` and `make install-plan` are also read-only. To plan against the VM disk, pass it deliberately:

```sh
make install-plan PROFILE=openrc INSTALL_DISK=/dev/vda
```

This matches `/dev/vda` against live ISO disk inventory only; it does not write to the qcow2 disk.

The next read-only checkpoint is the partition plan:

```sh
make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make partition-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

These targets report the exact GPT layout a future destructive target would apply. They do not partition or format the qcow2 disk.

Stop or clean the VM:

```sh
make vm-shutdown
make vm-destroy
make vm-clean
```

`vm-shutdown` requests a clean guest shutdown. `vm-destroy` forcibly stops only the configured domain and is a no-op when that domain is already inactive. `vm-clean` requires typing `DELETE`; it undefines only the project-owned domain and removes only generated project-local artifacts.

After a completed automated VM install, `make vm-validate-first-boot ADMIN_USER=<admin-user>` redefines the project domain to boot from the installed qcow2 disk and runs read-only installed-system checks over SSH. Run `make vm-define` afterward to restore official live ISO boot mode.

## Defaults

- libvirt URI: `qemu:///system`
- VM name: `gentoo-ai-installer`
- ISO: `gentoo.iso`
- artifact directory: `var/libvirt`
- disk: `var/libvirt/gentoo-ai-installer.qcow2`
- disk size: `40G` using a simple `qemu-img` size value such as `64M` or `40G`
- RAM: `4096` MB
- CPUs: `2`
- boot mode: `uefi`
- network mode: `network`
- libvirt network: `default`
- SSH user: `root`
- kernel args include the ISO-derived `root=live:CDLABEL=<iso-volume-id>` and `console=tty0 console=ttyS0,115200n8`

BIOS boot is not supported in v1. `VM_BOOT_MODE=bios` is rejected.

## Safety

The VM disk must be a qcow2 file under the configured project-local artifact directory. The scripts reject:

- `/dev/*` disk paths,
- absolute VM disk paths,
- parent traversal,
- project-root artifact directories such as `.`, `./`, and `./.`,
- wildcard paths,
- shell or libvirt option-injection characters,
- XML-special characters in the project root path that would make generated libvirt XML unsafe,
- symlinked artifact directories,
- symlinked path components,
- existing disk files that are not qcow2.

Generated domains include a project ownership marker. Targets that start, inspect, SSH into, rsync to, or bootstrap SSH in a domain refuse to operate on an existing domain with the same name unless it is marked as project-owned and matches the configured official ISO plus generated artifacts: `VM_ISO`, `VM_DISK`, per-VM NVRAM, extracted kernel, extracted initrd, and artifact directory metadata. Existing domains that reference `/dev/*` or libvirt block devices are rejected even if they carry the marker.

Cleanup, forced stop, clean shutdown, and redefinition may operate on stale project-marked domains only to remove or replace them, and only when the domain does not reference host block devices. This allows safe recovery from older project-generated domain XML while still refusing unrelated domains and host disk attachments.

SSH bootstrap uses the same ownership and artifact boundary: it must not open a console or write `authorized_keys` in an unrelated or stale libvirt domain with the same `VM_NAME`.

The VM uses UEFI only. `vm-check` must find OVMF code and vars firmware before the VM is defined. Per-VM NVRAM is generated for the domain under `./var/libvirt/nvram/` and must not point to a system firmware template as a writable file.

If a project VM was defined before OVMF support was added, `vm-check`, `vm-start`, SSH bootstrap, and SSH target discovery refuse to use it. Stop it with `make vm-destroy` if needed, then regenerate the domain with `make vm-define` before continuing. Redefinition recreates the per-VM NVRAM file after any `virsh undefine --nvram` cleanup.

Inside the VM, `/dev/vda` is the expected guest disk for the attached qcow2 image. Disk operations inside the VM affect that qcow2 file, not a host block device.

## Managed Network Mode

The default `VM_NET_MODE=network` uses the active libvirt `default` network on `qemu:///system`.

Use another managed network explicitly:

```sh
make vm-check VM_NET_MODE=network VM_NETWORK=<network-name>
```

Only use managed network mode when the named libvirt network exists on `LIBVIRT_URI`.

`VM_NET_MODE=user` remains available for experiments, but it does not provide reliable DHCP lease discovery and is not the default because libvirt port forwarding requires a working `passt` backend on the host. SSH and rsync targets still require the configured libvirt domain to be project-owned, UEFI-configured, and running before connecting to the configured endpoint.

## Legacy QEMU Targets

The direct QEMU workflow is no longer the active operator-facing VM workflow. Legacy `qemu-*` Makefile targets are compatibility aliases that call the libvirt `vm-*` targets.
