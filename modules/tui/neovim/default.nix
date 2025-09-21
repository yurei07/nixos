{ pkgs, ... }:
{
  imports = [
    ./nvim
    ./development
  ];

  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      neovim-remote
    ];
  };
}
