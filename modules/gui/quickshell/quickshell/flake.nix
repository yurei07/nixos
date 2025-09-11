{
  description = "Noctalia shell - a Wayland desktop shell built with Quickshell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    quickshell,
    ...
  }: let
    eachSystem = nixpkgs.lib.genAttrs (import systems);
  in {
    formatter = eachSystem (
      system:
        nixpkgs.legacyPackages.${system}.alejandra
    );

    packages = eachSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        qs = quickshell.packages.${system}.default.override {
          withX11 = false;
          withI3 = false;
        };

        runtimeDeps = with pkgs; [
          bash
          bluez
          brightnessctl
          cava
          cliphist
          coreutils
          ddcutil
          file
          findutils
          gpu-screen-recorder
          libnotify
          matugen
          networkmanager
          wl-clipboard
        ];

        fontconfig = pkgs.makeFontsConf {
          fontDirectories = [
            pkgs.roboto
            pkgs.inter-nerdfont
          ];
        };
      in {
        default = pkgs.stdenv.mkDerivation {
          pname = "noctalia-shell";
          version = self.rev or self.dirtyRev or "dirty";
          src = ./.;

          nativeBuildInputs = [pkgs.gcc pkgs.makeWrapper pkgs.qt6.wrapQtAppsHook];
          buildInputs = [qs pkgs.xkeyboard-config pkgs.qt6.qtbase];
          propagatedBuildInputs = runtimeDeps;

          installPhase = ''
            mkdir -p $out/share/noctalia-shell
            cp -r ./* $out/share/noctalia-shell

            makeWrapper ${qs}/bin/qs $out/bin/noctalia-shell \
              --prefix PATH : "${pkgs.lib.makeBinPath runtimeDeps}" \
              --set FONTCONFIG_FILE "${fontconfig}" \
              --add-flags "-p $out/share/noctalia-shell"
          '';

          meta = {
            description = "A sleek and minimal desktop shell thoughtfully crafted for Wayland, built with Quickshell.";
            homepage = "https://github.com/noctalia-dev/noctalia-shell";
            license = pkgs.lib.licenses.mit;
            mainProgram = "noctalia-shell";
          };
        };
      }
    );

    defaultPackage = eachSystem (system: self.packages.${system}.default);
  };
}