# Change: implement-ansible-users-and-access

## Summary
Implement safe target user creation, root password handling policy, and administrative access configuration.

## Motivation
The installed system needs a safe way to create an admin user and configure privilege escalation without committing secrets or hardcoding credentials.

## Scope
- Add shared `common/users` role.
- Support admin user creation from explicit variables.
- Configure sudo or doas.
- Define root password policy.
- Support SSH authorized keys if enabled.
- Follow `implement-secret-input-policy` for passwords, hashes, SSH keys, logs, state, and docs.
- Follow installed SSH policy for root SSH restrictions and authorized key handling.

## Non-goals
- Do not store passwords in the repository.
- Do not generate real credentials.
- Do not enable passwordless root SSH by default.

## Safety Requirements
- No secrets in git.
- Passwords must be provided interactively or as hashes through secret-safe channels.
- Logs, state files, and audit bundles must not expose secret values.
- Privileged user creation is high-risk and must be documented.

## Acceptance Criteria
- Admin user creation requires explicit username.
- Privilege escalation config is installed safely.
- No plaintext secrets appear in repo files.
- User/access evidence is included in audit output without secrets.
- Root SSH defaults remain safe when SSH is enabled.
- `openspec validate implement-ansible-users-and-access --strict` passes.

## Affected Files
- `ansible/roles/common/users/`
- `docs/`
- `skills/`
