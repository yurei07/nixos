{
  description = "flake for my config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprpolkitagent.url = "github:hyprwm/hyprpolkitagent";
    flake-utils.url = "github:numtide/flake-utils";
    nixcord.url = "github:kaylorben/nixcord";
    lazyvim.url = "github:pfassina/lazyvim-nix";
    textfox.url = "github:adriankarlen/textfox";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # noctalia = {
    #   url = "github:noctalia-dev/noctalia-shell";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.quickshell.follows = "quickshell";
    # };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        # IMPORTANT: we're using "libgbm" and is only available in unstable so ensure
        # to have it up-to-date or simply don't specify the nixpkgs input
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kanso-nvim = {
      url = "github:pabloagn/kanso.nvim";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    anicli-ru = {
      url = "github:vypivshiy/ani-cli-ru";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    copyparty = {
      url = "github:9001/copyparty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;
      rhodiumLib = import ./lib { inherit lib pkgs; };
      username = "Prizrak";
    in
    {
      nixosConfigurations = {
        nixos = inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs rhodiumLib username;
          };
          inherit system;
          modules = [
            ./hosts/Prizrak/configuration.nix
            inputs.home-manager.nixosModules.home-manager
            # inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480
            {
              nixpkgs.overlays = [
                (final: prev: {
                  caelestia-shell = inputs.caelestia-shell.packages.${system}.caelestia-shell;
                  caelestia-cli = inputs.caelestia-shell.inputs.caelestia-cli.packages.${system}.caelestia-cli;
                })
              ];
            }
            {
              home-manager = {
                extraSpecialArgs = {
                  inherit inputs rhodiumLib username;
                };
                useGlobalPkgs = true;
                useUserPackages = true;
              };
            }
          ];
        };
        server = inputs.nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          inherit system;
          modules = [
            ./hosts/server/configuration.nix
            inputs.home-manager.nixosModules.home-manager
            inputs.copyparty.nixosModules.default
            {
              home-manager = {
                extraSpecialArgs = {
                  inherit inputs;
                };
                useGlobalPkgs = true;
                useUserPackages = true;
              };
            }
          ];
        };
      };
    };
}
