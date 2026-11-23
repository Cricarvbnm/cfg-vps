{ pkgs, systemManager }:
pkgs.mkShellNoCC {
  packages = [
    systemManager
    pkgs.mihomo
  ];
}
