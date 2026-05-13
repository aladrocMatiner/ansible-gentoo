# Resumable libvirt OpenRC/ext4 Validation

This runbook validates the resumable installer one phase at a time in the disposable local libvirt VM.

It is a validation workflow for the reusable SSH-driven Ansible installer. It does not define a separate installer path and it does not replace full `vm-e2e-install` validation.

## Case

```text
platform: amd64
profile: openrc
filesystem: ext4
stage3 flavor: standard
domain: gentoo-test-amd64-openrc-ext4
guest install disk: /dev/vda
state pointer: var/state/libvirt/gentoo-test-amd64-openrc-ext4/current-install.json
```

`/dev/vda` is valid only inside the disposable VM. Real hardware and remote network targets must use the explicit disk reported by `make detect-disks ANSIBLE_LIVE_HOST=...`.

## Prerequisites

Place the official Gentoo live ISO at the configured `VM_ISO` path, normally:

```text
gentoo.iso
```

Prepare a public SSH key file for live ISO SSH bootstrap and installed-system validation. The file must contain public keys only.

Set a common environment for the validation commands:

```sh
export PROFILE=openrc
export FILESYSTEM=ext4
export STAGE3_FLAVOR=standard
export INSTALL_DISK=/dev/vda
export ADMIN_USER=testadmin
export ENABLE_SSH=yes
export ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file>
export ADMIN_SUDO_NOPASSWD=yes
export I_UNDERSTAND_THIS_WIPES_DISK=yes
export I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

The destructive confirmations are still required because the installer partitions, formats, and installs a bootloader inside the VM qcow2. The confirmations do not apply to host disks.

`ADMIN_SUDO_NOPASSWD=yes` is appropriate here because this VM is disposable validation infrastructure. Do not copy that setting into real installs unless the operator explicitly wants passwordless sudo.

## Prepare the VM

Start from a clean disposable VM when validating the whole resume path:

```sh
make vm-clean PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard I_UNDERSTAND_CLEANUP_DELETE=DELETE
make vm-check PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard
make vm-disk PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard
make vm-define PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard
make vm-start PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard
make vm-bootstrap-ssh PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file>
make vm-ansible-ping PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard
```

If the domain already exists and is known to be disposable, `vm-start` may reuse it. Use `make vm-clean` only when resetting generated artifacts is intended.

## Phase-by-phase Validation

Before each resumed phase, run the read-only planner:

```sh
make install-resume-plan \
  PROFILE=openrc \
  FILESYSTEM=ext4 \
  STAGE3_FLAVOR=standard \
  INSTALL_DISK=/dev/vda \
  ADMIN_USER=testadmin \
  ENABLE_SSH=yes \
  ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file> \
  ADMIN_SUDO_NOPASSWD=yes
```

Then execute exactly one planner-approved phase:

```sh
make install-resume \
  PROFILE=openrc \
  FILESYSTEM=ext4 \
  STAGE3_FLAVOR=standard \
  INSTALL_DISK=/dev/vda \
  ADMIN_USER=testadmin \
  ENABLE_SSH=yes \
  ADMIN_AUTHORIZED_KEYS_FILE=<public-key-file> \
  ADMIN_SUDO_NOPASSWD=yes \
  I_UNDERSTAND_THIS_WIPES_DISK=yes \
  I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

Repeat that pair until `final-checks` completes or a blocker is reached:

1. `make install-resume-plan`
2. inspect the next phase and required confirmations
3. `make install-resume`
4. stop and plan again

`install-resume` also runs planner validation internally, but the explicit planner command is required for this validation run so the evidence shows review before every phase.

## Expected Phases

The expected phase order is:

```text
live-preflight
disk-detection
disk-safety
install-plan
partition-plan
partition-apply
filesystem-plan
filesystem-apply
mount-plan
mount-target
stage3-install
chroot-preparation
portage-baseline
system-config
fstab-generation
kernel-install
system-packages
users-and-access
bootloader
final-checks
```

The run is successful when each phase either completes or the first blocker is documented with logs and recovery guidance.

## Evidence

Collect these non-secret artifacts:

```text
var/state/libvirt/gentoo-test-amd64-openrc-ext4/current-install.json
logs/install-runs/<run-id>/state.json
logs/install-runs/<run-id>/events.jsonl
logs/install-runs/<run-id>/*/
```

Useful inspection commands:

```sh
make install-state INSTALL_STATE_FILE=var/state/libvirt/gentoo-test-amd64-openrc-ext4/current-install.json
scripts/install-state.py --state-file var/state/libvirt/gentoo-test-amd64-openrc-ext4/current-install.json resume-plan
```

Do not copy password hashes, private keys, API tokens, or local credentials into committed validation notes.

## Failure Modes

- No state file exists: run the first Makefile-mediated phase such as `make ansible-live-preflight` or start with the full `make install-resume` wrapper after VM SSH is ready.
- VM SSH is unavailable: run `make vm-ip`, inspect `make vm-console`, then rerun `make vm-bootstrap-ssh`.
- Planner blocks on missing confirmations: rerun the planner with the exact variables intended for `install-resume`.
- Planner reports a disk mismatch: stop and inspect `make detect-disks`; do not continue by editing state manually.
- A destructive phase fails: preserve `logs/install-runs/<run-id>/`, rerun the relevant read-only plan, and only retry with explicit confirmations after reviewing state.
- Stage3, Portage, or package installation fails: rerun `make install-resume-plan`; if current facts match, retry only the next planner-approved phase.

## Recovery

For disposable VM retry from scratch:

```sh
make vm-clean PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard I_UNDERSTAND_CLEANUP_DELETE=DELETE
```

For a partial run that should continue, do not clean the VM. Inspect state:

```sh
make install-state INSTALL_STATE_FILE=var/state/libvirt/gentoo-test-amd64-openrc-ext4/current-install.json
make install-resume-plan PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard INSTALL_DISK=/dev/vda
```

If a manual fix is needed, record it before resuming:

```sh
make record-manual-step \
  INSTALL_STATE_FILE=var/state/libvirt/gentoo-test-amd64-openrc-ext4/current-install.json \
  MANUAL_STEP_SUMMARY="Reviewed VM target state" \
  MANUAL_STEP_REASON="Validation paused for manual recovery"
```

Then rerun `make install-resume-plan` before any mutating target.

## Completion

When validation reaches the end or a documented blocker, shut down or pause the VM:

```sh
make vm-shutdown PROFILE=openrc FILESYSTEM=ext4 STAGE3_FLAVOR=standard
```

Record the completed phase list, run id, and remaining issues in the OpenSpec change tasks or implementation summary.

## Validation Record

The `validate-resumable-libvirt-openrc-ext4` implementation run completed the full known phase list through `final-checks` for:

```text
domain: gentoo-test-amd64-openrc-ext4
run id: 20260513T205319352716135Z-openrc-ext4
state file: var/state/libvirt/gentoo-test-amd64-openrc-ext4/current-install.json
continuation log: logs/resumable-libvirt-validation/openrc-ext4-continue3-20260513T210614Z.log
```

The final resume plan reported no next phase, no mismatches, no missing variables, no missing confirmations, and the blocker `all known phases are complete`.
