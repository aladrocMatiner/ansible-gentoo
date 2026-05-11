# Design: implement-libvirt-end-to-end-install-validation

## Test Flow
1. Run `make vm-e2e-plan` to validate selected profile/filesystem, explicit `/dev/vda`, `ADMIN_USER`, and matrix coverage without VM mutation.
2. Ensure ISO exists through the existing `vm-check` path.
3. Create or reset qcow2 with confirmation when requested.
4. Boot live ISO.
5. Bootstrap SSH.
6. Run installer through the shared basic-console install wrapper.
7. Request clean live ISO shutdown so the target filesystems are flushed and unmounted before installed-disk boot.
8. Start the installed qcow2 disk.
9. Validate first boot and network.
10. Generate or reference audit evidence.

## Safety
All VM storage remains under `var/libvirt/`. Cleanup requires explicit confirmation.

`make vm-e2e-install` requires explicit `INSTALL_DISK=/dev/vda`, `ADMIN_USER`, `ENABLE_SSH=yes`, `ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file>`, `I_UNDERSTAND_THIS_WIPES_DISK=yes`, and `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`. If `VM_E2E_RESET_DISK=yes`, it also requires `I_UNDERSTAND_CLEANUP_DELETE=DELETE`.

The workflow is destructive only inside the disposable project-owned VM qcow2 disk. Host block devices remain forbidden.

First-boot handoff must fail closed if the live ISO VM cannot shut down cleanly. It must not hard-destroy a running live installer and immediately boot the installed disk, because that can leave recently written boot files invisible to GRUB on ext4.
