# QEMU Manual Install Test

This document is retained only as a migration note.

The project no longer uses direct `qemu-system-x86_64` as the operator-facing VM workflow. The active VM workflow is libvirt/virsh and is documented in:

```text
docs/libvirt-manual-install-test.md
```

Compatibility Makefile targets remain:

```sh
make qemu-check
make qemu-disk
make qemu-boot
make qemu-clean
```

These aliases call the corresponding libvirt `vm-*` targets. New operator instructions should use:

```sh
make vm-check
make vm-disk
make vm-define
make vm-start
make vm-console
make vm-viewer
make vm-ssh
make vm-rsync
make vm-clean
```

The safety model remains the same: use the official Gentoo live ISO, keep VM disks as project-local qcow2 files, reject host block devices, require UEFI, and never automate the Gentoo installation from the VM boot workflow.
