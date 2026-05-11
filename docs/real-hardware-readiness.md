# Real Hardware Readiness

Real hardware installation is higher risk than libvirt testing because destructive targets can erase physical disks. Run the readiness check before any destructive Makefile target against a physical machine.

This check is read-only. It writes a local report under `logs/real-hardware-readiness/latest.json`, and it does not satisfy `I_UNDERSTAND_THIS_WIPES_DISK=yes` or `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`.

## Run

Boot the official Gentoo live ISO on the target machine, enable SSH, and verify the target first:

```sh
make ansible-live-preflight ANSIBLE_LIVE_HOST=<live-iso-ip>
make detect-disks ANSIBLE_LIVE_HOST=<live-iso-ip>
make install-plan ANSIBLE_LIVE_HOST=<live-iso-ip> PROFILE=openrc FILESYSTEM=ext4
make partition-preview ANSIBLE_LIVE_HOST=<live-iso-ip> INSTALL_DISK=/dev/disk/by-id/<operator-selected-disk>
```

Then run the readiness check:

```sh
make real-hardware-check \
  ANSIBLE_LIVE_HOST=<live-iso-ip> \
  INSTALL_DISK=/dev/disk/by-id/<operator-selected-disk> \
  REAL_HARDWARE_BACKUPS_CONFIRMED=yes \
  REAL_HARDWARE_UEFI_CONFIRMED=yes \
  REAL_HARDWARE_NETWORK_CONFIRMED=yes \
  REAL_HARDWARE_POWER_CONFIRMED=yes \
  REAL_HARDWARE_RECOVERY_MEDIA_CONFIRMED=yes \
  REAL_HARDWARE_DESTRUCTIVE_PREVIEW_REVIEWED=yes \
  REAL_HARDWARE_LIBVIRT_VALIDATED=yes
```

If matching libvirt validation is not practical, the operator must explicitly record why:

```sh
make real-hardware-check \
  ANSIBLE_LIVE_HOST=<live-iso-ip> \
  INSTALL_DISK=/dev/disk/by-id/<operator-selected-disk> \
  REAL_HARDWARE_BACKUPS_CONFIRMED=yes \
  REAL_HARDWARE_UEFI_CONFIRMED=yes \
  REAL_HARDWARE_NETWORK_CONFIRMED=yes \
  REAL_HARDWARE_POWER_CONFIRMED=yes \
  REAL_HARDWARE_RECOVERY_MEDIA_CONFIRMED=yes \
  REAL_HARDWARE_DESTRUCTIVE_PREVIEW_REVIEWED=yes \
  REAL_HARDWARE_LIBVIRT_SKIP_REASON="Hardware-specific driver test; libvirt matrix does not cover this device"
```

## Required Checks

The target requires:

- valid installer configuration through `make config-check`,
- `ANSIBLE_LIVE_HOST` set to the network-reachable official live ISO target,
- explicit `INSTALL_DISK`,
- UEFI boot mode,
- backups confirmed,
- live ISO network/SSH stability confirmed,
- stable power confirmed,
- recovery media available,
- destructive preview reviewed,
- matching libvirt validation completed or an explicit skip reason recorded.

Prefer stable disk paths such as `/dev/disk/by-id/...`. Generic paths such as `/dev/sda` or `/dev/nvme0n1` are warnings because they can change across boots. VM example paths such as `/dev/vda` and `/dev/xvda` are rejected for real hardware readiness.

## Report

The report contains:

- profile and filesystem,
- whether `ANSIBLE_LIVE_HOST` is set,
- selected disk path,
- readiness acknowledgements,
- libvirt validation status,
- warnings and errors.

The report is project-local and ignored by git. It must not contain credentials, tokens, password hashes, private keys, or local secrets.

## Relationship To Destructive Targets

`make real-hardware-check` is a readiness checkpoint, not an authorization token. Before a destructive target, the operator must still run the relevant read-only preview and pass the normal confirmations:

```sh
make partition \
  ANSIBLE_LIVE_HOST=<live-iso-ip> \
  INSTALL_DISK=/dev/disk/by-id/<operator-selected-disk> \
  I_UNDERSTAND_THIS_WIPES_DISK=yes
```

Bootloader work still requires:

```sh
I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

## Failure Modes

- Missing `ANSIBLE_LIVE_HOST`: set the live ISO target IP or hostname.
- Missing `INSTALL_DISK`: rerun `make detect-disks` and choose the exact target disk.
- Generic disk path warning: prefer `/dev/disk/by-id/...` if available in the live ISO.
- VM disk example rejected: do not use `/dev/vda` or `/dev/xvda` for physical hardware.
- Missing acknowledgement: set the relevant `REAL_HARDWARE_*` variable only after verifying the condition.
- Missing libvirt validation: run the matching libvirt workflow or provide a non-secret skip reason.

## Recovery

If readiness fails, do not proceed to destructive targets. Fix the reported issue, rerun `make ansible-live-preflight`, rerun the relevant preview, and then run `make real-hardware-check` again.
