# Design: implement-first-boot-validation

## Validation Scope

First-boot validation is for libvirt VM tests, not host reboot automation.

The workflow should verify:

- VM boots from installed disk,
- live ISO is not the primary boot device,
- expected kernel is running,
- root filesystem UUID matches generated fstab,
- NetworkManager is active,
- hostname matches configured value,
- admin user exists,
- SSH works if enabled,
- final boot logs show no obvious boot-critical failures.

## Safety

- Do not reboot the host.
- Do not mutate the installed system beyond any explicitly required login/session artifacts.
- Do not require real hardware.
- Use project-local libvirt domains and qcow2 disks only.

## Makefile Integration

Planned target:

- `make vm-validate-first-boot`

This target must depend on a completed VM install state and must fail clearly if no installed VM disk is available.
