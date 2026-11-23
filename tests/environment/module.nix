{ options, ... }:
{
  # Limit Go parallelism for the resource-constrained test container.
  sops.package = options.sops.package.default.overrideAttrs (old: {
    postInstall = ''
      export GOMAXPROCS=2
      export GOFLAGS="$GOFLAGS -p=2"
    '' + (old.postInstall or "");
  });
}
