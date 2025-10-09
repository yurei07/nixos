{
  pkgs,
  ...
}:
let 
  Theme = import ./packages_theme.nix { inherit pkgs; };
in
{
  qt = {
      enable = true;
      platformTheme.name = "gtk";
  };
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 20;
  };
  gtk = {
    enable = true;
    theme = {
      name = "Goth_theme-2025-04-17-grey-Dark";
      package = Theme;
    };
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };
    font = {
      name = "Roboto";
      size = 11;
    };
  };
}
