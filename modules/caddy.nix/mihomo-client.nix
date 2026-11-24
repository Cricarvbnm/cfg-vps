{ config, lib, pkgs, ... }:
let
  deployClient = pkgs.writeShellApplication {
    name = "deploy-mihomo-client";
    runtimeInputs = with pkgs; [ coreutils findutils gnutar gzip ];
    text = builtins.readFile ./deploy-mihomo-client.sh;
  };
in
{
  sops.secrets.mihomo-client = {
    sopsFile = ../../secrets/cfg-mihomo/client.tar.gz;
    format = "binary";
    owner = "root";
    group = "root";
    mode = "0400";
    restartUnits = [ "mihomo-client.service" ];
  };

  systemd.services.mihomo-client = {
    description = "Deploy Mihomo archive contents";
    wantedBy = [ "sops-install-secrets.service" ];
    wants = [ "sops-install-secrets.service" ];
    after = [ "sops-install-secrets.service" ];
    before = [ "caddy.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      UMask = "0077";
      ExecStart = "${deployClient}/bin/deploy-mihomo-client " + lib.escapeShellArgs [
        config.sops.secrets.mihomo-client.path
        "/srv/mihomo"
        "root"
        "caddy"
      ];
    };
  };

  systemd.services.caddy = {
    wants = [ "mihomo-client.service" ];
    after = [ "mihomo-client.service" ];
    serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/test -d /srv/mihomo";
  };
}
