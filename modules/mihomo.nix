{ config, pkgs, ... }:
let
  mihomo = "${pkgs.mihomo}/bin/mihomo";
  args = "-d /var/lib/mihomo -f /etc/mihomo/config.yaml";
in
{
  systemd.services.mihomo = {
    description = "Mihomo proxy";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

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
}
