{
  description = "Portable VPS services managed with Nix and system-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      system-manager,
      sops-nix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      commonModules = [
        { nixpkgs.hostPlatform = system; }
        sops-nix.nixosModules.sops
        { sops.age.keyFile = "/etc/sops/age/keys.txt"; }
        ./modules/mihomo.nix
        ./modules/caddy.nix
      ];
    in
    {
      systemConfigs = {
        default = system-manager.lib.makeSystemConfig {
          modules = commonModules;
        };

        podman-test = system-manager.lib.makeSystemConfig {
          modules = commonModules ++ [
            ./tests/environment/module.nix
          ];
        };
      };

      devShells.${system}.default = import ./shell.nix {
        inherit pkgs;
        systemManager = system-manager.packages.${system}.default;
      };
    };
}
