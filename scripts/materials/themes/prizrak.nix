{ pkgs, ... }:
{
  stylix = {
    enable = true;
    base16Scheme = {
    base00 = "09090B"; # Default Background
    base01 = "1c1e1f"; # Lighter Background (Used for status bars, line number and folding marks)
    base02 = "313244"; # Selection Background
    base03 = "45475a"; # Comments, Invisibles, Line Highlighting
    base04 = "585b70"; # Dark Foreground (Used for status bars)
    base05 = "cdd6f4"; # Default Foreground, Caret, Delimiters, Operators
    base06 = "f5e0dc"; # Light Foreground (Not often used)
    base07 = "b4befe"; # Light Background (Not often used)
    base08 = "f38ba8"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
    base09 = "fab387"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url
    base0A = "f9e2af"; # Classes, Markup Bold, Search Text Background
    base0B = "a6e3a1"; # Strings, Inherited Class, Markup Code, Diff Inserted
    base0C = "94e2d5"; # Support, Regular Expressions, Escape Characters, Markup Quotes
    base0D = "8771DA"; # Functions, Methods, Attribute IDs, Headings, Accent color
    base0E = "cba6f7"; # Keywords, Storage, Selector, Markup Italic, Diff Changed
    base0F = "f2cdcd"; # Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?>

  };
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
    };
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };   
    iconTheme = {
      enable = true;
      package = pkgs.morewaita-icon-theme;
      dark = "Papirus-Dark";             
      light = "Papirus-Light";          
    };
  };

  stylix.targets.gtk.enable = true;
  stylix.targets.qt.enable = true;
  qt.platformTheme = "qt5ct";
}
