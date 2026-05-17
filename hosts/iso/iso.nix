{ pkgs, modulesPath, inputs, lib, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"

    ../../modules/wm/hyprland.nix      
    ../../modules/gui                   
    ../../modules/tui                   

    ../../materials/themes/prizrak.nix

    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
  ];

  isoImage.isoName = "nixos-prizrak-live.iso";
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";
  isoImage.includeSystemBuildDependencies = false;

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "input" "networkmanager" ];
    password = "";          
    initialPassword = "nixos";
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
    users.nixos = import ./iso-user.nix;
  };

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    gptfdisk
    parted
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
