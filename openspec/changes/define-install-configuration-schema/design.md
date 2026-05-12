# Design: define-install-configuration-schema

## Canonical Variables

The schema must define at least:

| Makefile variable | Ansible variable | Required | Default | Allowed values |
| --- | --- | --- | --- | --- |
| `PROFILE` | `profile` / `init_system` | yes | `openrc` | `openrc`, `systemd` |
| `FILESYSTEM` | `filesystem` | yes | `ext4` | `ext4`, `btrfs` |
| `BOOT_MODE` | `boot_mode` | yes | `uefi` | `uefi` |
| `INSTALL_DISK` | `install_disk` | destructive/apply | none | explicit disk path only |
| `HOSTNAME` | `hostname` | install | `gentoo` | valid Linux hostname |
| `ADMIN_USER` | `admin_user` | users | none or explicit | valid local username |
| `ENABLE_SSH` | `enable_ssh` | optional | `no` | `yes`, `no` |
| `TARGET_MOUNT` | `target_mount` | install | `/mnt/gentoo` | target path, not `/` |
| `EFI_MOUNT` | `efi_mount` | install | `/mnt/gentoo/boot/efi` | path under target root |
| `I_UNDERSTAND_THIS_WIPES_DISK` | `confirm_wipe_disk` | destructive | none | `yes` |

`INSTALL_DISK` must never have a default. Destructive confirmations must never default to `yes`.

## Schema Format

Implementation may use YAML, JSON, or Ansible vars, but the schema must be machine-readable enough for config validation and human-readable enough for docs.

## Validation Rules

The schema must reject:

- unsupported profile/filesystem/stage3 flavor/boot mode values,
- `INSTALL_DISK` omitted for destructive apply workflows,
- `INSTALL_DISK` defaulting from Makefile, role defaults, inventory, or group vars,
- BIOS boot mode in v1,
- LUKS in current scope,
- unknown variables that look like mistaken operator input when strict validation is enabled.

## Documentation

The schema must be documented in `docs/` and reflected in `skills/makefile-control-plane.md` and `skills/ansible-gentoo-installer.md`.
