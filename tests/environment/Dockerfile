FROM debian:13

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        systemd-sysv dbus ca-certificates curl git xz-utils nix-setup-systemd \
    && rm -rf /var/lib/apt/lists/*

RUN printf '\n%s\n' \
    'experimental-features = nix-command flakes' \
    'sandbox = false' \
    >>/etc/nix/nix.conf

CMD ["/sbin/init"]
