{
  description = "flake for my config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    niri.url = "github:YaLTeR/niri";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    caelestia-shell = {
      url = "github:AyushKr2003/niri-caelestia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "quickshell";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    prismlauncher = {
      url = "github:Diegiwg/PrismLauncher-Cracked";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # anicli-ru = {
    #   url = "github:vypivshiy/ani-cli-ru";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    copyparty = {
      url = "github:9001/copyparty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      stylix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      username = "Prizrak";
    in
    {
      nixosConfigurations = {
        nixos = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs username;
          };
          modules = [
            ./hosts/Prizrak/configuration.nix
            stylix.nixosModules.stylix
            ./materials/themes/prizrak.nix
            inputs.home-manager.nixosModules.home-manager
            {
              nixpkgs.overlays = [
                (final: prev: {
                  caelestia-shell = inputs.caelestia-shell.packages.${system}.caelestia-shell;
                  caelestia-cli = inputs.caelestia-shell.inputs.caelestia-cli.packages.${system}.caelestia-cli;
                })
              ];
            }
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs username;
              };
              home-manager.users.${username} = {
                imports = [ ]; 
              };
            }
          ];
        };

        server = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/server/configuration.nix
            inputs.home-manager.nixosModules.home-manager
            inputs.copyparty.nixosModules.default
            {
              home-manager = {
                extraSpecialArgs = { inherit inputs; };
                useGlobalPkgs = true;
                useUserPackages = true;
              };
            }
          ];
        };
      };
    };
}
