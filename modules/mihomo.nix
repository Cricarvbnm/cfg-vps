{ config, pkgs, ... }:
let
  mihomo = "${pkgs.mihomo}/bin/mihomo";
  args = "-d /var/lib/mihomo -f /etc/mihomo/config.yaml";
in
{
  environment.etc."mihomo/config.yaml".source = ../config/mihomo.yaml;

  systemd.services.mihomo = {
    description = "Mihomo proxy";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    restartTriggers = [ config.environment.etc."mihomo/config.yaml".source ];

    serviceConfig = {
      StateDirectory = "mihomo";
      WorkingDirectory = "/var/lib/mihomo";
      ExecStartPre = "${mihomo} -t ${args}";
      ExecStart = "${mihomo} ${args}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
