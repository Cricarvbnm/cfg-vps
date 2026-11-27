{ config, pkgs, ... }:
let
  inherit (import ./shared.nix) state-directory-name state-directory;

  caddy-pkg = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/duckdns@v0.5.0" ];
    hash = "sha256-jSavcX0BjQRJZr8bJGy/mMPfLYYwlX+PeWc1IAzAZMM=";
  };
  caddy = "${caddy-pkg}/bin/caddy";
  args = "--config ${config.sops.secrets.caddyfile.path} --adapter caddyfile";
in
{
  imports = [ ./mihomo-client.nix ];

  users.groups.caddy = { };
  users.users.caddy = {
    isSystemUser = true;
    group = "caddy";
  };

  sops.secrets.caddyfile = {
    sopsFile = ../../secrets/Caddyfile;
    format = "binary";
    mode = "0640";
    owner = "root";
    group = "caddy";
    reloadUnits = [ "caddy.service" ];
  };

  systemd.services.caddy = rec {
    description = "Caddy web server";
    wantedBy = [ "multi-user.target" ];
    wants = [
      "network-online.target"
      "sops-install-secrets.service"
    ];
    after = wants;

    serviceConfig = {
      Type = "notify";
      StateDirectory = state-directory-name;
      StateDirectoryMode = "0750";
      User = "caddy";
      Group = "caddy";
      Environment = [
        "XDG_DATA_HOME=${state-directory}"
        "XDG_CONFIG_HOME=${state-directory}"
      ];

      ExecStart = "${caddy} run ${args}";
      ExecReload = "${caddy} reload ${args}";

      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
