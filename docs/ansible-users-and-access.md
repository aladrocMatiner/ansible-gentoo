# Ansible Users And Access

This workflow configures installed-system users under `/mnt/gentoo` from the live ISO over SSH. It does not partition, format, mount filesystems, install GRUB, or reboot.

Run it through the Makefile:

```sh
make configure-users ADMIN_USER=gentoo PROFILE=openrc
```

`ADMIN_USER` is required. The default admin group is `wheel`, the default shell is `/bin/bash`, and the current privilege tool is `sudo`.

## Optional Secret Inputs

Password hashes and authorized keys are read from controller-local files. The file paths may be passed through environment variables, but the file contents must never be committed.

```sh
make configure-users \
  ADMIN_USER=gentoo \
  ADMIN_PASSWORD_HASH_FILE=var/secrets/admin-password.hash \
  ROOT_PASSWORD_HASH_FILE=var/secrets/root-password.hash
```

For installed SSH access:

```sh
make install-system-packages ENABLE_SSH=yes
make configure-users ADMIN_USER=gentoo ENABLE_SSH=yes ADMIN_AUTHORIZED_KEYS_FILE=var/secrets/admin_authorized_keys
```

`var/secrets/` is gitignored. `.env.example` documents variable names only and must not contain real values.

## Behavior

- Creates `ADMIN_USER` if missing.
- Ensures the admin user is in `ADMIN_GROUPS`.
- Installs `/etc/sudoers.d/gentoo-ai-installer-admin` in the target and validates it with `visudo`.
- Leaves existing passwords unchanged unless a password hash file is explicitly provided.
- Applies password hashes with `chpasswd -e` using Ansible `no_log`.
- Installs `authorized_keys` only when `ADMIN_AUTHORIZED_KEYS_FILE` is provided.
- When `ENABLE_SSH=yes`, enforces `PermitRootLogin no` in the installed target SSH config.

## Safety Notes

This is a high-risk persistent target-system change because it modifies users, groups, sudo policy, password hashes, and SSH access. It is not destructive to disks, but it must still be reviewed before real hardware use.

The workflow refuses to use git-tracked files as password hash or authorized key inputs. It also rejects private key material in `ADMIN_AUTHORIZED_KEYS_FILE`.

## Failure Modes

- Missing `ADMIN_USER`: pass a conservative username such as `ADMIN_USER=gentoo`.
- Missing sudo tooling: run `make install-system-packages` first.
- Missing chroot mounts: run `make prepare-chroot` first.
- Missing OpenSSH with `ENABLE_SSH=yes`: run `make install-system-packages ENABLE_SSH=yes`.
- Invalid password hash: provide a single encrypted hash line, not a plaintext password.
- Tracked secret input file: move the file under `var/secrets/` or outside the repository.

## Output Artifacts

Non-secret evidence is written under:

```text
logs/install-runs/<run-id>/users/users-access.json
```

The report records the admin username, groups, privilege tool, whether authorized keys were installed, whether password hash inputs were used, and whether root SSH login was restricted. It does not record password hashes or key contents.
