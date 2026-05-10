# Design: implement-libvirt-end-to-end-install-validation

## Test Flow
1. Ensure ISO exists.
2. Create or reset qcow2 with confirmation.
3. Boot live ISO.
4. Bootstrap SSH.
5. Run installer.
6. Shutdown/reboot into disk.
7. Validate boot and network.

## Safety
All VM storage remains under `var/libvirt/`. Cleanup requires explicit confirmation.
