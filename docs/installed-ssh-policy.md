# Installed SSH Policy

SSH in the installed Gentoo target is optional. It is controlled by `ENABLE_SSH` and is separate from temporary SSH bootstrap used by the live ISO VM.

## Policy

For v1:

- `ENABLE_SSH=no` is the default.
- `ENABLE_SSH=yes` installs OpenSSH and enables the selected init system's SSH service.
- SSH service enablement is init-specific but driven by shared variables.
- Root SSH password login must not be enabled by default.
- Passwordless root SSH must not be enabled by default.
- Admin authorized keys are installed only from `ADMIN_AUTHORIZED_KEYS_FILE`.
- Installed SSH host keys are generated under `/etc/ssh` when `ENABLE_SSH=yes` and no host private keys exist yet.
- Password hashes are read only from `ADMIN_PASSWORD_HASH_FILE` and `ROOT_PASSWORD_HASH_FILE`.
- SSH-key-only admin accounts need either a password hash for interactive sudo or `ADMIN_SUDO_NOPASSWD=yes` for passwordless sudo.
- Secret-bearing input files must be gitignored or outside the repository.

## Makefile Workflows

Install and enable SSH packages/services:

```sh
make install-system-packages PROFILE=openrc ENABLE_SSH=yes
make install-system-packages PROFILE=systemd ENABLE_SSH=yes
```

Install admin authorized keys and enforce root SSH restrictions:

```sh
make configure-users \
  ADMIN_USER=<admin-user> \
  ENABLE_SSH=yes \
  ADMIN_AUTHORIZED_KEYS_FILE=var/secrets/admin_authorized_keys
```

For disposable VM tests where the admin account is created only with SSH keys, enable passwordless sudo:

```sh
make configure-users \
  ADMIN_USER=<admin-user> \
  ENABLE_SSH=yes \
  ADMIN_AUTHORIZED_KEYS_FILE=var/secrets/admin_authorized_keys \
  ADMIN_SUDO_NOPASSWD=yes
```

Validate SSH policy evidence:

```sh
make final-checks ADMIN_USER=<admin-user> ENABLE_SSH=yes
make vm-validate-first-boot ADMIN_USER=<admin-user> FIRST_BOOT_USER=<admin-user>
make install-report
```

## OpenRC

OpenRC installations with `ENABLE_SSH=yes` must:

- install `net-misc/openssh`,
- enable `sshd` with OpenRC logic,
- validate SSH service status without calling `systemctl`.

## systemd

systemd installations with `ENABLE_SSH=yes` must:

- install `net-misc/openssh`,
- enable `sshd.service` with systemd logic,
- validate SSH service status without calling `rc-update` or `rc-service`.

## Secret Safety

The workflow must never commit, log, or copy into audit bundles:

- plaintext passwords,
- password hashes,
- private SSH keys,
- real local credentials.

`ADMIN_AUTHORIZED_KEYS_FILE` may contain public keys only. The workflow must reject private key material and git-tracked secret input files.

## Validation

Final checks must report installed SSH package/service status when `ENABLE_SSH=yes`, confirm root-login restrictions are present when SSH is configured, and validate whether admin sudoers requires a password or uses `NOPASSWD: ALL`.
Final checks must also require installed SSH host keys when `ENABLE_SSH=yes`; without host keys, `sshd` may be enabled but unable to listen after first boot.

First-boot validation requires SSH access to the installed VM because it runs read-only checks over Ansible. If SSH was not enabled or no authorized key was installed, first-boot validation fails clearly instead of falling back to console mutation.

## Failure Modes

- SSH service missing: rerun `make install-system-packages ENABLE_SSH=yes`.
- SSH service enabled but port 22 refuses connections after first boot: boot the VM through the live ISO recovery path, verify `/etc/ssh/ssh_host_*_key` exists in the target root, then rerun `make configure-users ENABLE_SSH=yes ...` so the workflow generates missing host keys.
- Authorized keys missing: rerun `make configure-users ENABLE_SSH=yes ADMIN_AUTHORIZED_KEYS_FILE=...`.
- SSH works but `sudo su -` asks for an unknown password: provide `ADMIN_PASSWORD_HASH_FILE` for password-requiring sudo, or rerun disposable tests with `ADMIN_SUDO_NOPASSWD=yes`.
- Private key material detected: replace the file with public keys only and rotate any exposed private key.
- Root SSH policy mismatch: rerun `make configure-users ENABLE_SSH=yes`; do not edit target SSH config manually unless a manual recovery note is recorded.

## Recovery

If SSH is required after a run with `ENABLE_SSH=no`, rerun the Makefile-mediated package and user targets with `ENABLE_SSH=yes`. Do not enable SSH with ad-hoc commands outside the project workflow.
