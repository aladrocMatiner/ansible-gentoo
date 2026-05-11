#!/usr/bin/env python3
import os
import pty
import re
import select
import shlex
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

PROJECT_MARKER = "gentoo-ai-installer-managed-domain"
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
COMMON_ENV_KEYS = (
    "LIBVIRT_URI",
    "PROFILE",
    "FILESYSTEM",
    "VM_CASE_DERIVED",
    "VM_BASE_NAME",
    "VM_TEST_IMAGE_NAME",
    "VM_PLATFORM",
    "VM_CASE_KEY",
    "VM_NAME",
    "VM_DIR",
    "VM_DISK",
    "VM_NVRAM",
    "VM_KERNEL",
    "VM_INITRD",
    "VM_LOG_DIR",
    "VM_KNOWN_HOSTS",
    "VM_SSH_HOST_PORT",
    "INSTALL_STATE_FILE",
)


def die(message):
    print(f"vm-bootstrap-ssh: {message}", file=sys.stderr)
    raise SystemExit(1)


def read_public_key():
    key = os.environ.get("VM_SSH_PUBLIC_KEY", "").strip()
    if key:
        return key
    home = os.path.expanduser("~")
    for path in (
        os.path.join(home, ".ssh", "id_ed25519.pub"),
        os.path.join(home, ".ssh", "id_rsa.pub"),
    ):
        if os.path.isfile(path):
            with open(path, "r", encoding="utf-8") as handle:
                return handle.read().strip()
    die("no public key found; set VM_SSH_PUBLIC_KEY or create ~/.ssh/id_ed25519.pub")


def validate_public_key(public_key):
    if not public_key:
        die("public SSH key is empty")
    if any(character in public_key for character in ("\n", "\r", "\x00")):
        die("public SSH key must be a single line")
    if any(ord(character) < 32 for character in public_key):
        die("public SSH key contains control characters")

    parts = public_key.split()
    if len(parts) < 2:
        die("public SSH key must include key type and encoded key material")

    key_type = parts[0]
    encoded_key = parts[1]
    allowed_key_types = {
        "ssh-ed25519",
        "ssh-rsa",
        "ecdsa-sha2-nistp256",
        "ecdsa-sha2-nistp384",
        "ecdsa-sha2-nistp521",
        "sk-ssh-ed25519@openssh.com",
        "sk-ecdsa-sha2-nistp256@openssh.com",
    }
    if key_type not in allowed_key_types:
        die(f"unsupported public SSH key type: {key_type}")
    if not re.fullmatch(r"[A-Za-z0-9+/=]+", encoded_key):
        die("public SSH key material is not valid base64-like text")


def abs_path(path):
    if os.path.isabs(path):
        return os.path.abspath(path)
    return os.path.abspath(os.path.join(REPO_ROOT, path))


def common_vm_config():
    key_list = " ".join(COMMON_ENV_KEYS)
    script = (
        "source scripts/vm-libvirt-common.sh; "
        "load_vm_config; "
        "validate_vm_config; "
        f"for name in {key_list}; do printf '%s\\0' \"${{!name}}\"; done"
    )
    result = subprocess.run(
        ["bash", "-c", script],
        cwd=REPO_ROOT,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        detail = result.stderr.decode("utf-8", errors="replace").strip() or (
            f"common VM config derivation exited with status {result.returncode}"
        )
        prefix = "vm-libvirt: "
        if detail.startswith(prefix):
            detail = detail[len(prefix) :]
        die(detail)
    values = result.stdout.split(b"\0")
    if values and values[-1] == b"":
        values.pop()
    if len(values) != len(COMMON_ENV_KEYS):
        die("common VM config derivation returned an unexpected number of values")
    decoded = {
        key: value.decode("utf-8", errors="strict")
        for key, value in zip(COMMON_ENV_KEYS, values)
    }
    os.environ.update(decoded)
    return decoded


def expected_artifacts():
    vm_dir = os.environ.get("VM_DIR", "var/libvirt")
    vm_disk = os.environ.get("VM_DISK", os.path.join(vm_dir, "gentoo-test.qcow2"))
    domain = os.environ.get("VM_NAME", "gentoo-test")
    return {
        "vm_dir": vm_dir,
        "disk": abs_path(vm_disk),
        "nvram": abs_path(os.path.join(vm_dir, "nvram", f"{domain}_VARS.fd")),
        "kernel": abs_path(os.path.join(vm_dir, f"{domain}-gentoo-kernel")),
        "initrd": abs_path(os.path.join(vm_dir, f"{domain}-gentoo-initrd")),
    }


def element_text(root, path):
    item = root.find(path)
    return item.text.strip() if item is not None and item.text else ""


def require_domain_matches_artifacts(xml_text, domain):
    expected = expected_artifacts()
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError as exc:
        die(f"cannot parse libvirt XML for {domain}: {exc}")

    loader = root.find("./os/loader")
    if loader is None or loader.attrib.get("type") != "pflash":
        die(f"libvirt domain is not configured with OVMF UEFI firmware: {domain}")

    artifact_dirs = re.findall(r"<artifact-dir>([^<]+)</artifact-dir>", xml_text)
    if len(artifact_dirs) != 1:
        die(f"libvirt domain must have exactly one artifact-dir marker; found {len(artifact_dirs)}: {domain}")
    if abs_path(artifact_dirs[0]) != abs_path(expected["vm_dir"]):
        die(f"libvirt domain artifact directory does not match VM_DIR: {artifact_dirs[0]} != {expected['vm_dir']}")

    for label, path in (("NVRAM", "nvram"), ("kernel", "kernel"), ("initrd", "initrd")):
        actual = abs_path(element_text(root, f"./os/{path}"))
        if actual != expected[path]:
            die(f"libvirt domain {label} path does not match generated artifact: {actual} != {expected[path]}")

    disk_sources = []
    for disk in root.findall("./devices/disk"):
        source = disk.find("source")
        if disk.attrib.get("type") == "block":
            die(f"libvirt domain contains a block-device disk; refusing to operate: {domain}")
        if source is None:
            continue
        dev_source = source.attrib.get("dev", "")
        file_source = source.attrib.get("file", "")
        if dev_source.startswith("/dev/") or dev_source == "/dev":
            die(f"libvirt domain references a host /dev path; refusing to operate: {dev_source}")
        if file_source.startswith("/dev/") or file_source == "/dev":
            die(f"libvirt domain file source points under /dev; refusing to operate: {file_source}")
        if disk.attrib.get("device") == "disk":
            disk_sources.append(abs_path(file_source))

    if len(disk_sources) != 1:
        die(f"libvirt domain must have exactly one VM disk source; found {len(disk_sources)}: {domain}")
    if disk_sources[0] != expected["disk"]:
        die(f"libvirt domain disk source does not match VM_DISK: {disk_sources[0]} != {expected['disk']}")


def send(fd, text):
    os.write(fd, text.encode("utf-8"))


def read_until(fd, needles, timeout):
    end = time.time() + timeout
    buffer = ""
    while time.time() < end:
        ready, _, _ = select.select([fd], [], [], 0.2)
        if not ready:
            continue
        try:
            data = os.read(fd, 4096)
        except OSError:
            break
        if not data:
            break
        chunk = data.decode("utf-8", errors="replace")
        sys.stdout.write(chunk)
        sys.stdout.flush()
        buffer += chunk
        if any(needle in buffer for needle in needles):
            return buffer
    return buffer


def run_console_commands(domain, uri, public_key):
    cmd = ["virsh", "--connect", uri, "console", domain]
    pid, fd = pty.fork()
    if pid == 0:
        os.execvp(cmd[0], cmd)

    try:
        read_until(fd, ["Escape character is", "Connected to domain"], 15)
        send(fd, "\n")
        output = read_until(fd, ["root@livecd", "livecd login:"], 90)
        if "livecd login:" in output and "root@livecd" not in output:
            send(fd, "root\n")
            read_until(fd, ["root@livecd"], 30)

        marker = "GENTOO_AI_INSTALLER_SSH_READY"
        commands = [
            "mkdir -p /root/.ssh",
            f"printf '%s\\n' {shlex.quote(public_key)} > /root/.ssh/authorized_keys",
            "chmod 700 /root/.ssh",
            "chmod 600 /root/.ssh/authorized_keys",
            "rc-service NetworkManager start >/dev/null 2>&1 || true",
            "nm-online -q -t 20 || true",
            "rc-service sshd start",
            f"echo {marker}",
        ]
        send(fd, "\n".join(commands) + "\n")
        output = read_until(fd, [marker], 60)
        if marker not in output:
            die("serial console did not report SSH readiness")
    finally:
        send(fd, "\x1d")
        _, status = os.waitpid(pid, 0)
        if status != 0:
            return status
    return 0


def require_project_owned_domain(domain, uri):
    result = subprocess.run(
        ["virsh", "--connect", uri, "dumpxml", domain],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or f"virsh dumpxml exited with status {result.returncode}"
        die(f"cannot inspect libvirt domain {domain!r}: {detail}")
    if PROJECT_MARKER not in result.stdout:
        die(f"libvirt domain exists but is not marked as project-owned: {domain}")
    require_domain_matches_artifacts(result.stdout, domain)


def require_common_vm_safety():
    validation = (
        "SCRIPT_NAME=vm-bootstrap-ssh; "
        "source scripts/vm-libvirt-common.sh; "
        "load_vm_config; "
        "require_command virsh; "
        "validate_vm_config; "
        "require_libvirt_connection; "
        "require_project_owned_running_domain"
    )
    result = subprocess.run(
        ["bash", "-c", validation],
        cwd=REPO_ROOT,
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or f"common VM safety validation exited with status {result.returncode}"
        prefix = "vm-bootstrap-ssh: "
        if detail.startswith(prefix):
            detail = detail[len(prefix):]
        die(detail)


def require_running_domain(domain, uri):
    result = subprocess.run(
        ["virsh", "--connect", uri, "domstate", domain],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or f"virsh domstate exited with status {result.returncode}"
        die(f"cannot inspect libvirt domain state for {domain!r}: {detail}")
    if result.stdout.strip().lower() != "running":
        die(f"libvirt domain must be running before SSH bootstrap: {domain}")


def main():
    config = common_vm_config()
    uri = config["LIBVIRT_URI"]
    domain = config["VM_NAME"]
    public_key = read_public_key()
    validate_public_key(public_key)
    require_common_vm_safety()
    require_project_owned_domain(domain, uri)
    require_running_domain(domain, uri)
    status = run_console_commands(domain, uri, public_key)
    if status:
        raise SystemExit(status)
    print("vm-bootstrap-ssh: SSH public key installed and sshd started")


if __name__ == "__main__":
    main()
