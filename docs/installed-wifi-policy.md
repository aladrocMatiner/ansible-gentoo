# Installed WiFi Policy

Installed WiFi support is optional and controlled by `ENABLE_WIFI`.

This policy installs the packages and USE flags required for a target system to manage WiFi after installation. It does not configure a wireless network, does not write `.nmconnection` files, and must never store SSIDs or passphrases in the repository, logs, state files, or OpenSpec artifacts.

## Policy

- `ENABLE_WIFI=no` is the default.
- `ENABLE_WIFI=yes` installs WiFi firmware and supplicant support in the target root.
- WiFi package selection is shared for OpenRC and systemd.
- Init-specific roles still only manage services; they must not duplicate WiFi package logic.
- NetworkManager remains the installed network manager.
- WiFi credentials are an operator/runtime concern after the installed system boots.

## Packages

When `ENABLE_WIFI=yes`, `make install-system-packages` adds:

- `sys-kernel/linux-firmware`
- `net-wireless/wpa_supplicant`

The target package USE policy must build:

- `net-misc/networkmanager` with `wifi`
- `net-wireless/wpa_supplicant` with `dbus`

Legacy `tkip` and `wep` flags remain disabled unless a future OpenSpec change explicitly approves them.

## Commands

Install package support during the system package phase:

```sh
make install-system-packages PROFILE=systemd FILESYSTEM=btrfs ENABLE_WIFI=yes
```

Run the full install with WiFi support:

```sh
make install-systemd \
  FILESYSTEM=btrfs \
  INSTALL_DISK=/dev/disk/by-id/<target-disk> \
  ADMIN_USER=<admin-user> \
  ENABLE_WIFI=yes \
  I_UNDERSTAND_THIS_WIPES_DISK=yes \
  I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

Run final checks with the same option:

```sh
make final-checks PROFILE=systemd FILESYSTEM=btrfs ADMIN_USER=<admin-user> ENABLE_WIFI=yes
```

For libvirt or Proxmox disposable VM validation, keep using the VM-specific explicit guest disk path required by that harness.

## Validation

Successful package installation evidence must include:

- `enable_wifi: true`,
- `sys-kernel/linux-firmware`,
- `net-wireless/wpa_supplicant`,
- NetworkManager package USE containing `wifi`,
- wpa_supplicant package USE containing `dbus`.

Final checks must fail when `ENABLE_WIFI=yes` and the requested packages or USE policy are missing.

## Failure Modes

- `ENABLE_WIFI` is not `yes` or `no`: rerun with a valid value.
- Firmware package is unavailable from the configured repo state: rerun `make configure-portage`, inspect Portage sync status, then rerun `make install-system-packages ENABLE_WIFI=yes`.
- NetworkManager was built without `wifi`: rerun `make install-system-packages ENABLE_WIFI=yes` so `--changed-use` can rebuild it.
- wpa_supplicant was built without `dbus`: rerun `make install-system-packages ENABLE_WIFI=yes`.
- WiFi connects poorly after reboot: confirm hardware firmware availability and configure the network interactively on the installed system; do not commit wireless credentials.

## Recovery

If WiFi support was omitted, rerun:

```sh
make install-system-packages ENABLE_WIFI=yes
make final-checks ADMIN_USER=<admin-user> ENABLE_WIFI=yes
```

If a wireless connection profile is needed after first boot, create it on the installed host through NetworkManager tooling. Keep passphrases out of project files and logs.

## Output Artifacts

- `/mnt/gentoo/etc/portage/package.use/gentoo-ai-installer-system`
- `logs/install-runs/<run-id>/system-packages/packages-services.json`
- `logs/install-runs/<run-id>/final-checks/reboot-readiness.json`

## Documentation Maintenance

When WiFi package policy, USE flags, validation, or credential-handling rules change, update this document, `docs/ansible-system-packages-and-services.md`, `docs/target-system-baseline.md`, `skills/ansible-gentoo-installer.md`, `skills/makefile-control-plane.md`, and the active OpenSpec tasks in the same change.
