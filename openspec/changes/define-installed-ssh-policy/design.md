# Design: define-installed-ssh-policy

## Policy

Recommended v1 behavior:

- SSH is optional and controlled by `ENABLE_SSH`.
- If `ENABLE_SSH=yes`, install OpenSSH or the approved SSH server package.
- Enable SSH through init-specific service logic.
- Do not enable passwordless root SSH by default.
- Do not enable root password login by default.
- Authorized keys must come from an approved secret-safe channel.

## Authentication

Passwords and SSH keys must follow the secret input policy. Public keys may be documented as public, but private keys must never be stored or logged.

## Validation

If SSH is enabled:

- final checks verify package/service status,
- first-boot validation may verify SSH reachability,
- install report summarizes host/port/user guidance without secrets.

## Scope

This policy applies to the installed target. It is separate from temporary SSH bootstrap inside the live ISO VM.
