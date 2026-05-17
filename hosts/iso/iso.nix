{ pkgs, modulesPath, inputs, lib, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ../../materials/themes/prizrak.nix
    inputs.stylix.nixosModules.stylix
    inputs.home-manager.nixosModules.home-manager
  ];

  isoImage.isoName = "nixos-prizrak-live.iso";
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  users.users.nixos = {
    isNormalUser = true;
    initialPassword = "nixos";
    extraGroups = [ "wheel" "video" "audio" "input" "networkmanager" ];
  };

  services.getty.autologinUser = lib.mkForce "nixos";

  programs.bash.loginShellInit = ''
    if [ "$(tty)" = "/dev/tty1" ]; then
      exec Hyprland
    fi
  '';

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.nixos = { pkgs, ... }: {
      home.username = "nixos";
      home.homeDirectory = "/home/nixos";
      home.stateVersion = "25.05";
    };
  };

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    gptfdisk
    parted
    hyprland
  ];

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cache.garnix.io"
      "https://zen-browser.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCUSDs="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "zen-browser.cachix.org-1:ePDN0rkGMKQBBkDMBNJBNmRR5jCH3cOWYL6VEwCN5E="
    ];
  };

  system.stateVersion = "25.05";
}
