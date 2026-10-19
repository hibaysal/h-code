#!/bin/bash
set -euo pipefail

ubuntu_home=/home/ubuntu

# Generate a host key for this container; a replacement container gets a new key.
install -d -m 0755 /run/sshd
install -d -m 0700 /var/lib/ssh-host-keys
host_key=/var/lib/ssh-host-keys/ssh_host_ed25519_key
if [ ! -f "$host_key" ]; then
    ssh-keygen -q -t ed25519 -N '' -f "$host_key"
fi

/usr/sbin/sshd -t -h "$host_key"
/usr/sbin/sshd -D -e -h "$host_key" &
sshd_pid=$!
runuser -u ubuntu -- env HOME="$ubuntu_home" \
    /usr/bin/code-server --config "$ubuntu_home/.config/code-server/config.yaml" \
    --bind-addr 0.0.0.0:8080 --disable-telemetry "$ubuntu_home" &
code_pid=$!

shutdown() {
    kill -TERM "${sshd_pid}" "${code_pid}" 2>/dev/null || true
    wait "${sshd_pid}" "${code_pid}" 2>/dev/null || true
}
trap shutdown TERM INT EXIT

wait -n "${sshd_pid}" "${code_pid}"
exit 1
