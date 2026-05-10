SHELL := /usr/bin/env bash

LIBVIRT_URI ?= qemu:///system
VM_NET_MODE ?= network
VM_NAME ?= gentoo-ai-installer
VM_ISO ?= gentoo.iso
VM_DIR ?= var/libvirt
VM_DISK ?= $(VM_DIR)/gentoo-ai-installer.qcow2
VM_DISK_SIZE ?= 40G
VM_RAM ?= 4096
VM_CPUS ?= 2
VM_NETWORK ?= default
VM_SSH_HOST ?= 127.0.0.1
VM_SSH_HOST_PORT ?= 2222
VM_SSH_GUEST_PORT ?= 22
VM_SSH_USER ?= root
VM_BOOT_MODE ?= uefi
VM_KERNEL_ARGS ?= dokeymap nodhcp root=live:CDLABEL=Gentoo-amd64-20260426 rd.live.dir=/ rd.live.squashimg=image.squashfs cdroot console=tty0 console=ttyS0,115200n8
PROFILE ?= openrc
FILESYSTEM ?= ext4

export LIBVIRT_URI
export VM_NET_MODE
export VM_NAME
export VM_ISO
export VM_DIR
export VM_DISK
export VM_DISK_SIZE
export VM_RAM
export VM_CPUS
export VM_NETWORK
export VM_SSH_HOST
export VM_SSH_HOST_PORT
export VM_SSH_GUEST_PORT
export VM_SSH_USER
export VM_BOOT_MODE
export VM_KERNEL_ARGS
export PROFILE
export FILESYSTEM
export INSTALL_DISK

.PHONY: help \
	vm-check vm-disk vm-define vm-start vm-console vm-viewer vm-ip vm-bootstrap-ssh vm-ssh vm-rsync vm-ansible-ping vm-shutdown vm-destroy vm-clean \
	ansible-check ansible-live-ping ansible-live-preflight detect-disks install-plan \
	qemu-check qemu-disk qemu-boot qemu-clean

help:
	@printf '%s\n' \
		'gentoo-ai-installer targets:' \
		'  make vm-check        Verify libvirt tools, ISO, UEFI, network mode, and safe paths' \
		'  make vm-disk         Create the project-local qcow2 VM disk if missing' \
		'  make vm-define       Generate and define the libvirt domain' \
		'  make vm-start        Start the libvirt VM from the official Gentoo ISO' \
		'  make vm-console      Attach to virsh console for the VM' \
		'  make vm-viewer       Open graphical access with virt-viewer' \
		'  make vm-ip           Discover guest IP when managed networking supports it' \
		'  make vm-bootstrap-ssh Configure SSH authorized_keys and start sshd via serial console' \
		'  make vm-ssh          SSH to the live ISO after SSH is enabled in the guest' \
		'  make vm-rsync        Copy non-secret project files to the guest over SSH' \
		'  make vm-ansible-ping Validate Ansible connectivity to the live ISO over SSH' \
		'  make ansible-check   Verify Ansible tooling and syntax for implemented playbooks' \
		'  make ansible-live-ping Validate Ansible connectivity using project inventory' \
		'  make ansible-live-preflight Run read-only live ISO Ansible preflight' \
		'  make detect-disks    Run read-only Ansible disk detection in the live ISO' \
		'  make install-plan    Generate read-only Ansible install plan (PROFILE=openrc|systemd FILESYSTEM=ext4|btrfs)' \
		'  make vm-shutdown     Request clean guest shutdown' \
		'  make vm-destroy      Stop the configured VM without deleting artifacts' \
		'  make vm-clean        Undefine VM and delete generated artifacts after confirmation' \
		'' \
		'Compatibility aliases:' \
		'  make qemu-check      Alias for vm-check' \
		'  make qemu-disk       Alias for vm-disk' \
		'  make qemu-boot       Alias for vm-start' \
		'  make qemu-clean      Alias for vm-clean' \
		'' \
		'VM variables:' \
		'  LIBVIRT_URI=$(LIBVIRT_URI)' \
		'  VM_NET_MODE=$(VM_NET_MODE)' \
		'  VM_NAME=$(VM_NAME)' \
		'  VM_ISO=$(VM_ISO)' \
		'  VM_DIR=$(VM_DIR)' \
		'  VM_DISK=$(VM_DISK)' \
		'  VM_DISK_SIZE=$(VM_DISK_SIZE)' \
		'  VM_RAM=$(VM_RAM)' \
		'  VM_CPUS=$(VM_CPUS)' \
		'  VM_NETWORK=$(VM_NETWORK)' \
		'  VM_SSH_HOST=$(VM_SSH_HOST)' \
		'  VM_SSH_HOST_PORT=$(VM_SSH_HOST_PORT)' \
		'  VM_SSH_GUEST_PORT=$(VM_SSH_GUEST_PORT)' \
		'  VM_SSH_USER=$(VM_SSH_USER)' \
		'  VM_BOOT_MODE=$(VM_BOOT_MODE)' \
		'  VM_KERNEL_ARGS=$(VM_KERNEL_ARGS)' \
		'  PROFILE=$(PROFILE)' \
		'  FILESYSTEM=$(FILESYSTEM)' \
		'  INSTALL_DISK has no default; pass INSTALL_DISK=/dev/vda only deliberately inside the VM'

vm-check:
	@scripts/vm-check-libvirt.sh

vm-disk:
	@scripts/vm-create-disk.sh

vm-define: vm-disk
	@scripts/vm-define-libvirt-domain.sh

vm-start: vm-disk
	@if ! virsh --connect "$(LIBVIRT_URI)" dominfo "$(VM_NAME)" >/dev/null 2>&1; then scripts/vm-define-libvirt-domain.sh; fi
	@scripts/vm-start.sh

vm-console:
	@scripts/vm-console.sh

vm-viewer:
	@scripts/vm-viewer.sh

vm-ip:
	@scripts/vm-ip.sh

vm-bootstrap-ssh:
	@scripts/vm-bootstrap-live-ssh.py

vm-ssh:
	@scripts/vm-ssh.sh

vm-rsync:
	@scripts/vm-rsync.sh

vm-ansible-ping:
	@scripts/vm-ansible-ping.sh

ansible-check:
	@scripts/ansible-check.sh

ansible-live-ping:
	@scripts/ansible-live-ping.sh

ansible-live-preflight:
	@scripts/ansible-live-preflight.sh

detect-disks:
	@scripts/ansible-detect-disks.sh

install-plan:
	@scripts/ansible-install-plan.sh

vm-shutdown:
	@scripts/vm-shutdown.sh

vm-destroy:
	@scripts/vm-destroy.sh

vm-clean:
	@scripts/vm-clean.sh

qemu-check: vm-check
	@printf '%s\n' 'qemu-check is a compatibility alias; libvirt/virsh vm-check is the active workflow.'

qemu-disk: vm-disk
	@printf '%s\n' 'qemu-disk is a compatibility alias; libvirt/virsh vm-disk is the active workflow.'

qemu-boot: vm-start
	@printf '%s\n' 'qemu-boot is a compatibility alias; libvirt/virsh vm-start is the active workflow.'

qemu-clean: vm-clean
	@printf '%s\n' 'qemu-clean is a compatibility alias; libvirt/virsh vm-clean is the active workflow.'
