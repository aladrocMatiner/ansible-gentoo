# Design: implement-secret-input-policy

## Allowed Secret Channels

Allowed channels may include:

- interactive prompts,
- environment variables set by the operator for the current process,
- gitignored local files with documented examples,
- Ansible Vault only if later approved and documented.

## Forbidden Secret Storage

Never store these in git, logs, state, audit bundles, docs, or examples:

- plaintext passwords,
- real password hashes unless explicitly approved as non-secret for a specific workflow,
- API keys,
- Codex login tokens,
- private SSH keys,
- real local credentials.

## Documentation

`.env.example` may document variable names only. `.env` must be ignored if used.

Docs must show secret variable names with empty values, not placeholder token strings or real values.

## Validation

Secret checks should run before commits/release readiness and before writing audit bundles where practical. Findings must fail or warn clearly depending on severity.
