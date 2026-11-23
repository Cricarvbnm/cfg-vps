{ config, pkgs, ... }:
let
  mihomo = "${pkgs.mihomo}/bin/mihomo";
  args = "-d /var/lib/mihomo -f ${config.sops.secrets."mihomo.yaml".path}";
in
{
  sops.age.keyFile = "/etc/sops/age/keys.txt";

  sops.secrets."mihomo.yaml" = {
    sopsFile = ../secrets/mihomo.yaml;
    restartUnits = [ "mihomo.service" ];
    key = "";
  };

  systemd.services.mihomo = rec {
    description = "Mihomo proxy";
    wantedBy = [ "multi-user.target" ];
    requires = [ "sops-install-secrets.service" ];
    after = [ "network.target" ] ++ requires;

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
