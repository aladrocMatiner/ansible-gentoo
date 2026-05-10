## Why

Final checks before reboot are necessary, but they do not prove the installed system can boot from disk, get network, and accept management connections.

## What Changes

- Add libvirt-only first-boot validation after a completed VM install.
- Boot the VM from the installed qcow2 disk without relying on the live ISO as the primary boot path.
- Validate boot, networking, optional SSH access, admin user presence, NetworkManager status, root filesystem UUID, and basic system identity.
- Validate installed time sync status and boot command line root behavior where practical.
- Keep validation read-only inside the installed system.

## Capabilities

### New Capabilities
- `first-boot-validation`: Validates a completed libvirt install can boot and be reached after reboot.

### Modified Capabilities

## Impact

- Libvirt end-to-end validation.
- Final checks and audit bundle output.
- Future Makefile targets and docs.
