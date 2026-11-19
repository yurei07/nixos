# User-level terminal module entry point.
{ ... }:
{
  imports = [
    ./nh/nh.nix
    ./zsh/zsh.nix
    ./kitty/kitty.nix
    ./neovim/neovim.nix
    ./fastfetch/fastfetch.nix
    ./nothing-themes.nix
  ];
}
