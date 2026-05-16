#!/usr/bin/env python3
"""Proxmox VE validation harness for gentoo-ai-installer."""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import subprocess
import sys
import time
from concurrent.futures import FIRST_COMPLETED, ThreadPoolExecutor, wait
from datetime import datetime, timezone
from pathlib import Path


PROJECT_MARKER = "gentoo-ai-installer-managed-proxmox-vm"
PLATFORM = "amd64"
CASES = [
    ("openrc", "ext4", "standard"),
    ("openrc", "btrfs", "standard"),
    ("systemd", "ext4", "standard"),
    ("systemd", "btrfs", "standard"),
    ("openrc", "ext4", "hardened"),
    ("openrc", "btrfs", "hardened"),
    ("systemd", "ext4", "hardened"),
    ("systemd", "btrfs", "hardened"),
    ("openrc", "ext4", "musl"),
    ("openrc", "btrfs", "musl"),
    ("systemd", "ext4", "musl"),
    ("systemd", "btrfs", "musl"),
]


def die(code: str, message: str) -> None:
    print(f"proxmox: {code}: {message}", file=sys.stderr)
    raise SystemExit(1)


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default).strip()


def env_default(name: str, default: str) -> str:
    value = env(name)
    return value if value else default


def require_safe_name(label: str, value: str) -> None:
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,62}", value):
        die("PROXMOX_CONFIG_INVALID", f"{label} must be a conservative name: {value}")


def require_safe_token(label: str, value: str) -> None:
    if not re.fullmatch(r"[A-Za-z0-9_.:+/@-]+", value):
        die("PROXMOX_CONFIG_INVALID", f"{label} contains unsupported characters: {value}")


def require_int(label: str, value: str, minimum: int, maximum: int) -> int:
    if not value.isdigit():
        die("PROXMOX_CONFIG_INVALID", f"{label} must be numeric: {value}")
    number = int(value)
    if number < minimum or number > maximum:
        die("PROXMOX_CONFIG_INVALID", f"{label} must be between {minimum} and {maximum}: {value}")
    return number


def case_key(profile: str, filesystem: str, flavor: str) -> str:
    suffix = "" if flavor == "standard" else f"-{flavor}"
    return f"{PLATFORM}-{profile}-{filesystem}{suffix}"


def case_name(base: str, label: str, profile: str, filesystem: str, flavor: str) -> str:
    prefix = f"{base}-{label}" if label else base
    name = f"{prefix}-{case_key(profile, filesystem, flavor)}"
    require_safe_name("VM name", name)
    return name


def selected_case_index(profile: str, filesystem: str, flavor: str) -> int:
    try:
        return CASES.index((profile, filesystem, flavor))
    except ValueError:
        die("PROXMOX_CASE_INVALID", f"unsupported case: {profile}/{filesystem}/{flavor}")


def ip_for_index(base_ip: str, index: int) -> str:
    parts = base_ip.split(".")
    if len(parts) != 4 or not all(part.isdigit() for part in parts):
        die("PROXMOX_CONFIG_INVALID", f"PROXMOX_IP_BASE must be IPv4: {base_ip}")
    last = int(parts[3]) + index
    if last > 254:
        die("PROXMOX_CONFIG_INVALID", f"derived IP octet exceeds 254 from {base_ip} index {index}")
    return ".".join(parts[:3] + [str(last)])


class Config:
    def __init__(self) -> None:
        self.ssh_host = env("PROXMOX_HOST", "100.64.60.211")
        self.node = env("PROXMOX_NODE", "pve-node10")
        self.storage = env("PROXMOX_STORAGE", "ceph_low_prio")
        self.bridge = env("PROXMOX_BRIDGE", "vmbr0")
        self.vlan = require_int("PROXMOX_VLAN", env("PROXMOX_VLAN", "1070"), 1, 4094)
        self.iso = env("PROXMOX_ISO", "local:iso/install-amd64-minimal-20260510T170106Z.iso")
        self.vmid_base = require_int("PROXMOX_VMID_BASE", env("PROXMOX_VMID_BASE", "73000"), 100, 999999999)
        self.vmid = env("PROXMOX_VMID")
        self.disk_size = env("PROXMOX_DISK_SIZE", "80G")
        self.ram = require_int("PROXMOX_RAM", env("PROXMOX_RAM", "16384"), 512, 1048576)
        self.cpus = require_int("PROXMOX_CPUS", env("PROXMOX_CPUS", "4"), 1, 256)
        self.ip_base = env("PROXMOX_IP_BASE", "10.64.70.99")
        self.gateway = env("PROXMOX_GATEWAY", "10.64.70.1")
        self.netmask = env("PROXMOX_NETMASK", "255.255.255.0")
        self.dns = env("PROXMOX_DNS", "1.1.1.1")
        self.base_name = env("VM_NAME", "gentoo-test")
        self.test_label = env("VM_TEST_IMAGE_NAME")
        self.install_disk = env("INSTALL_DISK", "")
        self.access_install_disk = env_default("PROXMOX_ACCESS_INSTALL_DISK", "/dev/sda")
        self.matrix_parallel = require_int("PROXMOX_MATRIX_PARALLEL", env("PROXMOX_MATRIX_PARALLEL", "4"), 1, len(CASES))
        self.public_key_file = env("ADMIN_AUTHORIZED_KEYS_FILE") or str(Path.home() / ".ssh/id_ed25519.pub")
        self.admin_user = env_default("ADMIN_USER", "aladroc")
        self.enable_ssh = env_default("ENABLE_SSH", "yes")
        self.enable_qemu_guest_agent = env("ENABLE_QEMU_GUEST_AGENT", "yes")
        self.reset_vm = env("PROXMOX_RESET_VM", "no")
        self.cleanup_confirm = env("I_UNDERSTAND_CLEANUP_DELETE")
        self.wipe_confirm = env("I_UNDERSTAND_THIS_WIPES_DISK")
        self.bootloader_confirm = env("I_UNDERSTAND_BOOTLOADER_CHANGES")
        self.admin_sudo_nopasswd = env("ADMIN_SUDO_NOPASSWD", env("VM_E2E_ADMIN_SUDO_NOPASSWD", "yes"))
        self.log_root = Path(env("PROXMOX_E2E_MATRIX_LOG_DIR", "logs/proxmox-e2e-matrix"))

        for label, value in (
            ("PROXMOX_HOST", self.ssh_host),
            ("PROXMOX_NODE", self.node),
            ("PROXMOX_STORAGE", self.storage),
            ("PROXMOX_BRIDGE", self.bridge),
            ("PROXMOX_ISO", self.iso),
            ("VM_NAME", self.base_name),
        ):
            require_safe_token(label, value)
        if self.test_label:
            require_safe_name("VM_TEST_IMAGE_NAME", self.test_label)
        require_safe_name("ADMIN_USER", self.admin_user)
        if not re.fullmatch(r"[0-9]+[GMTP]?", self.disk_size):
            die("PROXMOX_CONFIG_INVALID", f"PROXMOX_DISK_SIZE must be a simple size such as 80G: {self.disk_size}")
        if self.install_disk and self.install_disk not in ("/dev/sda", "/dev/vda"):
            die("DISK_UNSAFE", "Proxmox E2E currently accepts explicit INSTALL_DISK=/dev/sda or /dev/vda only")
        if self.access_install_disk not in ("/dev/sda", "/dev/vda"):
            die("DISK_UNSAFE", "Proxmox installed-access repair accepts PROXMOX_ACCESS_INSTALL_DISK=/dev/sda or /dev/vda only")
        if self.enable_qemu_guest_agent not in ("yes", "no"):
            die("PROXMOX_CONFIG_INVALID", "ENABLE_QEMU_GUEST_AGENT must be yes or no")

    def case(self, profile: str, filesystem: str, flavor: str) -> dict[str, str | int]:
        index = selected_case_index(profile, filesystem, flavor)
        vmid = int(self.vmid) if self.vmid else self.vmid_base + index
        name = case_name(self.base_name, self.test_label, profile, filesystem, flavor)
        return {
            "index": index,
            "profile": profile,
            "filesystem": filesystem,
            "stage3_flavor": flavor,
            "case": case_key(profile, filesystem, flavor),
            "name": name,
            "vmid": vmid,
            "ip": ip_for_index(self.ip_base, index),
        }


def run(cmd: list[str], *, check: bool = True, env_vars: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env_vars)
    if check and result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        die("COMMAND_FAILED", f"{' '.join(shlex.quote(part) for part in cmd)}\n{detail}")
    return result


def ssh(cfg: Config, remote: str, *, check: bool = True) -> subprocess.CompletedProcess[str]:
    return run(
        ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=15", "-o", "StrictHostKeyChecking=accept-new", f"root@{cfg.ssh_host}", remote],
        check=check,
    )


def qm(cfg: Config, args: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    quoted = " ".join(shlex.quote(arg) for arg in ["qm", *args])
    return ssh(cfg, quoted, check=check)


def pvesm(cfg: Config, args: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    quoted = " ".join(shlex.quote(arg) for arg in ["pvesm", *args])
    return ssh(cfg, quoted, check=check)


def guest_ssh(host: str, user: str, remote: str, *, check: bool = True, timeout: int = 15) -> subprocess.CompletedProcess[str]:
    return run(
        [
            "ssh",
            "-o",
            "BatchMode=yes",
            "-o",
            f"ConnectTimeout={timeout}",
            "-o",
            "StrictHostKeyChecking=no",
            "-o",
            "UserKnownHostsFile=/dev/null",
            f"{user}@{host}",
            remote,
        ],
        check=check,
    )


def qm_config(cfg: Config, vmid: int) -> str:
    result = qm(cfg, ["config", str(vmid)], check=False)
    return result.stdout if result.returncode == 0 else ""


def vm_exists(cfg: Config, vmid: int) -> bool:
    return qm(cfg, ["status", str(vmid)], check=False).returncode == 0


def require_owned(cfg: Config, vmid: int, name: str) -> None:
    config = qm_config(cfg, vmid)
    if PROJECT_MARKER not in config or f"name: {name}" not in config:
        die("PROXMOX_OWNERSHIP_MISMATCH", f"VMID {vmid} is not the expected project-owned VM {name}")


def ensure_guest_agent_channel(cfg: Config, vmid: int) -> None:
    qm(cfg, ["set", str(vmid), "--agent", "enabled=1"])


def iso_local_path(iso: str) -> str:
    match = re.fullmatch(r"local:iso/([^/]+\.iso)", iso)
    if not match:
        die("PROXMOX_CONFIG_INVALID", "initial Proxmox implementation requires PROXMOX_ISO like local:iso/<file>.iso")
    return f"/var/lib/vz/template/iso/{match.group(1)}"


def remote_snippet_paths(name: str) -> tuple[str, str]:
    safe = re.sub(r"[^A-Za-z0-9_.-]", "-", name)
    return (f"/var/lib/vz/snippets/{safe}-gentoo-kernel", f"/var/lib/vz/snippets/{safe}-gentoo-initrd")


def remote_iso_label(cfg: Config) -> str:
    iso_path = iso_local_path(cfg.iso)
    script = f"isoinfo -d -i {shlex.quote(iso_path)} | awk -F': ' '/^Volume id:/ {{ print $2; exit }}'"
    result = ssh(cfg, script)
    label = result.stdout.strip()
    if not re.fullmatch(r"[A-Za-z0-9._:-]+", label):
        die("PROXMOX_ISO_INVALID", f"could not read safe ISO volume label from {cfg.iso}: {label}")
    return label


def kernel_args(cfg: Config, case: dict[str, str | int]) -> str:
    label = remote_iso_label(cfg)
    hostname = str(case["name"])
    ip = str(case["ip"])
    return (
        f"dokeymap root=live:CDLABEL={label} rd.live.dir=/ rd.live.squashimg=image.squashfs cdroot "
        "console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 rd.neednet=1 "
        f"ip={ip}::{cfg.gateway}:{cfg.netmask}:{hostname}:eth0:none nameserver={cfg.dns}"
    )


def proxmox_disk_size(size: str) -> str:
    match = re.fullmatch(r"([0-9]+)G?", size)
    if not match:
        die("PROXMOX_CONFIG_INVALID", f"initial Proxmox disk creation requires a GiB size such as 80G: {size}")
    return match.group(1)


def ensure_kernel_artifacts(cfg: Config, case: dict[str, str | int]) -> tuple[str, str]:
    iso_path = iso_local_path(cfg.iso)
    kernel, initrd = remote_snippet_paths(str(case["name"]))
    script = (
        "set -euo pipefail; "
        "mkdir -p /var/lib/vz/snippets; "
        f"test -f {shlex.quote(iso_path)}; "
        f"isoinfo -i {shlex.quote(iso_path)} -R -x /boot/gentoo > {shlex.quote(kernel)}; "
        f"isoinfo -i {shlex.quote(iso_path)} -R -x /boot/gentoo.igz > {shlex.quote(initrd)}; "
        f"chmod 0644 {shlex.quote(kernel)} {shlex.quote(initrd)}"
    )
    ssh(cfg, script)
    return kernel, initrd


def print_case(cfg: Config, case: dict[str, str | int]) -> None:
    print(
        json.dumps(
            {
                **case,
                "node": cfg.node,
                "host": cfg.ssh_host,
                "storage": cfg.storage,
                "bridge": cfg.bridge,
                "vlan": cfg.vlan,
                "iso": cfg.iso,
                "disk_size": cfg.disk_size,
                "ram": cfg.ram,
                "cpus": cfg.cpus,
                "expected_install_disk": cfg.install_disk or "<explicit INSTALL_DISK required for install>",
            },
            indent=2,
            sort_keys=True,
        )
    )


def check(cfg: Config) -> None:
    ssh(cfg, "command -v qm >/dev/null && command -v pvesm >/dev/null && command -v isoinfo >/dev/null")
    pvesm(cfg, ["status"])
    ssh(cfg, f"test -f {shlex.quote(iso_local_path(cfg.iso))}")
    storage = pvesm(cfg, ["status"]).stdout
    if not any(line.split()[0] == cfg.storage and "active" in line.split() for line in storage.splitlines()[1:] if line.split()):
        die("PROXMOX_STORAGE_INVALID", f"storage is not active on {cfg.ssh_host}: {cfg.storage}")
    network = ssh(cfg, f"pvesh get /nodes/{shlex.quote(cfg.node)}/network --output-format json").stdout
    if f'"iface":"{cfg.bridge}"' not in network and f'"iface": "{cfg.bridge}"' not in network:
        die("PROXMOX_NETWORK_INVALID", f"bridge not found on {cfg.node}: {cfg.bridge}")
    print("proxmox-check: ok")
    print(f"  node={cfg.node} host={cfg.ssh_host}")
    print(f"  storage={cfg.storage} bridge={cfg.bridge} vlan={cfg.vlan}")
    print(f"  iso={cfg.iso}")


def list_cases(cfg: Config) -> None:
    for profile, filesystem, flavor in CASES:
        print_case(cfg, cfg.case(profile, filesystem, flavor))


def create_vm(cfg: Config, case: dict[str, str | int]) -> None:
    vmid = int(case["vmid"])
    name = str(case["name"])
    if vm_exists(cfg, vmid):
        if cfg.reset_vm == "yes":
            clean_vm(cfg, case)
        else:
            require_owned(cfg, vmid, name)
            ensure_guest_agent_channel(cfg, vmid)
            print(f"proxmox-vm-create: preserving existing project-owned VM {vmid} {name}")
            return

    kernel, initrd = ensure_kernel_artifacts(cfg, case)
    append = kernel_args(cfg, case)
    args = f"-kernel {shlex.quote(kernel)} -initrd {shlex.quote(initrd)} -append {shlex.quote(append)}"
    description = f"{PROJECT_MARKER} case={case['case']} ip={case['ip']}"

    qm(cfg, ["create", str(vmid), "--name", name, "--memory", str(cfg.ram), "--cores", str(cfg.cpus), "--cpu", "host",
             "--machine", "q35", "--bios", "ovmf", "--ostype", "l26", "--serial0", "socket", "--vga", "serial0",
             "--description", description, "--tags", "gentoo-ai-installer;gentoo-test", "--onboot", "0"])
    qm(cfg, ["set", str(vmid), "--net0", f"virtio,bridge={cfg.bridge},tag={cfg.vlan}"])
    qm(cfg, ["set", str(vmid), "--scsihw", "virtio-scsi-single", "--scsi0", f"{cfg.storage}:{proxmox_disk_size(cfg.disk_size)},iothread=1,discard=on"])
    qm(cfg, ["set", str(vmid), "--efidisk0", f"{cfg.storage}:1,efitype=4m,pre-enrolled-keys=0"])
    qm(cfg, ["set", str(vmid), "--ide2", f"{cfg.iso},media=cdrom"])
    qm(cfg, ["set", str(vmid), "--boot", "order=ide2;scsi0"])
    qm(cfg, ["set", str(vmid), "--args", args])
    ensure_guest_agent_channel(cfg, vmid)
    require_owned(cfg, vmid, name)
    print(f"proxmox-vm-create: created {vmid} {name} ip={case['ip']}")


def create_all(cfg: Config) -> None:
    for profile, filesystem, flavor in CASES:
        create_vm(cfg, cfg.case(profile, filesystem, flavor))


def stop_running_vm(cfg: Config, vmid: int, name: str) -> bool:
    status = qm(cfg, ["status", str(vmid)]).stdout
    if "status: running" not in status:
        return False
    qm(cfg, ["stop", str(vmid), "--skiplock"], check=False)
    for _ in range(30):
        time.sleep(2)
        if "status: stopped" in qm(cfg, ["status", str(vmid)], check=False).stdout:
            return True
    die("PROXMOX_STOP_TIMEOUT", f"VM did not stop before boot mode switch: {vmid} {name}")
    return True


def start_vm(cfg: Config, case: dict[str, str | int]) -> None:
    vmid = int(case["vmid"])
    name = str(case["name"])
    require_owned(cfg, vmid, name)
    was_running = stop_running_vm(cfg, vmid, name)
    kernel, initrd = ensure_kernel_artifacts(cfg, case)
    append = kernel_args(cfg, case)
    args = f"-kernel {shlex.quote(kernel)} -initrd {shlex.quote(initrd)} -append {shlex.quote(append)}"
    qm(cfg, ["set", str(vmid), "--ide2", f"{cfg.iso},media=cdrom"])
    qm(cfg, ["set", str(vmid), "--boot", "order=ide2;scsi0"])
    qm(cfg, ["set", str(vmid), "--args", args])
    qm(cfg, ["start", str(vmid)])
    action = "restarted" if was_running else "started"
    print(f"proxmox-vm-start: {action} {vmid} {name} in live ISO mode")


def start_installed_vm(cfg: Config, case: dict[str, str | int]) -> None:
    vmid = int(case["vmid"])
    name = str(case["name"])
    require_owned(cfg, vmid, name)
    was_running = stop_running_vm(cfg, vmid, name)
    qm(cfg, ["set", str(vmid), "--ide2", "none,media=cdrom"])
    qm(cfg, ["set", str(vmid), "--boot", "order=scsi0", "--delete", "args"])
    qm(cfg, ["start", str(vmid)])
    action = "restarted" if was_running else "started"
    print(f"proxmox-vm-start-installed: {action} {vmid} {name} from installed disk scsi0")


def start_installed_all(cfg: Config) -> None:
    for profile, filesystem, flavor in CASES:
        start_installed_vm(cfg, cfg.case(profile, filesystem, flavor))


def shutdown_vm(cfg: Config, case: dict[str, str | int]) -> None:
    vmid = int(case["vmid"])
    name = str(case["name"])
    require_owned(cfg, vmid, name)
    status = qm(cfg, ["status", str(vmid)]).stdout
    if "status: stopped" in status:
        print(f"proxmox-vm-shutdown: already stopped {vmid} {name}")
        return
    qm(cfg, ["shutdown", str(vmid), "--timeout", "120"], check=False)
    for _ in range(24):
        time.sleep(5)
        if "status: stopped" in qm(cfg, ["status", str(vmid)], check=False).stdout:
            print(f"proxmox-vm-shutdown: stopped {vmid} {name}")
            return
    die("PROXMOX_SHUTDOWN_TIMEOUT", f"VM did not shut down cleanly: {vmid} {name}")


def clean_vm(cfg: Config, case: dict[str, str | int]) -> None:
    if cfg.cleanup_confirm != "DELETE":
        die("CONFIRMATION_MISSING", "Proxmox cleanup requires I_UNDERSTAND_CLEANUP_DELETE=DELETE")
    vmid = int(case["vmid"])
    name = str(case["name"])
    if not vm_exists(cfg, vmid):
        print(f"proxmox-vm-clean: VM does not exist: {vmid} {name}")
        return
    require_owned(cfg, vmid, name)
    qm(cfg, ["stop", str(vmid), "--skiplock"], check=False)
    result = qm(cfg, ["destroy", str(vmid), "--purge", "1", "--destroy-unreferenced-disks", "1"], check=False)
    if result.returncode != 0:
        qm(cfg, ["destroy", str(vmid), "--purge", "1"])
    print(f"proxmox-vm-clean: destroyed project-owned VM {vmid} {name}")


def read_public_key(path_text: str) -> str:
    path = Path(path_text).expanduser()
    if not path.is_file():
        die("PROXMOX_CONFIG_INVALID", f"public key file not found: {path_text}")
    text = path.read_text(encoding="utf-8").strip()
    if "PRIVATE KEY" in text:
        die("SECRET_INPUT_INVALID", "ADMIN_AUTHORIZED_KEYS_FILE must contain public keys only")
    first = next((line.strip() for line in text.splitlines() if line.strip()), "")
    if not re.match(r"^(ssh-ed25519|ssh-rsa|ecdsa-sha2-|sk-)", first):
        die("PROXMOX_CONFIG_INVALID", "public key file does not contain a supported OpenSSH public key")
    return first


def bootstrap_ssh(cfg: Config, case: dict[str, str | int]) -> None:
    vmid = int(case["vmid"])
    key = read_public_key(cfg.public_key_file)
    marker = "GENTOO_AI_INSTALLER_PROXMOX_SSH_READY"
    ip = str(case["ip"])
    commands = [
        "mkdir -p /root/.ssh",
        f"printf '%s\\n' {shlex.quote(key)} > /root/.ssh/authorized_keys",
        "chmod 700 /root/.ssh",
        "chmod 600 /root/.ssh/authorized_keys",
        "ip link set eth0 up || true",
        f"ip addr add {ip}/24 dev eth0 2>/dev/null || true",
        f"ip route replace default via {cfg.gateway} || true",
        f"printf 'nameserver {cfg.dns}\\n' > /etc/resolv.conf",
        "rc-service sshd start || /etc/init.d/sshd start || true",
        f"echo {marker}",
    ]
    payload = "\n".join(commands) + "\n"
    remote = (
        f"python3 - <<'PY'\n"
        "import os, pty, select, subprocess, sys, time\n"
        f"cmd=['qm','terminal',{str(vmid)!r}]\n"
        "pid, fd = pty.fork()\n"
        "if pid == 0:\n"
        "    os.execvp(cmd[0], cmd)\n"
        "def send(s): os.write(fd, s.encode())\n"
        "def read_for(seconds):\n"
        "    end=time.time()+seconds; out=''\n"
        "    while time.time()<end:\n"
        "        r,_,_=select.select([fd],[],[],0.2)\n"
        "        if not r: continue\n"
        "        try: data=os.read(fd,4096)\n"
        "        except OSError: break\n"
        "        if not data: break\n"
        "        chunk=data.decode('utf-8','replace'); out+=chunk; sys.stdout.write(chunk); sys.stdout.flush()\n"
        "        if 'root@livecd' in out or 'livecd login:' in out: break\n"
        "    return out\n"
        "send('\\n')\n"
        "out=read_for(20)\n"
        "if 'root@livecd' not in out and 'livecd login:' not in out:\n"
        "    send('\\n'); out += read_for(10)\n"
        "if 'livecd login:' in out and 'root@livecd' not in out:\n"
        "    send('root\\n'); read_for(30)\n"
        f"send({payload!r})\n"
        "end=time.time()+90; found=False; out=''\n"
        "while time.time()<end:\n"
        "    r,_,_=select.select([fd],[],[],0.2)\n"
        "    if not r: continue\n"
        "    data=os.read(fd,4096)\n"
        "    if not data: break\n"
        "    chunk=data.decode('utf-8','replace'); out+=chunk; sys.stdout.write(chunk); sys.stdout.flush()\n"
        f"    if {marker!r} in out:\n"
        "        found=True; break\n"
        "send('\\x0f')\n"
        "try: os.waitpid(pid,0)\n"
        "except ChildProcessError: pass\n"
        "sys.exit(0 if found else 1)\n"
        "PY"
    )
    ssh(cfg, remote)
    print(f"proxmox-bootstrap-ssh: configured root SSH for {vmid} {case['name']} at {ip}")


def ansible_ping(cfg: Config, case: dict[str, str | int]) -> None:
    env_vars = os.environ.copy()
    env_vars.update({"ANSIBLE_LIVE_HOST": str(case["ip"]), "ANSIBLE_LIVE_PORT": "22", "ANSIBLE_LIVE_USER": "root"})
    run(["scripts/ansible-live-ping.sh"], env_vars=env_vars)


def wait_for_guest_ssh(host: str, user: str, *, attempts: int = 36) -> bool:
    for _ in range(attempts):
        result = guest_ssh(host, user, "true", check=False, timeout=5)
        if result.returncode == 0:
            return True
        time.sleep(5)
    return False


def installed_access_script(cfg: Config, case: dict[str, str | int], key: str) -> str:
    disk = cfg.access_install_disk
    root_part = f"{disk}2"
    esp_part = f"{disk}1"
    admin = cfg.admin_user
    profile = str(case["profile"])
    filesystem = str(case["filesystem"])
    ip = str(case["ip"])
    prefix = int(cfg.netmask.split(".")[0] == "255") + int(cfg.netmask.split(".")[1] == "255") + int(cfg.netmask.split(".")[2] == "255") + int(cfg.netmask.split(".")[3] == "255")
    prefix *= 8
    if cfg.netmask != "255.255.255.0":
        prefix = 24
    mounts = [
        "set -eu",
        "umount -R /mnt/gentoo 2>/dev/null || true",
        "mkdir -p /mnt/gentoo",
    ]
    if filesystem == "btrfs":
        mounts.extend(
            [
                f"mount -o rw,subvol=@ {shlex.quote(root_part)} /mnt/gentoo",
                "mkdir -p /mnt/gentoo/home /mnt/gentoo/var /mnt/gentoo/.snapshots",
                f"mount -o rw,subvol=@home {shlex.quote(root_part)} /mnt/gentoo/home",
                f"mount -o rw,subvol=@var {shlex.quote(root_part)} /mnt/gentoo/var",
                "mkdir -p /mnt/gentoo/var/log /mnt/gentoo/var/cache",
                f"mount -o rw,subvol=@var_log {shlex.quote(root_part)} /mnt/gentoo/var/log",
                f"mount -o rw,subvol=@var_cache {shlex.quote(root_part)} /mnt/gentoo/var/cache",
                "mkdir -p /mnt/gentoo/.snapshots",
                f"mount -o rw,subvol=@snapshots {shlex.quote(root_part)} /mnt/gentoo/.snapshots",
            ]
        )
    else:
        mounts.append(f"mount -o rw {shlex.quote(root_part)} /mnt/gentoo")
    mounts.extend(
        [
            "mkdir -p /mnt/gentoo/boot/efi",
            f"mount {shlex.quote(esp_part)} /mnt/gentoo/boot/efi 2>/dev/null || true",
            "mount --bind /dev /mnt/gentoo/dev",
            "mount -t proc proc /mnt/gentoo/proc",
            "mount --rbind /sys /mnt/gentoo/sys",
            "mount --make-rslave /mnt/gentoo/sys",
        ]
    )
    target = "\n".join(
        [
            "set -eu",
            "getent group wheel >/dev/null || groupadd wheel",
            f"if id -u {shlex.quote(admin)} >/dev/null 2>&1; then usermod -aG wheel -s /bin/bash {shlex.quote(admin)}; else useradd -m -G wheel -s /bin/bash {shlex.quote(admin)}; fi",
            f"install -d -m 0700 /home/{shlex.quote(admin)}/.ssh",
            f"chown {shlex.quote(admin)}:wheel /home/{shlex.quote(admin)}/.ssh",
            f"printf '%s\\n' {shlex.quote(key)} > /home/{shlex.quote(admin)}/.ssh/authorized_keys",
            f"chown {shlex.quote(admin)}:wheel /home/{shlex.quote(admin)}/.ssh/authorized_keys",
            f"chmod 0600 /home/{shlex.quote(admin)}/.ssh/authorized_keys",
            "install -d -m 0750 /etc/sudoers.d",
            f"printf '%s\\n' '{admin} ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/gentoo-ai-installer-admin-{admin}",
            f"chmod 0440 /etc/sudoers.d/gentoo-ai-installer-admin-{admin}",
            f"visudo -cf /etc/sudoers.d/gentoo-ai-installer-admin-{admin}",
            "ssh-keygen -A",
            "grep -q '^PermitRootLogin no$' /etc/ssh/sshd_config || printf '\\nPermitRootLogin no\\n' >> /etc/ssh/sshd_config",
            "grep -q '^PubkeyAuthentication yes$' /etc/ssh/sshd_config || printf 'PubkeyAuthentication yes\\n' >> /etc/ssh/sshd_config",
            "install -d -m 0700 /etc/NetworkManager/system-connections",
            "cat > /etc/NetworkManager/system-connections/gentoo-ai-installer-proxmox.nmconnection <<'NMEOF'",
            "[connection]",
            "id=gentoo-ai-installer-proxmox",
            "type=ethernet",
            "autoconnect=true",
            "",
            "[ipv4]",
            "method=manual",
            f"address1={ip}/{prefix},{cfg.gateway}",
            f"dns={cfg.dns};",
            "",
            "[ipv6]",
            "method=ignore",
            "NMEOF",
            "chmod 0600 /etc/NetworkManager/system-connections/gentoo-ai-installer-proxmox.nmconnection",
            "rc-update add sshd default >/dev/null 2>&1 || true" if profile == "openrc" else "systemctl enable sshd.service >/dev/null 2>&1 || true",
            "rc-update add NetworkManager default >/dev/null 2>&1 || true" if profile == "openrc" else "systemctl enable NetworkManager.service >/dev/null 2>&1 || true",
            "install -d -m 0755 /etc/local.d" if profile == "openrc" else ":",
            "cat > /etc/local.d/gentoo-ai-installer-sshd.start <<'OPENRCSSHEOF'\n#!/bin/sh\nrc-service sshd start || /etc/init.d/sshd start || true\nOPENRCSSHEOF" if profile == "openrc" else ":",
            "chmod 0755 /etc/local.d/gentoo-ai-installer-sshd.start" if profile == "openrc" else ":",
            "rc-update add local default >/dev/null 2>&1 || true" if profile == "openrc" else ":",
            "install -d -m 0755 /usr/local/sbin" if profile == "openrc" else ":",
            "cat > /usr/local/sbin/gentoo-ai-installer-sshd-ensure <<'OPENRCSSHDWRAPPEREOF'\n#!/bin/sh\nwhile true; do\n  /usr/sbin/sshd -D -e\n  sleep 5\ndone\nOPENRCSSHDWRAPPEREOF" if profile == "openrc" else ":",
            "chmod 0755 /usr/local/sbin/gentoo-ai-installer-sshd-ensure" if profile == "openrc" else ":",
            "grep -q '^gai:' /etc/inittab || printf '\\ngai:2345:respawn:/usr/local/sbin/gentoo-ai-installer-sshd-ensure\\n' >> /etc/inittab" if profile == "openrc" else ":",
        ]
    )
    return "\n".join(
        mounts
        + [
            "cat > /mnt/gentoo/root/gentoo-ai-installer-ensure-access.sh <<'TARGETEOF'",
            target,
            "TARGETEOF",
            "chmod 0700 /mnt/gentoo/root/gentoo-ai-installer-ensure-access.sh",
            "chroot /mnt/gentoo /bin/bash /root/gentoo-ai-installer-ensure-access.sh",
            "rm -f /mnt/gentoo/root/gentoo-ai-installer-ensure-access.sh",
            "sync",
            "umount -R /mnt/gentoo",
        ]
    )


def ensure_installed_access(cfg: Config, case: dict[str, str | int]) -> dict[str, str | int | bool]:
    vmid = int(case["vmid"])
    name = str(case["name"])
    require_owned(cfg, vmid, name)
    key = read_public_key(cfg.public_key_file)
    start_vm(cfg, case)
    time.sleep(45)
    bootstrap_ssh(cfg, case)
    script = installed_access_script(cfg, case, key)
    guest_ssh(str(case["ip"]), "root", script, timeout=20)
    start_installed_vm(cfg, case)
    ok = wait_for_guest_ssh(str(case["ip"]), cfg.admin_user, attempts=36)
    if ok:
        verify = guest_ssh(
            str(case["ip"]),
            cfg.admin_user,
            "hostname; id -un; id -nG; sudo -n true && echo sudo_nopasswd_ok",
            check=False,
            timeout=10,
        )
        ok = verify.returncode == 0 and "sudo_nopasswd_ok" in verify.stdout
    else:
        verify = subprocess.CompletedProcess(args=[], returncode=255, stdout="", stderr="SSH timeout")
    result = {
        "case": str(case["case"]),
        "vmid": vmid,
        "name": name,
        "ip": str(case["ip"]),
        "admin_user": cfg.admin_user,
        "ssh_sudo_ok": ok,
    }
    print(json.dumps(result, sort_keys=True))
    if not ok:
        detail = (verify.stderr or verify.stdout).strip()
        die("PROXMOX_ACCESS_VERIFY_FAILED", f"{case['case']} {cfg.admin_user}@{case['ip']} failed: {detail}")
    return result


def ensure_installed_access_all(cfg: Config) -> None:
    run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    log_dir = Path("logs/proxmox-access") / run_id
    log_dir.mkdir(parents=True, exist_ok=True)
    results = []
    for profile, filesystem, flavor in CASES:
        result = ensure_installed_access(cfg, cfg.case(profile, filesystem, flavor))
        results.append(result)
        (log_dir / "access.json").write_text(json.dumps({"entries": results}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"proxmox-ensure-installed-access-all: all cases verified; see {log_dir}")


def verify_installed_access(cfg: Config, case: dict[str, str | int]) -> dict[str, str | int | bool]:
    result = guest_ssh(
        str(case["ip"]),
        cfg.admin_user,
        "hostname; id -un; id -nG; sudo -n true && echo sudo_nopasswd_ok",
        check=False,
        timeout=10,
    )
    ok = result.returncode == 0 and "sudo_nopasswd_ok" in result.stdout
    entry = {
        "case": str(case["case"]),
        "vmid": int(case["vmid"]),
        "name": str(case["name"]),
        "ip": str(case["ip"]),
        "admin_user": cfg.admin_user,
        "ssh_sudo_ok": ok,
    }
    print(json.dumps(entry, sort_keys=True))
    return entry


def verify_installed_access_all(cfg: Config) -> None:
    results = [verify_installed_access(cfg, cfg.case(*item)) for item in CASES]
    failures = [entry for entry in results if not entry["ssh_sudo_ok"]]
    if failures:
        die("PROXMOX_ACCESS_VERIFY_FAILED", f"{len(failures)} Proxmox cases failed installed SSH/sudo verification")


def e2e_install(cfg: Config, case: dict[str, str | int]) -> dict[str, str | int]:
    if cfg.install_disk not in ("/dev/sda", "/dev/vda"):
        die("DISK_UNSAFE", "run Proxmox E2E with explicit INSTALL_DISK=/dev/sda or INSTALL_DISK=/dev/vda")
    if cfg.wipe_confirm != "yes":
        die("DESTRUCTIVE_CONFIRMATION_MISSING", "Proxmox E2E requires I_UNDERSTAND_THIS_WIPES_DISK=yes")
    if cfg.bootloader_confirm != "yes":
        die("DESTRUCTIVE_CONFIRMATION_MISSING", "Proxmox E2E requires I_UNDERSTAND_BOOTLOADER_CHANGES=yes")
    if not cfg.admin_user:
        die("PROXMOX_CONFIG_INVALID", "ADMIN_USER is required")

    create_vm(cfg, case)
    start_vm(cfg, case)
    time.sleep(40)
    bootstrap_ssh(cfg, case)
    ansible_ping(cfg, case)

    state_file = f"var/state/proxmox/{case['name']}/current-install.json"
    env_vars = os.environ.copy()
    env_vars.update(
        {
            "ANSIBLE_LIVE_HOST": str(case["ip"]),
            "ANSIBLE_LIVE_PORT": "22",
            "ANSIBLE_LIVE_USER": "root",
            "PROFILE": str(case["profile"]),
            "FILESYSTEM": str(case["filesystem"]),
            "STAGE3_FLAVOR": str(case["stage3_flavor"]),
            "HOSTNAME": str(case["name"]),
            "INSTALL_STATE_FILE": state_file,
            "ADMIN_SUDO_NOPASSWD": cfg.admin_sudo_nopasswd,
            "ENABLE_SSH": cfg.enable_ssh,
            "ENABLE_QEMU_GUEST_AGENT": cfg.enable_qemu_guest_agent,
        }
    )
    log_dir = Path("logs/proxmox-e2e") / f"{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}-{case['case']}"
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / "install.log"
    print(f"proxmox-e2e-install: running install for {case['case']} vmid={case['vmid']} ip={case['ip']}")
    with log_file.open("w", encoding="utf-8") as handle:
        proc = subprocess.Popen(["scripts/ansible-install-basic-console.sh"], env=env_vars, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        assert proc.stdout is not None
        for line in proc.stdout:
            sys.stdout.write(line)
            handle.write(line)
        rc = proc.wait()
    result = {
        "case": str(case["case"]),
        "vmid": int(case["vmid"]),
        "name": str(case["name"]),
        "ip": str(case["ip"]),
        "returncode": rc,
        "status": "pass" if rc == 0 else "fail",
        "log": str(log_file),
    }
    (log_dir / "result.json").write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    if rc != 0:
        die("PROXMOX_INSTALL_FAILED", f"{case['case']} failed; see {log_file}")
    shutdown_vm(cfg, case)
    return result


def e2e_matrix(cfg: Config) -> None:
    run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    matrix_dir = cfg.log_root / run_id
    matrix_dir.mkdir(parents=True, exist_ok=True)
    entries = [cfg.case(*item) for item in CASES]
    results: list[dict[str, str | int]] = []
    failures = 0
    with ThreadPoolExecutor(max_workers=cfg.matrix_parallel) as pool:
        future_map = {pool.submit(e2e_install, cfg, entry): entry for entry in entries}
        while future_map:
            done, _ = wait(future_map.keys(), return_when=FIRST_COMPLETED)
            for future in done:
                entry = future_map.pop(future)
                try:
                    result = future.result()
                except SystemExit as exc:
                    failures += 1
                    result = {"case": str(entry["case"]), "vmid": int(entry["vmid"]), "name": str(entry["name"]), "ip": str(entry["ip"]), "status": "fail", "returncode": int(exc.code or 1)}
                except Exception as exc:  # noqa: BLE001
                    failures += 1
                    result = {"case": str(entry["case"]), "vmid": int(entry["vmid"]), "name": str(entry["name"]), "ip": str(entry["ip"]), "status": "fail", "error": str(exc)}
                results.append(result)
                (matrix_dir / "matrix-e2e.json").write_text(json.dumps({"entries": results}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
                print(f"proxmox-e2e-matrix: completed {entry['case']} status={result.get('status')}")
    if failures:
        die("PROXMOX_MATRIX_FAILED", f"{failures} Proxmox matrix cases failed; see {matrix_dir}")
    print(f"proxmox-e2e-matrix: all cases passed; see {matrix_dir}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "command",
        choices=[
            "check",
            "list-cases",
            "create",
            "create-all",
            "start",
            "start-installed",
            "start-installed-all",
            "ensure-installed-access",
            "ensure-installed-access-all",
            "verify-installed-access",
            "verify-installed-access-all",
            "ip",
            "bootstrap-ssh",
            "ansible-ping",
            "e2e-install",
            "e2e-matrix",
            "shutdown",
            "clean",
        ],
    )
    args = parser.parse_args()
    cfg = Config()
    profile, filesystem, flavor = env("PROFILE", "openrc"), env("FILESYSTEM", "ext4"), env("STAGE3_FLAVOR", "standard")
    case = cfg.case(profile, filesystem, flavor)

    if args.command == "check":
        check(cfg)
    elif args.command == "list-cases":
        list_cases(cfg)
    elif args.command == "create":
        create_vm(cfg, case)
    elif args.command == "create-all":
        create_all(cfg)
    elif args.command == "start":
        start_vm(cfg, case)
    elif args.command == "start-installed":
        start_installed_vm(cfg, case)
    elif args.command == "start-installed-all":
        start_installed_all(cfg)
    elif args.command == "ensure-installed-access":
        ensure_installed_access(cfg, case)
    elif args.command == "ensure-installed-access-all":
        ensure_installed_access_all(cfg)
    elif args.command == "verify-installed-access":
        verify_installed_access(cfg, case)
    elif args.command == "verify-installed-access-all":
        verify_installed_access_all(cfg)
    elif args.command == "ip":
        print(case["ip"])
    elif args.command == "bootstrap-ssh":
        bootstrap_ssh(cfg, case)
    elif args.command == "ansible-ping":
        ansible_ping(cfg, case)
    elif args.command == "e2e-install":
        e2e_install(cfg, case)
    elif args.command == "e2e-matrix":
        e2e_matrix(cfg)
    elif args.command == "shutdown":
        shutdown_vm(cfg, case)
    elif args.command == "clean":
        clean_vm(cfg, case)


if __name__ == "__main__":
    main()
