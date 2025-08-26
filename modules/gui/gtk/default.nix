{
  pkgs,
  ...
}:
{
#  qt = {
#      enable = true;
#      platformTheme.name = "gtk";
#  };
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 20;
  };
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-lavender-compact";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "lavender" ];
        variant = "mocha";
        size = "compact";
      };
    };
  #  iconTheme = {
  #    name = "Tela-circle-dark";
  #    package = pkgs.tela-circle-icon-theme;
  #  };
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
