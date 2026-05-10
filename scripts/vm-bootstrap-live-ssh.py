#!/usr/bin/env python3
import os
import pty
import select
import subprocess
import sys
import time


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
            f"printf '%s\\n' '{public_key}' > /root/.ssh/authorized_keys",
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


def main():
    uri = os.environ.get("LIBVIRT_URI", "qemu:///system")
    domain = os.environ.get("VM_NAME", "gentoo-ai-installer")
    public_key = read_public_key()
    subprocess.run(["virsh", "--connect", uri, "domstate", domain], check=True, stdout=subprocess.DEVNULL)
    status = run_console_commands(domain, uri, public_key)
    if status:
      raise SystemExit(status)
    print("vm-bootstrap-ssh: SSH public key installed and sshd started")


if __name__ == "__main__":
    main()
