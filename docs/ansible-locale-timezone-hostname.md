# Ansible Locale, Timezone, and Hostname

`make configure-system` configures the target system identity and console locale basics inside `/mnt/gentoo`.

It runs from the operator machine over SSH into the official Gentoo live ISO target. It does not install packages, create users, enable services, install a kernel, install a bootloader, or change the live ISO hostname.

## Required State

Run the earlier target setup first:

```sh
make mount-target PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make stage3-install PROFILE=openrc FILESYSTEM=btrfs
make prepare-chroot PROFILE=openrc FILESYSTEM=btrfs
make configure-portage PROFILE=openrc FILESYSTEM=btrfs
```

For a real network target, pass `ANSIBLE_LIVE_HOST=...` and use the disk selected from that target's own `make detect-disks` output.

## Command

```sh
make configure-system PROFILE=openrc HOSTNAME=gentoo TIMEZONE=UTC LOCALE=en_US.UTF-8 KEYMAP=us
```

For systemd:

```sh
make configure-system PROFILE=systemd HOSTNAME=gentoo TIMEZONE=UTC LOCALE=en_US.UTF-8 KEYMAP=us
```

## Variables

| Variable | Default | Meaning |
| --- | --- | --- |
| `HOSTNAME` | `gentoo` | Target hostname written under `/mnt/gentoo`. |
| `TIMEZONE` | `UTC` | Target zoneinfo path, for example `UTC` or `Europe/Stockholm`. |
| `LOCALE` | `en_US.UTF-8` | Target UTF-8 locale written to `locale.gen` and `02locale`. |
| `KEYMAP` | `us` | Console keymap written to OpenRC or systemd console config. |

## Behavior

The shared role:

- verifies the live ISO target and prepared chroot,
- refuses target roots other than `/mnt/gentoo`,
- validates hostname, timezone, locale, and keymap syntax,
- verifies the timezone and keymap exist inside the target root,
- installs `sys-libs/timezone-data` in the target root when a minimal stage3 is missing the selected timezone,
- writes `/mnt/gentoo/etc/hostname`,
- writes `/mnt/gentoo/etc/conf.d/hostname` for OpenRC,
- links `/mnt/gentoo/etc/localtime` to the target zoneinfo path,
- writes `/mnt/gentoo/etc/locale.gen`,
- writes `/mnt/gentoo/etc/env.d/02locale`,
- runs `locale-gen` only when `locale.gen` changes and the target stage3 provides `/usr/sbin/locale-gen`; musl stage3 variants may not provide that helper,
- runs `env-update` only when the locale environment changes,
- writes `/mnt/gentoo/etc/conf.d/keymaps` for OpenRC,
- writes `/mnt/gentoo/etc/vconsole.conf` for systemd,
- records evidence under `logs/install-runs/<run-id>/system-config/`.

## Final Checks and Reports

The evidence file includes hostname, timezone, locale, whether `locale-gen` was available, keymap, and whether locale generation or env update ran. Later final-check and install-report changes should consume this evidence instead of rediscovering the same state inconsistently.

## Safety

The workflow must not change the live ISO hostname or local controller configuration. All writes are scoped to `/mnt/gentoo`.

If `TIMEZONE`, `LOCALE`, or `KEYMAP` are invalid, the workflow fails before writing partial configuration. If the selected timezone is valid but the target stage3 lacks zoneinfo data, the workflow installs `sys-libs/timezone-data` inside `/mnt/gentoo` and validates the timezone path again.

## Recovery

If timezone validation fails, confirm `sys-libs/timezone-data` can be installed in the target and choose a path that exists under target `/usr/share/zoneinfo`.

If keymap validation fails, inspect target `/usr/share/keymaps` and rerun with a supported keymap.

If locale generation fails on a glibc target, inspect `/mnt/gentoo/etc/locale.gen`, target chroot mounts, and `/mnt/gentoo/etc/resolv.conf`, then rerun `make configure-system`. If a musl target lacks `/usr/sbin/locale-gen`, that is expected; the role still writes `locale.gen` and `02locale` and records that generation was skipped.
