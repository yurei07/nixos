# System fonts and fontconfig defaults.
{config, pkgs, ...}:
{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      inter
      noto-fonts
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      material-symbols
      vazirmatn
    ];

    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Inter" "Noto Sans" ];
        monospace = [ "JetBrains Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}

