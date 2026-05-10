# Secret Input Policy

Secrets must not be committed, logged, copied into audit bundles, or written into OpenSpec changes. This policy applies to Codex bootstrap, installed-system users, SSH configuration, future Ansible Vault use, logs, state files, and release artifacts.

## Allowed Channels

Approved channels for future workflows:

- interactive prompts that do not echo values,
- environment variables for the current process when the workflow explicitly documents them,
- gitignored local files such as `.env`,
- Ansible Vault only after an approved OpenSpec change documents usage.

`.env.example` may document variable names only. Values in `.env.example` must remain empty.

User/access configuration may read these optional controller-local files:

- `ADMIN_PASSWORD_HASH_FILE`
- `ROOT_PASSWORD_HASH_FILE`
- `ADMIN_AUTHORIZED_KEYS_FILE`

Store real local inputs under `var/secrets/` or outside the repository. `var/secrets/` is gitignored. The workflow must reject git-tracked input files and must never print password hashes or authorized key contents.

## Forbidden Storage

Never store these in git, logs, state, audit bundles, docs, examples, or commit messages:

- plaintext passwords,
- real password hashes unless a future OpenSpec change explicitly classifies a specific hash as non-secret test data,
- API keys,
- Codex login or refresh tokens,
- private SSH keys,
- real local credentials.

## Checks

Run:

```sh
make secret-check
```

The check scans tracked and non-ignored untracked text files for high-risk secret patterns. It prints only the pattern category and path, not the matching value.

`make config-check` also rejects known password/private-key environment variables for installer configuration, because those values would be too easy to log through Makefile or Ansible output.

## Recovery

If a secret is found before commit:

1. Remove the secret from the file.
2. Rotate the secret if it may have been exposed.
3. Re-run `make secret-check`.

If a secret was already committed, stop and treat it as an incident. Remove it from future commits and rotate it; history rewriting requires explicit operator approval.
