# Design: implement-ansible-users-and-access

## Variables
- `admin_user`
- `admin_groups`
- `admin_password_hash` or documented interactive alternative
- `ssh_authorized_keys`

## Secret Handling
Never commit plaintext passwords, private keys, tokens, or local credentials. `.env` remains ignored; `.env.example` may document variable names only.

## Access Policy
Configure one documented privilege escalation path. Default to conservative access and explicit operator-provided credentials.
