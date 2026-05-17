{ pkgs, inputs, ... }:
{
  imports = [
    ../Prizrak/home/home-configuration.nix
  ];

  home.username = "Prizrak";
  home.homeDirectory = "/home/Prizrak";

  # Если home-конфиг зависит от hardware — лучше продублировать нужное вручную
  # например:
  # programs.zsh.enable = true;
  # programs.kitty.enable = true;

  home.stateVersion = "25.05";
}
