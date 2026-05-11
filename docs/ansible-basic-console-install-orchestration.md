# Ansible Basic Console Install Orchestration

`make install`, `make install-openrc`, and `make install-systemd` run the full basic console Gentoo install flow through a shared Ansible playbook.

These targets are destructive. They partition and format the selected disk, mount the target, install stage3, configure the target system, install GRUB, and run final checks. They do not reboot automatically.

## Targets

Use the generic target with `PROFILE`:

```sh
make install \
  PROFILE=openrc \
  FILESYSTEM=btrfs \
  INSTALL_DISK=/dev/vda \
  ADMIN_USER=gentoo \
  I_UNDERSTAND_THIS_WIPES_DISK=yes \
  I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

Or use thin profile targets:

```sh
make install-openrc FILESYSTEM=ext4 INSTALL_DISK=<disk> ADMIN_USER=<name> I_UNDERSTAND_THIS_WIPES_DISK=yes I_UNDERSTAND_BOOTLOADER_CHANGES=yes
make install-systemd FILESYSTEM=ext4 INSTALL_DISK=<disk> ADMIN_USER=<name> I_UNDERSTAND_THIS_WIPES_DISK=yes I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

`/dev/vda` is only a libvirt guest example. For real hardware or remote VMs, use the disk path reported by `make detect-disks ANSIBLE_LIVE_HOST=...`.

## Required Variables

- `PROFILE=openrc|systemd`
- `FILESYSTEM=ext4|btrfs`
- `INSTALL_DISK=<explicit target disk>`
- `ADMIN_USER=<admin account>`
- `I_UNDERSTAND_THIS_WIPES_DISK=yes`
- `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`

Optional variables include `HOSTNAME`, `TIMEZONE`, `LOCALE`, `KEYMAP`, `ENABLE_SSH`, `ADMIN_GROUPS`, `ADMIN_SHELL`, `ADMIN_SUDO_NOPASSWD`, `ADMIN_AUTHORIZED_KEYS_FILE`, `ADMIN_PASSWORD_HASH_FILE`, `ROOT_PASSWORD_HASH_FILE`, `STAGE3_MIRROR`, `STAGE3_CACHE_DIR`, and `PORTAGE_GENTOO_MIRRORS`.

Secret-bearing files must be local, gitignored, and passed by file path only.

## Shared Flow

The shared playbook follows the Gentoo AMD64 Handbook order with project-specific guardrails:

1. live ISO preflight
2. disk detection and shared destructive safety gate
3. partition plan and partition apply
4. refreshed disk detection and filesystem plan/apply
5. target root and EFI mount
6. official stage3 download, signature/checksum verification, and extraction
7. chroot pseudo-filesystem and DNS preparation
8. Portage baseline
9. hostname, timezone, locale, and keymap
10. UUID-based fstab
11. `gentoo-kernel-bin` and initramfs support
12. console packages and init-specific services
13. admin user, sudo policy, and optional SSH policy
14. GRUB UEFI bootloader
15. read-only final checks

OpenRC and systemd entrypoints only select variant variables and call this shared flow.

## Safety

Full install targets must fail before doing target work unless both destructive confirmations are present.

The full flow:

- uses no default disk
- runs `make config-check` first
- runs `make secret-check` first
- uses shared disk safety gates
- prints destructive previews inside partition and filesystem roles
- shows EFI entries before bootloader changes
- keeps OpenRC and systemd differences in variant variables and init roles
- writes non-secret per-phase evidence under `logs/install-runs/<run-id>/`
- writes non-secret install state checkpoints through `common/install_state`

Do not run the full install target against a disk with mounted descendants from a previous install attempt. Reboot the live ISO or cleanly unmount the target first.

## Validation

Run non-destructive validation first:

```sh
make ansible-check
make config-check CONFIG_DESTRUCTIVE=yes CONFIG_REQUIRE_INSTALL_DISK=yes PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=<disk> ADMIN_USER=<name> I_UNDERSTAND_THIS_WIPES_DISK=yes I_UNDERSTAND_BOOTLOADER_CHANGES=yes
make config-check CONFIG_DESTRUCTIVE=yes CONFIG_REQUIRE_INSTALL_DISK=yes PROFILE=systemd FILESYSTEM=ext4 INSTALL_DISK=<disk> ADMIN_USER=<name> I_UNDERSTAND_THIS_WIPES_DISK=yes I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

Full VM validation should use a disposable libvirt VM disk with no mounted target descendants before running the destructive install target.

## Failure Modes

- Missing `INSTALL_DISK`: run `make detect-disks`.
- Missing wipe confirmation: pass `I_UNDERSTAND_THIS_WIPES_DISK=yes` only when the selected disk is disposable or intentionally targeted.
- Missing bootloader confirmation: pass `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`.
- Missing `ADMIN_USER`: choose the target admin account.
- Mounted descendants on the selected disk: reboot the live ISO or unmount target filesystems before rerunning full install.
- Existing stage3 markers under `/mnt/gentoo`: use a clean target root or restart from partition/format.
- Systemd/OpenRC profile mismatch: use `make install-openrc` or `make install-systemd` instead of changing variant variables mid-run.

## Output

Each implemented role writes non-secret evidence under a shared run id:

```text
logs/install-runs/<run-id>/
```

The shared state role also updates:

```text
var/state/current-install.json
logs/install-runs/<run-id>/state.json
logs/install-runs/<run-id>/events.jsonl
```

Inspect state with `make install-state`. Validate a possible continuation with `make install-resume-plan`; this is read-only and does not satisfy destructive confirmations.

Final checks write:

```text
logs/install-runs/<run-id>/final-checks/reboot-readiness.json
```

After successful final checks, the wrapper generates:

```text
logs/install-runs/<run-id>/audit-bundle/
```

The audit bundle is secret-scanned local evidence for review and debugging. It does not copy password hashes, private keys, tokens, or local credentials.
