{ lib, options, ... }:
{
  # Never run the production Caddy configuration in the test container.
  systemd.services.caddy.enable = lib.mkForce false;
  systemd.maskedUnits = [ "caddy.service" ];
  sops.secrets.caddyfile.reloadUnits = lib.mkForce [ ];

  # Limit Go parallelism for the resource-constrained test container.
  sops.package = options.sops.package.default.overrideAttrs (old: {
    postInstall = ''
      export GOMAXPROCS=2
      export GOFLAGS="$GOFLAGS -p=2"
    ''
    + (old.postInstall or "");
  });
}
