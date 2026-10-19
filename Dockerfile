FROM ghcr.io/h-network/base:latest
ENV DEBIAN_FRONTEND=noninteractive

# Everything generic — openssh-server, git, gh, python3, the `ubuntu` user +
# passwordless sudo, sshd hardening and the git pre-push guardrail — comes from
# the base image. This image only adds code-server and this box's identity.

# Browser-based VS Code. Pin the release so rebuilds are reproducible.
# Needs curl + ca-certificates + apt from the base to download and install.
ARG CODE_SERVER_VERSION=4.141.0
RUN apt-get update \
 && apt-get install -y --no-install-recommends /tmp/code-server.deb \
 && curl -fsSL https://code-server.dev/install.sh | sh

# Seed this box's identity + code-server config into the ubuntu home.
# Runtime changes stay in the container.
COPY --chown=ubuntu:ubuntu configs/authorized_keys /home/ubuntu/.ssh/authorized_keys
COPY --chown=ubuntu:ubuntu configs/gitConfigs/git/gitconfig /home/ubuntu/.gitconfig
COPY --chown=ubuntu:ubuntu configs/gitConfigs/git/id-* /home/ubuntu/.config/git/
COPY --chown=ubuntu:ubuntu configs/gitConfigs/code-server/config.yaml /home/ubuntu/.config/code-server/config.yaml
RUN chown ubuntu:ubuntu /home/ubuntu/.ssh /home/ubuntu/.config /home/ubuntu/.config/git /home/ubuntu/.config/code-server \
 && chmod 0700 /home/ubuntu/.ssh /home/ubuntu/.config/git /home/ubuntu/.config/code-server \
 && chmod 0600 /home/ubuntu/.ssh/authorized_keys /home/ubuntu/.gitconfig /home/ubuntu/.config/git/id-* /home/ubuntu/.config/code-server/config.yaml

COPY entrypoint.sh /usr/local/bin/hblvs-entrypoint
RUN chmod 0755 /usr/local/bin/hblvs-entrypoint

EXPOSE 22 8080
CMD ["/usr/local/bin/hblvs-entrypoint"]
