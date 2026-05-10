# Design: implement-live-iso-local-ansible-control-plane

## Execution Modes
- `vm`: controller runs Ansible over SSH into the libvirt live ISO VM for tests.
- `local`: Ansible runs inside the booted official Gentoo live ISO.

## Makefile Model
Expose operator-facing local targets through Makefile. The target names may either be explicit, such as `local-install-plan`, or parameterized with an execution-mode variable if the implementation keeps behavior clear.

## Inventory
Create `ansible/inventory/local.yml` with one host representing the live ISO and `ansible_connection=local`.

Local inventory must not rely on globally disabled host-key checking. Host-key exceptions are only valid for host-to-temporary-live-ISO SSH wrappers, not for local execution inside the live ISO.

## Safety
Local mode does not reduce confirmation requirements. It must still require explicit `INSTALL_DISK` for disk plans and future destructive work.

## Quality Gates
Local Ansible playbooks, inventories, and wrappers must satisfy the project Ansible quality standards and be covered by `make ansible-check`.

## Documentation
Docs must make clear which commands run on the host and which commands run inside the live ISO.
