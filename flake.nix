{
  description = "Portable VPS services managed with Nix and system-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, system-manager, ... }: {
    systemConfigs.default = system-manager.lib.makeSystemConfig {
      modules = [
        { nixpkgs.hostPlatform = "x86_64-linux"; }
        ./modules/mihomo.nix
      ];
    };

    apps.x86_64-linux.default = {
      type = "app";
      program = "${system-manager.packages.x86_64-linux.default}/bin/system-manager";
    };

    devShells = nixpkgs.lib.genAttrs
      [ "x86_64-linux" ]
      (system: {
        default = import ./shell.nix {
          pkgs = nixpkgs.legacyPackages.${system};
          systemManager = system-manager.packages.${system}.default;
        };
      });
  };
}
