# Install Configuration

`make config-check` validates operator-provided installer variables before any live ISO, disk, or target-root workflow runs. It is read-only and host-only: it does not connect over SSH, inspect disks, create filesystems, mount paths, or modify libvirt.

The machine-readable schema lives at `config/install-schema.yml`.

## Run

Validate defaults:

```sh
make config-check
```

Validate a planned remote target configuration:

```sh
make config-check PROFILE=openrc FILESYSTEM=ext4 BOOT_MODE=uefi HOSTNAME=gentoo
```

Validate a disk-aware future apply configuration without making changes:

```sh
make config-check CONFIG_REQUIRE_INSTALL_DISK=yes INSTALL_DISK=/dev/vda
```

Validate destructive confirmations before a future destructive target calls the same guard:

```sh
make config-check CONFIG_DESTRUCTIVE=yes INSTALL_DISK=/dev/vda I_UNDERSTAND_THIS_WIPES_DISK=yes
```

`/dev/vda` is only an example for the local libvirt guest. For real hardware or a remote VM, use the disk path reported by `make detect-disks ANSIBLE_LIVE_HOST=...`.

## Variables

| Makefile variable | Default | Rule |
| --- | --- | --- |
| `PROFILE` | `openrc` | Must be `openrc` or `systemd`. |
| `FILESYSTEM` | `ext4` | Must be `ext4` or `btrfs`. |
| `STAGE3_MIRROR` | `https://distfiles.gentoo.org/releases/amd64/autobuilds` | Must be an HTTPS base URL for Gentoo stage3 metadata. |
| `STAGE3_CACHE_DIR` | `/tmp/gentoo-ai-installer/stage3` | Must be an absolute live-ISO-local path outside `TARGET_MOUNT`. |
| `PORTAGE_GENTOO_MIRRORS` | `https://distfiles.gentoo.org` | Must be an HTTPS Gentoo distfiles mirror URL written to target `make.conf`. |
| `BOOT_MODE` | `uefi` | Must be `uefi`; BIOS is outside v1 scope. |
| `HOSTNAME` | `gentoo` | Must be a simple Linux hostname. |
| `TIMEZONE` | `UTC` | Must be a relative path under target `/usr/share/zoneinfo`, such as `UTC` or `Europe/Stockholm`. |
| `LOCALE` | `en_US.UTF-8` | Must be a UTF-8 locale generated inside the target. |
| `KEYMAP` | `us` | Must be a simple console keymap name available in target `/usr/share/keymaps`. |
| `ADMIN_USER` | unset | Optional; must be a conservative local username when set. |
| `ADMIN_GROUPS` | `wheel` | Comma-separated target groups for the admin user. |
| `ADMIN_SHELL` | `/bin/bash` | Absolute target shell path for the admin user. |
| `PRIVILEGE_TOOL` | `sudo` | Current implementation supports `sudo`; doas requires a later change. |
| `ADMIN_AUTHORIZED_KEYS_FILE` | unset | Optional local gitignored file used by `make configure-users`; the path is reported as set/unset only. |
| `ADMIN_PASSWORD_HASH_FILE` | unset | Optional local gitignored file containing one encrypted admin password hash. |
| `ROOT_PASSWORD_HASH_FILE` | unset | Optional local gitignored file containing one encrypted root password hash. |
| `ENABLE_SSH` | `no` | Must be `yes` or `no`. |
| `TARGET_MOUNT` | `/mnt/gentoo` | Must be an absolute path and must not be `/`. |
| `EFI_MOUNT` | `/mnt/gentoo/boot/efi` | Must be below `TARGET_MOUNT`. |
| `INSTALL_DISK` | no default | Must be explicit when required; never defaults. |
| `I_UNDERSTAND_THIS_WIPES_DISK` | no default | Must be `yes` only for destructive workflows that require it. |
| `I_UNDERSTAND_BOOTLOADER_CHANGES` | no default | Must be `yes` for `make install-bootloader`, which may update EFI boot entries. |

## Failure Modes

- `CONFIG_INVALID`: an unsupported value, invalid hostname, invalid username, or unsafe mount path was provided.
- `UNSUPPORTED_CONFIGURATION`: the configuration requests behavior outside v1 scope, such as BIOS boot.
- `DISK_UNSAFE`: `INSTALL_DISK` is missing when required or contains unsafe syntax.
- `DESTRUCTIVE_CONFIRMATION_MISSING`: a destructive workflow did not provide `I_UNDERSTAND_THIS_WIPES_DISK=yes`.
- `SECRET_LEAK_RISK`: a schema variable or forbidden password/private-key environment variable appears to contain secret material.

## Recovery

- Re-run `make help` and check the documented defaults.
- Use `make detect-disks` on the target before setting `INSTALL_DISK`.
- Do not set `I_UNDERSTAND_THIS_WIPES_DISK=yes` for read-only plan targets.
- Do not pass passwords, private keys, API keys, or tokens through Makefile variables.
- Keep `.env` files local and gitignored; `.env.example` may document variable names only.
