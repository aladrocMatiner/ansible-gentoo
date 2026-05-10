# Change: implement-ansible-portage-baseline

## Summary
Implement minimal Portage baseline configuration in the target Gentoo system.

## Motivation
The target system needs a conservative `make.conf`, profile selection, repository sync, mirrors, licenses, and minimal USE policy before package installation. This maps to the Gentoo AMD64 Handbook base system and Portage configuration steps.

## Scope
- Add shared `common/portage` role.
- Configure `make.conf` conservatively.
- Select OpenRC or systemd profile.
- Configure mirrors through documented variables.
- Sync Gentoo repository.
- Keep `COMMON_FLAGS`, `MAKEOPTS`, `USE`, and license policy simple and documented.
- Keep GURU disabled in the installed system unless explicitly required.
- Use the target system baseline and configuration schema for profile-related values.
- Follow the download cache/mirror policy and Portage world update policy.

## Non-goals
- Do not install kernel or bootloader.
- Do not install Codex into the target system.
- Do not over-optimize CPU flags.

## Safety Requirements
- Do not write secrets.
- Do not enable overlays blindly.
- Preserve clear diffs for managed files.

## Acceptance Criteria
- `make.conf` is minimal and reproducible.
- Profile matches `PROFILE`.
- OpenRC and systemd profile choices are variant data, not duplicated tasks.
- Profile selection contributes evidence to the install report and final baseline checks.
- Broad `@world` update does not run by default in v1 unless a later approved change enables it.
- Pending config file updates are reported without unsafe unattended overwrites.
- Portage sync succeeds or fails clearly.
- `openspec validate implement-ansible-portage-baseline --strict` passes.

## Affected Files
- `ansible/roles/common/portage/`
- `ansible/init/openrc/`
- `ansible/init/systemd/`
- `docs/`
- `skills/`
