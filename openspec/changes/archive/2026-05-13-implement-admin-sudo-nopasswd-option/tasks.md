# Tasks: implement-admin-sudo-nopasswd-option

## OpenSpec

- [x] Create proposal, design, tasks, and spec delta.
- [x] Validate with `openspec validate implement-admin-sudo-nopasswd-option --strict`.
- [x] Validate full project with `openspec validate --all --strict`.

## Implementation

- [x] Add Makefile variables and help output.
- [x] Add schema and config-check validation for `ADMIN_SUDO_NOPASSWD`.
- [x] Pass the sudo mode through configure-users and full install wrappers.
- [x] Default disposable libvirt E2E installs to passwordless sudo through `VM_E2E_ADMIN_SUDO_NOPASSWD=yes`.
- [x] Update `common/users` to render sudoers with optional `NOPASSWD: ALL`.
- [x] Update final checks and first-boot validation.
- [x] Update users preview and install report evidence.

## Documentation

- [x] Update `.env.example`.
- [x] Update users/access documentation.
- [x] Update install configuration documentation.
- [x] Update installed SSH and libvirt E2E documentation.
- [x] Update relevant skills.

## Verification

- [x] Run `make ansible-check`.
- [x] Run `make config-check`.
- [x] Run `make secret-check`.
- [x] Run OpenSpec validations.
