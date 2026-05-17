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
    git curl wget gptfdisk parted hyprland
  ];

  nixpkgs.config.allowUnfree = true;


  system.stateVersion = "25.05";
}
