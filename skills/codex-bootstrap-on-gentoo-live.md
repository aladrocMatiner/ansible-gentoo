# Codex Bootstrap on Gentoo Live Skill

## 1. Purpose
This skill describes how to install Codex temporarily inside the official Gentoo live ISO for `gentoo-ai-installer`.

The project does not build a custom ISO in v1. Codex is installed after booting the official Gentoo live ISO, and the Makefile controls the operation. The install method must be configurable.

This skill describes procedure and requirements only. It does not implement scripts.

## 2. When to Use This Skill
Use this skill:

- After the official Gentoo live ISO has booted.
- After live environment preflight checks pass.
- Before using Codex to assist with manual Gentoo installation.
- After rebooting the live ISO, because the previous Codex install may be gone.
- When changing the configured Codex install method.

## 3. Required Context
- Confirmation that the environment is the official Gentoo live ISO.
- Result of live environment preflight.
- Network, DNS, HTTPS, and time status.
- Writable project directory.
- Temporary bootstrap directory.
- Selected install method: `npm`, `guru`, or `binary`.
- Authentication approach: interactive login or environment variables.
- Confirmation that no target Gentoo root should be modified.

## 4. Install Method Selection
Supported install methods:

- `npm`: install Codex through the npm package.
- `guru`: install `dev-util/codex` from the GURU overlay.
- `binary`: install the official Codex binary release.

Selection rules:

- The preferred method must be configurable, for example with `CODEX_INSTALL_METHOD=npm`, `CODEX_INSTALL_METHOD=guru`, or `CODEX_INSTALL_METHOD=binary`.
- Prefer the configured method when its preflight requirements pass.
- Use `npm` when Node.js/npm are available or can be installed temporarily through documented Makefile-controlled steps.
- Use `guru` when Portage and GURU overlay setup are appropriate for the live environment and will not modify the target root.
- Use `binary` when an official amd64-compatible release is available and provenance can be verified.
- Stop and ask the operator to choose another method if the configured method fails preflight.
- Do not silently fall back to a different method.

## 5. Network Requirements
Before `make bootstrap-codex`, verify:

- IP address is assigned.
- Default route exists.
- DNS resolution works.
- HTTPS/TLS works.
- System time is correct enough for TLS.
- The selected source is reachable:
  - npm registry for `npm`.
  - Gentoo/GURU package sources for `guru`.
  - official release source for `binary`.

If network checks fail, do not start Codex installation.

## 6. Package Requirements
Method-specific requirements:

- `npm`: Node.js, npm, TLS certificates, registry access, writable package/cache path, and enough temporary space.
- `guru`: Portage availability in the live environment, GURU overlay access, package metadata, TLS certificates, and enough temporary space.
- `binary`: download tool such as `curl` or `wget`, checksum or signature verification when available, executable permissions, amd64 compatibility, and writable install path.

Any missing package or runtime dependency must be installed through a make target or documented script, not through undocumented ad-hoc commands.

## 7. Authentication Safety
Security requirements:

- Do not commit API keys.
- Do not persist tokens into the repository.
- Do not write secrets into shell history.
- `.env.example` may document variable names only.
- `.env` must be gitignored.
- Prefer interactive login or environment variables.
- Warn that the live environment is temporary and will be lost after reboot.
- Do not print tokens, API keys, refresh tokens, or session material in logs.
- Do not store secrets in OpenSpec changes, generated docs, Makefile defaults, Ansible variables, or commit messages.

If a secret may have been written into the repository, stop and clean it before continuing.

## 8. Environment Variable Handling
When using environment variables:

- Document variable names in `.env.example` with placeholder values only.
- Keep real values outside git.
- Prefer one-shot shell environment variables or interactive prompts.
- Do not ask the operator to paste secret values into chat logs.
- Do not echo secret variables in scripts or Makefile targets.
- Ensure `make clean-live-secrets` removes only known temporary secret files.

Examples of documented placeholders are acceptable:

```text
OPENAI_API_KEY=replace-with-your-key
CODEX_INSTALL_METHOD=npm
```

Real secret values are not acceptable in tracked files.

## 9. Temporary Filesystem Considerations
The official Gentoo live ISO environment is temporary:

- Codex installation may be lost after reboot.
- Authentication state may be lost after reboot.
- Temporary package caches may be RAM-backed.
- Available space must be checked before installing Codex or dependencies.
- Bootstrap files must not be written into the mounted target Gentoo root.
- The temporary install path should be explicit and easy to clean.
- Cleanup must avoid broad recursive deletion.

Warn the operator before reboot that Codex may need to be bootstrapped again.

## 10. Makefile Targets
Expected make targets:

- `make bootstrap-codex`
- `make check-codex`
- `make clean-live-secrets`

Expected behavior:

- `make bootstrap-codex`: install Codex temporarily using the configured `CODEX_INSTALL_METHOD`.
- `make check-codex`: verify Codex is available and usable without exposing secrets.
- `make clean-live-secrets`: remove known live-session secret files and authentication artifacts only.

The operator should use Makefile targets, not raw install commands or scripts.

## 11. Validation Checks
After `make bootstrap-codex`, run `make check-codex` and verify:

- `codex` command exists.
- Codex version can be printed.
- Authentication method is available.
- Network access is working.
- Project directory is writable.
- Selected install method is recorded.
- Codex install path is in the live environment or project-approved temporary path.
- No files were written into the target Gentoo root.
- `.env` is gitignored if present.
- `.env.example` contains variable names and placeholders only.
- No secrets appear in tracked files or command output.

## 12. Failure Modes
- Network is unavailable.
- DNS resolution fails.
- System time breaks TLS validation.
- npm registry is unreachable.
- Node.js or npm is missing for the `npm` method.
- GURU overlay is unavailable or `dev-util/codex` is missing.
- Portage setup would modify the target root instead of the live environment.
- Official binary release cannot be verified.
- Binary is not compatible with amd64 live environment.
- Temporary filesystem lacks space.
- `codex` installs but is not on `PATH`.
- Authentication fails.
- Login state is lost after reboot.
- Secrets are written to `.env`, shell history, logs, or tracked files.

## 13. Recovery Advice
- Re-run live environment preflight before retrying.
- Fix network, DNS, and time before retrying downloads.
- Switch `CODEX_INSTALL_METHOD` only after operator approval.
- For `npm`, verify Node.js/npm availability and temporary cache space.
- For `guru`, verify live-environment Portage and GURU overlay setup.
- For `binary`, verify architecture, source, checksum or signature, and executable permissions.
- If `codex` is not found, inspect the configured temporary install path and PATH setup.
- If secrets may have leaked, run `make clean-live-secrets`, inspect `git status`, and remove secret material before continuing.
- After reboot, assume Codex and authentication state are gone and run bootstrap again.

## 14. Output Artifacts
This skill should produce or request:

- Selected `CODEX_INSTALL_METHOD`.
- Bootstrap preflight result.
- Temporary install path.
- Codex version output.
- Authentication method status without secret values.
- Network validation result.
- Project directory writability result.
- Secret hygiene check result.
- Cleanup instructions through `make clean-live-secrets`.
