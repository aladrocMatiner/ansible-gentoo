# QEMU Manual Install Test

This project can boot the official Gentoo live ISO in a local QEMU VM with a safe qcow2 disk image. The VM is for manually testing the Gentoo installation workflow before using real hardware.

This does not automate the Gentoo installation. It only starts a VM from the official ISO and attaches a virtual disk file.

## ISO Location

Place the official Gentoo live ISO in one of these supported locations:

```text
./gentoo.iso
./gentoo.iso/<official-live-iso-file>.iso
```

`gentoo.iso` is ignored by git because it is a large local release artifact. It may be either a regular ISO file or a directory containing exactly one `.iso` file. If your ISO is stored somewhere else, pass `QEMU_ISO`:

```sh
make qemu-check QEMU_ISO=path/to/install-amd64.iso
```

## Targets

Check host tools, ISO presence, boot mode, and safe paths:

```sh
make qemu-check
```

`make qemu-check` is read-only. It validates tools, ISO resolution, boot mode, firmware availability, and path safety without creating `QEMU_DIR`, disk images, or OVMF vars files.

Create the test disk if it does not already exist:

```sh
make qemu-disk
```

`make qemu-disk` only requires `qemu-img` and safe QEMU disk paths. It does not require `gentoo.iso`, `qemu-system-x86_64`, or OVMF firmware, so the disk can be prepared before the boot prerequisites are complete.

Boot the official live ISO with the qcow2 disk attached:

```sh
make qemu-boot
```

Inside the VM, `/dev/vda` is the expected guest virtual disk for the attached qcow2 image. Treat it as disposable test storage inside the VM only.

Delete generated QEMU artifacts after confirmation:

```sh
make qemu-clean
```

`qemu-clean` prints the files it will delete and requires typing `DELETE`.
Cleanup is limited to the configured `QEMU_DISK` and the generated per-VM OVMF vars file `gentoo-test-OVMF_VARS.fd`. It does not delete unrelated `.qcow2` or `.fd` files that an operator stores under `QEMU_DIR`.

## Defaults

- ISO: `gentoo.iso` as a file, or `gentoo.iso/` as a directory containing exactly one `.iso`
- Disk directory: `var/qemu`
- Disk image: `var/qemu/gentoo-test.qcow2`
- Disk size: `40G`
- RAM: `4096` MB
- CPUs: `2`
- Boot mode: `uefi`
- Network: user-mode NAT
- Display: graphical

BIOS boot is not supported in v1. `QEMU_BOOT_MODE=bios` is rejected so QEMU rehearsals match the UEFI-only installer assumptions.

SSH forwarding, `make qemu-ssh`, and `make qemu-rsync` are planned workflow extensions. They are not implemented yet and should not be documented as available until corresponding Makefile targets exist.

## Safety

The virtual disk is safe because it is a qcow2 file under `./var/qemu/`. The scripts refuse `/dev/*` disk paths and refuse disk images outside the configured QEMU directory.

`QEMU_DIR` must be a project-relative directory. The scripts reject absolute paths, parent traversal, wildcard paths, QEMU option separators such as commas, symlinked directories, symlinked path components, and the project root as the QEMU artifact directory. `QEMU_DISK` must be project-relative and stay under `QEMU_DIR`; it must not contain parent traversal, point under `/dev/`, contain QEMU `-drive` option separators such as commas, use wildcard paths, or be a symlink. The disk image itself must also be a regular qcow2 file, and existing files with a `.qcow2` suffix are rejected unless `qemu-img info` identifies them as qcow2 images.

For UEFI boot, the writable per-VM OVMF vars file is always `QEMU_DIR/gentoo-test-OVMF_VARS.fd`. If that path already exists, it must be a regular file and must not be a symlink. The boot and cleanup flows refuse symlinked or non-regular OVMF vars paths before QEMU can attach them as writable pflash or cleanup can remove them.

If `QEMU_ISO` points to a directory, the boot script accepts it only when the directory contains exactly one `.iso` file. It fails instead of guessing when there are zero or multiple ISO files.

The QEMU targets do not use `sudo` by default and must never operate on host block devices such as `/dev/sda`, `/dev/nvme0n1`, `/dev/vda`, or `/dev/xvda`.

Inside the VM, any disk operations affect the attached qcow2 image, not a host disk.
