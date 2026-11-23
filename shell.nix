{ pkgs, systemManager }:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    systemManager
    sops age
  ];

  shellHook = ''
    if [[ $- == *i* ]]; then
      exec ${pkgs.fish}/bin/fish
    fi
  '';
}
