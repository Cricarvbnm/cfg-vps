{ config, pkgs, ... }:
let
  caddy-pkg = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/duckdns@v0.5.0" ];
    hash = "sha256-jSavcX0BjQRJZr8bJGy/mMPfLYYwlX+PeWc1IAzAZMM=";
  };
  caddy = "${caddy-pkg}/bin/caddy";
  args = "--config ${config.sops.secrets.Caddyfile.path} --adapter caddyfile";
in
{
  imports = [ ./mihomo-client.nix ];

  users.groups.caddy = {};
  users.users.caddy = {
    isSystemUser = true;
    group = "caddy";
  };

  sops.secrets.Caddyfile = {
    sopsFile = ../../secrets/Caddyfile;
    format = "binary";
    mode = "0440";
    owner = "caddy";
    group = "caddy";
    reloadUnits = [ "caddy.service" ];
  };

  systemd.services.caddy = rec {
    description = "Caddy web server";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" "sops-install-secrets.service" ];
    after = wants;

    serviceConfig = {
      Type = "notify";
      StateDirectory = "caddy";
      StateDirectoryMode = "0750";
      User = "caddy";
      Group = "caddy";
      Environment = [
        "XDG_DATA_HOME=/var/lib/caddy"
        "XDG_CONFIG_HOME=/var/lib/caddy"
      ];

      ExecStart = "${caddy} run ${args}";
      ExecReload = "${caddy} reload ${args}";

      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
