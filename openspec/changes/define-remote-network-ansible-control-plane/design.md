# Design: define-remote-network-ansible-control-plane

## Primary Execution Model
The normal installer model is:

1. The operator boots the official Gentoo live ISO on the target machine.
2. The target becomes reachable over the network by SSH.
3. The operator runs Makefile targets from the controller machine.
4. The Makefile wrappers run Ansible against the live ISO target.
5. Ansible modifies only the selected target after plan and safety gates pass.

The target may be physical hardware, a remote VM, or the project libvirt VM. Reusable Ansible roles must not care which one it is.

## Makefile Variables
Network live ISO target selection uses:

- `ANSIBLE_LIVE_HOST`: explicit target address or DNS name. No default.
- `ANSIBLE_LIVE_PORT`: SSH port. Default may be `22`.
- `ANSIBLE_LIVE_USER`: SSH user. Default may be `root` for the official live ISO.

If `ANSIBLE_LIVE_HOST` is empty, wrappers may discover the configured local libvirt VM for validation. That fallback is a test harness convenience only.

## Inventory and Role Rules
- Roles must be inventory-driven.
- Roles must not call `virsh`.
- Roles must not read `VM_NAME`, `VM_DISK`, `VM_DIR`, or local qcow2 paths.
- Roles must not assume `/dev/vda`; disk paths must come from target-side detection and explicit operator input.
- Inventory examples must not contain secrets or default install disks.

## Local Harness Boundary
libvirt/virsh owns:

- booting `./gentoo.iso`,
- creating qcow2 disks under `./var/libvirt/`,
- serial-console SSH bootstrap for the live ISO,
- VM IP discovery,
- VM rsync helpers,
- VM cleanup.

Ansible owns:

- preflight checks,
- disk detection,
- install, partition, mount, filesystem, stage3, chroot, Portage, kernel, bootloader, user, SSH, final-check, logging, and audit roles as they are implemented through approved changes.

## Documentation Rules
- README should stay concise and identify Ansible as the product path.
- Detailed VM/libvirt docs must say they are local test harness docs.
- Ansible architecture docs must describe controller, target, inventory, Makefile variables, and harness boundaries.
- OpenSpec implementation changes must say whether behavior is reusable Ansible behavior or local harness behavior.

## Review Checklist
Before approving future Ansible work:

- Does the behavior work against a network live ISO target selected by `ANSIBLE_LIVE_HOST` or inventory?
- Are VM-specific assumptions isolated to scripts/docs/tests?
- Is `install_disk` still explicit and default-free?
- Does the Makefile expose the operator workflow?
- Does the implementation follow Ansible quality rules and reuse-first OpenRC/systemd architecture?
- Are documentation and OpenSpec tasks updated?
