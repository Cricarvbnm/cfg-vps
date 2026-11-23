{ pkgs, ... }:
let
  mihomo = "${pkgs.mihomo}/bin/mihomo";
  args = "-d /var/lib/mihomo -f /etc/mihomo/config.yaml";
in
{
  users.groups.mihomo = {};
  users.users.mihomo = {
    isSystemUser = true;
    group = "mihomo";
  };

  systemd.services.mihomo = rec {
    description = "Mihomo proxy";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = wants;

    serviceConfig = {
      User = "mihomo";
      Group = "mihomo";
      StateDirectory = "mihomo";
      StateDirectoryMode = "0750";
      WorkingDirectory = "/var/lib/mihomo";
      ExecStartPre = "${mihomo} -t ${args}";
      ExecStart = "${mihomo} ${args}";
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
