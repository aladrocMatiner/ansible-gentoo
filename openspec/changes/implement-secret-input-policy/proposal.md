## Why

Users, passwords, SSH keys, Codex tokens, and API keys are high-risk inputs. The installer needs one shared policy before user creation and automation start accepting secrets.

## What Changes

- Define secret-safe input channels for Ansible, scripts, and Makefile targets.
- Forbid committing `.env`, plaintext passwords, API keys, private SSH keys, login tokens, and secret variable files.
- Require `.env.example` to document variable names only.
- Require logs, state files, and audit bundles to redact or reject secret values.
- Define validation checks for accidental secrets.

## Capabilities

### New Capabilities
- `secret-input-policy`: Defines how secrets are passed, redacted, documented, and rejected.

### Modified Capabilities

## Impact

- User creation and access workflows.
- Codex bootstrap docs.
- Audit bundle, state checkpoints, and final checks.
- `.gitignore`, docs, and skills.
