# libvirt Manual Install Test

The project uses libvirt/virsh to boot the official Gentoo live ISO in a local VM with a project-local qcow2 disk. This VM is for manual installation testing and future Ansible preparation. It does not install Gentoo automatically.

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

`vm-check` is read-only. It does not create domains, disks, NVRAM files, or artifact directories.

Create the sparse qcow2 disk:

```sh
make vm-disk
```

Define the libvirt domain. The domain boots the official ISO by extracting the official kernel and initrd from the ISO and passing serial console kernel arguments; the ISO remains attached as the live root media.

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

`vm-console` uses `virsh console`. The default VM definition passes `console=tty0 console=ttyS0,115200n8`, so the official live ISO should show boot output and a root shell on the serial console.

Bootstrap SSH access by installing the operator public key into the temporary live ISO and starting `sshd` through the serial console:

```sh
make vm-bootstrap-ssh
```

The target uses `VM_SSH_PUBLIC_KEY` if set. Otherwise it reads `~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`. It writes only the public key into the temporary live ISO session.

SSH, rsync, and Ansible validation are available after SSH is enabled inside the live ISO:

```sh
make vm-ip
make vm-ssh
make vm-rsync
make vm-ansible-ping
```

The default network mode is the libvirt managed `default` network. `make vm-ip` discovers the live ISO address from libvirt DHCP leases. The project does not commit passwords, tokens, or private keys.

Stop or clean the VM:

```sh
make vm-shutdown
make vm-destroy
make vm-clean
```

`vm-destroy` stops only the configured domain. `vm-clean` requires typing `DELETE`; it undefines only the project-owned domain and removes only generated project-local artifacts.

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
- kernel args include `console=tty0 console=ttyS0,115200n8`

BIOS boot is not supported in v1. `VM_BOOT_MODE=bios` is rejected.

## Safety

The VM disk must be a qcow2 file under the configured project-local artifact directory. The scripts reject:

- `/dev/*` disk paths,
- absolute VM disk paths,
- parent traversal,
- project-root artifact directories such as `.`, `./`, and `./.`,
- wildcard paths,
- shell or libvirt option-injection characters,
- symlinked artifact directories,
- symlinked path components,
- existing disk files that are not qcow2.

Generated domains include a project ownership marker. Targets that define, destroy, or clean a domain refuse to operate on an existing domain with the same name unless it is marked as project-owned.

The VM uses UEFI only. Per-VM NVRAM is generated for the domain and must not point to a system firmware template as a writable file.

Inside the VM, `/dev/vda` is the expected guest disk for the attached qcow2 image. Disk operations inside the VM affect that qcow2 file, not a host block device.

## Managed Network Mode

The default `VM_NET_MODE=network` uses the active libvirt `default` network on `qemu:///system`.

Use another managed network explicitly:

```sh
make vm-check VM_NET_MODE=network VM_NETWORK=<network-name>
```

Only use managed network mode when the named libvirt network exists on `LIBVIRT_URI`.

`VM_NET_MODE=user` remains available for experiments, but it does not provide reliable DHCP lease discovery and is not the default because libvirt port forwarding requires a working `passt` backend on the host.

## Legacy QEMU Targets

The direct QEMU workflow is no longer the active operator-facing VM workflow. Legacy `qemu-*` Makefile targets are compatibility aliases that call the libvirt `vm-*` targets.
