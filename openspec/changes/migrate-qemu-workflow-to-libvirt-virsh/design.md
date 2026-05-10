# Design: Migrate QEMU Test Workflow to libvirt/virsh

## 1. Purpose
Move the local Gentoo live ISO test VM from direct `qemu-system-x86_64` invocation to a libvirt/virsh-managed VM.

The new workflow must make the VM controllable after boot while preserving the existing safety model:

- official Gentoo live ISO only,
- UEFI only,
- project-local qcow2 disk only,
- no host block devices,
- no custom ISO in v1,
- Makefile as the operator-facing control plane.

## 2. Existing Alignment Review
The current QEMU workflow should be treated as a safety baseline, not as the final control model.

Aligned behavior to preserve:

- `./gentoo.iso` as the local official ISO input, either a file or a directory containing exactly one `.iso`.
- `var/qemu/gentoo-test.qcow2` style project-local qcow2 disk artifacts.
- 40G sparse qcow2 default disk size.
- UEFI-only boot.
- Rejection of BIOS mode.
- Rejection of `/dev/*` VM disk paths.
- Rejection of parent traversal, project-root artifact directories, symlinked path components, wildcard paths, and option-injection characters.
- `qemu-check` style read-only validation.
- Explicit cleanup confirmation with `DELETE`.
- No Gentoo installation automation in the VM boot workflow.

Behavior to replace:

- Direct operator-facing `qemu-system-x86_64` invocation.
- Direct QEMU `-drive` assembly in operator workflows.
- Graphical-only VM interaction as the main control path.
- Lack of managed VM identity, lifecycle, IP discovery, SSH, and rsync.

Behavior to add:

- libvirt domain definition.
- managed lifecycle through `virsh`.
- `virsh console` support.
- SSH access through explicit host port forwarding by default.
- Optional IP discovery through `virsh domifaddr` and/or DHCP lease inspection when a managed libvirt network is explicitly configured.
- SSH target discovery and Makefile-mediated SSH.
- rsync target for copying project files or generated artifacts into the live ISO.
- future Ansible handoff through a controlled VM access layer.

## 3. Proposed Local Files
- `./gentoo.iso` or `./gentoo.iso/<official-live-iso-file>.iso`
- `./var/libvirt/gentoo-ai-installer.qcow2`
- `./var/libvirt/gentoo-ai-installer.xml`
- `./var/libvirt/nvram/`
- `./logs/libvirt/`

The exact artifact directory may be configurable, but it must remain project-relative and must not be the project root.

## 4. Required Host Tools
- `virsh`
- `virt-install` or an equivalent reviewed XML generation path
- `qemu-img`
- `ssh`
- `rsync`
- `make`
- UEFI firmware usable by libvirt

Optional tools:

- `virt-viewer` or `remote-viewer` for graphical access.
- `virt-xml` for controlled XML edits.

## 5. Libvirt Connection Model
Default:

- `LIBVIRT_URI ?= qemu:///system`

Rules:

- Do not require raw `sudo` commands in operator documentation; system libvirt permissions must be provided by host configuration.
- `qemu:///system` may be supported only when explicitly configured with `LIBVIRT_URI=qemu:///system`.
- Documentation must explain host setup prerequisites for whichever connection mode is used.
- Scripts must pass `--connect "$LIBVIRT_URI"` or equivalent explicitly.
- No target may silently switch between session and system libvirt.

## 6. VM Defaults
- Domain name: `gentoo-ai-installer`
- Architecture: x86_64
- RAM: 4096 MB
- CPUs: 2
- Disk size: 40G
- Disk format: qcow2
- Boot mode: UEFI only
- Network: managed libvirt networking with the default network
- Console: serial console enabled when supported by the live ISO boot path
- Graphics: optional, not the primary automation path

Expected variables:

- `LIBVIRT_URI ?= qemu:///system`
- `VM_NET_MODE ?= network`
- `VM_NAME ?= gentoo-ai-installer`
- `VM_ISO ?= gentoo.iso`
- `VM_DIR ?= var/libvirt`
- `VM_DISK ?= $(VM_DIR)/gentoo-ai-installer.qcow2`
- `VM_DISK_SIZE ?= 40G`
- `VM_RAM ?= 4096`
- `VM_CPUS ?= 2`
- `VM_NETWORK ?= default`
- `VM_SSH_HOST ?= 127.0.0.1`
- `VM_SSH_HOST_PORT ?= 2222`
- `VM_SSH_GUEST_PORT ?= 22`
- `VM_SSH_USER ?= root`
- `VM_BOOT_MODE ?= uefi`
- `VM_KERNEL_ARGS ?= dokeymap nodhcp root=live:CDLABEL=Gentoo-amd64-20260426 rd.live.dir=/ rd.live.squashimg=image.squashfs cdroot console=tty0 console=ttyS0,115200n8`

`VM_BOOT_MODE=bios` must be rejected in v1.
`VM_NET_MODE` must be `user` or `network`. `network` is the default and requires an explicit libvirt network name. `user` is non-default because libvirt port forwarding depends on host `passt` support.

## 7. Required Makefile Targets
New targets:

- `make vm-check`: read-only validation of libvirt tools, connection, ISO resolution, UEFI support, network mode configuration, and safe paths.
- `make vm-disk`: create the qcow2 disk if missing.
- `make vm-define`: generate or update the libvirt domain definition from safe project-local inputs.
- `make vm-start`: validate ISO, UEFI firmware, network, and path prerequisites before creating missing artifacts; for an existing inactive domain, verify disk, NVRAM, kernel, and initrd artifacts before starting; then start the VM from the official ISO and qcow2 disk.
- `make vm-console`: attach to `virsh console`.
- `make vm-viewer`: open a graphical console with `virt-viewer` or documented equivalent when serial console is not usable.
- `make vm-ip`: discover the guest IP when a managed libvirt network or guest agent can provide it; otherwise fail with guidance to use the forwarded SSH target.
- `make vm-bootstrap-ssh`: use the serial console to install an operator public key into the temporary live ISO and start `sshd`.
- `make vm-ssh`: connect to the guest over SSH after the live ISO has SSH enabled.
- `make vm-rsync`: copy selected project files or artifacts to the guest after SSH is available.
- `make vm-ansible-ping`: validate Ansible SSH connectivity to the live ISO without running installer playbooks.
- `make vm-shutdown`: request clean guest shutdown.
- `make vm-destroy`: stop the VM without deleting disk artifacts.
- `make vm-clean`: undefine the domain and delete generated project-local artifacts only after explicit confirmation.

Compatibility:

- Existing `make qemu-*` targets should be removed, renamed, or converted to compatibility aliases that call `make vm-*`.
- If aliases remain, documentation must state that libvirt/virsh is the active workflow and direct QEMU is no longer operator-facing.

## 8. Required Scripts
Potential scripts:

- `scripts/vm-check-libvirt.sh`
- `scripts/vm-create-disk.sh`
- `scripts/vm-define-libvirt-domain.sh`
- `scripts/vm-start.sh`
- `scripts/vm-ip.sh`
- `scripts/vm-bootstrap-live-ssh.py`
- `scripts/vm-ssh.sh`
- `scripts/vm-rsync.sh`
- `scripts/vm-ansible-ping.sh`
- `scripts/vm-clean.sh`

Scripts are implementation details. Operator instructions must use Makefile targets.

## 9. Domain Definition Strategy
Preferred strategy:

- Generate a deterministic domain XML under `VM_DIR`.
- Validate all paths before writing XML.
- Define the domain with `virsh --connect "$LIBVIRT_URI" define <xml>`.

The XML must include:

- official ISO attached as a CD-ROM,
- qcow2 disk attached as virtio,
- official kernel and initrd extracted from the ISO into project artifacts for direct kernel boot,
- serial console kernel arguments including `console=ttyS0,115200n8`,
- a serial console,
- managed libvirt networking with an explicit network name by default, or user-mode networking only when explicitly configured,
- stable domain name from `VM_NAME`,
- a project ownership marker in metadata, description, or another reviewed mechanism.

If `virt-install --print-xml` is used, the resulting XML must be reviewed and written to `VM_DIR` before definition. The workflow must not pass unvalidated disk or ISO paths directly to libvirt commands.

If a domain with `VM_NAME` already exists, `vm-define` must inspect it before making changes. It must fail if the existing domain does not carry the project ownership marker or if it references host block devices. `vm-define` may replace an inactive stale project-marked domain so older generated XML can be regenerated with current OVMF, ISO, and artifact settings. Start, SSH, rsync, Ansible, console, viewer, and IP discovery must fail if the existing domain does not match the configured official ISO and generated artifact paths. The workflow must not overwrite unrelated libvirt domains. It must not enable libvirt autostart by default.

## 10. Network and SSH Strategy
Default network mode is `VM_NET_MODE=network` with `VM_NETWORK=default`. It requires `VM_NETWORK` to name an existing libvirt network available on `LIBVIRT_URI`.

In managed network mode, `vm-ip` should try, in order:

1. `virsh domifaddr "$VM_NAME" --source agent` when a guest agent is available.
2. `virsh domifaddr "$VM_NAME" --source lease`.
3. `virsh net-dhcp-leases "$VM_NETWORK"` filtered by the VM MAC address.

If `VM_NET_MODE=network`, `vm-check` must validate that `VM_NETWORK` is set and exists.

The workflow must not assume SSH is available immediately after boot. `make vm-bootstrap-ssh` may use the serial console to:

- install an operator public key into `/root/.ssh/authorized_keys`,
- start `sshd`,
- leave private keys, passwords, and tokens untouched.

`make vm-ssh` must fail with a clear message if the forwarded port or discovered IP is not reachable.

`make vm-rsync` must use the discovered SSH endpoint, the IP discovered by `vm-ip`, or an explicitly provided `VM_IP`. It must not copy secrets, `.env`, private keys, local credentials, or ignored large artifacts unless explicitly documented and approved.

## 11. Console Strategy
`make vm-console` should use:

```sh
virsh --connect "$LIBVIRT_URI" console "$VM_NAME"
```

The domain should expose a serial console. The official ISO stock GRUB path uses graphical output, so the workflow boots the official kernel and initrd extracted from the ISO while keeping the ISO attached as the live root media. The generated domain must pass `console=tty0 console=ttyS0,115200n8`. This must not modify the ISO or create a custom ISO.

`make vm-viewer` should be available when graphical access is needed to complete live ISO setup. It should use `virt-viewer --connect "$LIBVIRT_URI" "$VM_NAME"` or an equivalent documented command through Makefile.

## 12. Safety Gates
Path safety rules must be shared with or equivalent to the current QEMU scripts:

- Reject VM disk paths under `/dev/`.
- Reject absolute VM disk paths unless a future change explicitly approves a safe project-root canonicalization model.
- Reject parent traversal.
- Reject project-root artifact directories such as `.`, `./`, and `./.`.
- Reject wildcard characters.
- Reject libvirt or shell option injection characters in operator-controlled paths.
- Reject XML-special characters in the project root path before generating libvirt domain XML.
- Reject symlinked artifact directories and symlinked path components.
- Reject existing disk files that are not qcow2 according to `qemu-img info`.
- Preserve existing qcow2 disks rather than overwriting them.
- Validate SSH ports as numeric ports in an allowed range.
- Reject network and SSH configurations that are empty, ambiguous, or contain shell/libvirt option injection characters.
- Delete only known generated artifacts during cleanup.

Domain safety rules:

- `VM_NAME` must be validated against a conservative domain-name pattern.
- Generated domains must include a project ownership marker.
- `vm-define` must refuse to replace an existing unrelated domain with the same name.
- `vm-start`, `vm-console`, `vm-viewer`, `vm-ip`, SSH, rsync, and Ansible target discovery must require the existing domain to match the configured official ISO and generated artifacts.
- `vm-clean` must operate only on the configured `VM_NAME`.
- `vm-clean`, `vm-destroy`, `vm-shutdown`, and `vm-define` may operate on stale project-marked domains only when those domains do not reference host block devices.
- `vm-clean` must show the domain and file paths it will remove.
- `vm-clean` must require `DELETE`.
- `vm-clean` must not delete libvirt networks, pools, unrelated domains, or unrelated volumes.
- `vm-destroy` must stop only the configured domain and must not delete disk images.
- The domain must not be configured for autostart by default.

## 13. UEFI and Serial Boot
UEFI remains mandatory in v1.

The tested workflow boots the official kernel and initrd extracted from the official ISO, with the ISO still attached as the live root media. This is not a custom ISO and does not modify the ISO. The kernel command line must include serial console arguments so `virsh console` reaches the live ISO prompt.

## 14. Automation Boundary
This change is about VM lifecycle and access automation, not Gentoo installation automation.

Allowed automation:

- create a safe qcow2 disk,
- define a libvirt domain,
- start and stop the VM,
- find its IP,
- open console,
- bootstrap temporary SSH access in the live ISO with an operator public key,
- SSH after the live ISO is prepared,
- rsync non-secret project files,
- validate Ansible connectivity with `make vm-ansible-ping`.

Not allowed in this change:

- partition the guest disk,
- format filesystems,
- install stage3,
- configure Portage,
- create installed-system users,
- install GRUB,
- run Ansible installer playbooks.

## 15. Documentation Updates Required
Implementation must update:

- `README.md`: concise target list and libvirt workflow pointer.
- `AGENTS.md`: QEMU documentation rule should become virtualization/libvirt workflow guidance.
- `docs/qemu-manual-install-test.md`: replace with migration note or remove when no longer accurate.
- `docs/libvirt-manual-install-test.md`: detailed virsh workflow.
- `skills/makefile-control-plane.md`: new VM targets and variables.
- Relevant QEMU/live environment skills: ISO path, qcow2 path, libvirt network, SSH, cleanup, and guest `/dev/vda`.
- `agents/safety-review-agent.md`: libvirt/domain cleanup review checks.
- `openspec/changes/migrate-qemu-workflow-to-libvirt-virsh/tasks.md`: documentation tasks.

## 16. Review Checklist
Before implementation is accepted:

- Are all operator-facing actions Makefile targets?
- Is direct QEMU no longer the documented operator-facing workflow?
- Does `vm-check` remain read-only?
- Are disk paths confined to project artifacts?
- Are host block devices rejected?
- Are dot-equivalent project-root artifact directories rejected?
- Are symlinked paths rejected?
- Are existing non-qcow2 files rejected?
- Does cleanup delete only generated artifacts after `DELETE`?
- Does `vm-clean` avoid unrelated domains, pools, networks, and volumes?
- Does `vm-ssh` fail clearly when SSH is not ready?
- Does the default managed network provide DHCP lease discovery?
- Does `vm-console` show the live ISO prompt?
- Does `vm-ansible-ping` validate connectivity without running installer playbooks?
- Does managed network mode validate `VM_NETWORK` before use?
- Are secrets excluded from rsync and docs?
- Does documentation clearly label planned versus implemented behavior?
- Do OpenSpec validations pass?

## 17. Exhaustive Alignment Notes
Alignment with prior QEMU work:

- Keep `./gentoo.iso`: aligned.
- Keep qcow2 under project artifacts: aligned, but move default from `var/qemu` to `var/libvirt` or document aliases.
- Keep 40G sparse disk: aligned.
- Keep UEFI only: aligned.
- Keep no custom ISO: aligned.
- Keep no host block devices: aligned.
- Keep Makefile control plane: aligned.
- Keep `qemu-check` read-only principle as `vm-check`: aligned.
- Keep cleanup confirmation: aligned.
- Replace `qemu-boot`: not aligned; should become `vm-start`/`vm-console`.
- Add forwarded SSH, optional IP discovery, and rsync: new required behavior.
- Preserve Ansible phase separation: aligned; this change prepares access but does not implement installer playbooks.

Potential conflicts to resolve during implementation:

- `docs/qemu-manual-install-test.md` currently presents direct QEMU as active.
- `Makefile` currently exposes `qemu-*` targets.
- `scripts/qemu-*` currently implement direct QEMU.
- `AGENTS.md` currently has a QEMU documentation rule rather than a generic VM/libvirt rule.
- `.gitignore` currently ignores `var/qemu/*.qcow2` and `var/qemu/*.fd`; libvirt artifacts under `var/libvirt/` must be ignored too.
