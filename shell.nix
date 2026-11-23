{ pkgs, systemManager }:
pkgs.mkShellNoCC {
  packages = [
    systemManager
    pkgs.mihomo
  ];

  shellHook = ''
    if [[ $- == *i* ]]; then
      exec ${pkgs.fish}/bin/fish
    fi
  '';
}
