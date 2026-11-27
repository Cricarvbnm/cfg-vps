{ pkgs, ... }:
let
  inherit (import ./caddy.nix/exports.nix) cert;

  mihomo = "${pkgs.mihomo}/bin/mihomo";
  args = "-d /var/lib/mihomo -f /etc/mihomo/config.yaml";
in
{
  users.groups.mihomo = { };
  users.users.mihomo = {
    isSystemUser = true;
    group = "mihomo";
  };

  sops.secrets.mihomo-server = {
    sopsFile = ../secrets/cfg-mihomo/server.yaml;
    format = "yaml";
    key = "data";
    path = "/etc/mihomo/config.yaml";
    owner = "root";
    group = "mihomo";
    mode = "0640";
    restartUnits = [ "mihomo.service" ];
  };

  systemd.services.mihomo = rec {
    description = "Mihomo proxy";
    wantedBy = [ "multi-user.target" ];
    wants = [
      "sops-install-secrets.service"
      "network-online.target"
    ];
    after = wants;

    serviceConfig = {
      StateDirectory = "mihomo";
      StateDirectoryMode = "0750";
      WorkingDirectory = "/var/lib/mihomo";
      ExecStartPre = "${mihomo} -t ${args}";
      ExecStart = "${mihomo} ${args}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  systemd.tmpfiles.rules = [
    "L+ /var/lib/mihomo/server.crt - - - - ${cert.crt}"
    "L+ /var/lib/mihomo/server.key - - - - ${cert.key}"
  ];
}
