{ config, lib, pkgs, ... }:
let
  caddy = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/duckdns@v0.5.0" ];
    hash = "sha256-jSavcX0BjQRJZr8bJGy/mMPfLYYwlX+PeWc1IAzAZMM=";
  };
in
{
  users.groups.caddy = {};
  users.users.caddy = {
    isSystemUser = true;
    group = "caddy";
  };

  sops.secrets.Caddyfile = {
    sopsFile = ../secrets/Caddyfile;
    format = "binary";
    mode = "0440";
    group = "caddy";
    restartUnits = [ "caddy.service" ];
  };

  systemd.services.caddy = rec {
    description = "Caddy web server";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    requires = [ "sops-install-secrets.service" ];
    after = [ "network-online.target" ] ++ requires;

    serviceConfig = {
      Type = "notify";
      StateDirectory = "caddy";
      StateDirectoryMode = "0700";
      User = "caddy";
      Group = "caddy";
      Environment = [
        "XDG_DATA_HOME=/var/lib/caddy"
        "XDG_CONFIG_HOME=/var/lib/caddy"
      ];

      ExecStart = "${caddy}/bin/caddy run --config ${config.sops.secrets.Caddyfile.path} --adapter caddyfile";

      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      Restart = "on-failure";
    };
  };
}
