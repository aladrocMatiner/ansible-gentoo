# Design: implement-ansible-users-and-access

## Variables
- `admin_user`
- `admin_groups`
- `admin_sudo_nopasswd` with default `no` outside disposable VM E2E workflows
- `admin_password_hash` or documented interactive alternative
- `ssh_authorized_keys`

## Secret Handling
Never commit plaintext passwords, private keys, tokens, or local credentials. `.env` remains ignored; `.env.example` may document variable names only.

## Access Policy
Configure one documented privilege escalation path. Default to conservative password-requiring sudo for normal installs. Allow `admin_sudo_nopasswd=yes` only as an explicit policy choice or as the documented disposable libvirt E2E default.
