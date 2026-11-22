{
  description = "Prizrak's NixOS flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nothing-panel = {
      url = "github:yurei07/nothing-panel";
      flake = false;
    };

    chiaroscuro = {
      url = "path:./themes/chiaroscuro-stub";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    freesm-launcher = {
      url = "github:FreesmTeam/FreesmLauncher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "Prizrak"; # CHANGEME
    in
    {
      nixosConfigurations = {
        nixos = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs username;
          };
          modules = [
            inputs.nur.modules.nixos.default
            ./hosts/${username}/configuration.nix
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs username;
                theme = inputs.chiaroscuro.themes.kanso-zen;
              };
              home-manager.users.${username} = {
                imports = [
                  ./hosts/${username}/home/home-configuration.nix
                ];
              };
            }
          ];
        };

        # generic desktop: the install target used by scripts/nixinstall
        pc = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs username;
          };
          modules = [
            inputs.nur.modules.nixos.default
            ./hosts/pc/configuration.nix
            inputs.home-manager.nixosModules.home-manager
          ];
        };

        # live ISO: boots into Hyprland with the full Nothing shell
        live = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs username;
          };
          modules = [
            inputs.nur.modules.nixos.default
            ./hosts/live/configuration.nix
            inputs.home-manager.nixosModules.home-manager
          ];
        };
      };
    };
}
