{pkgs, ...}: 
let 
  base = (import ../../../materials/themes {}).base;
  mantle = (import ../../../materials/themes {}).surface;
  crust = (import ../../../materials/themes {}).background;
  text = (import ../../../materials/themes {}).foreground;
  subtext = (import ../../../materials/themes {}).foreground-secondary;
  mauve = (import ../../../materials/themes {}).mauve;
  blue = (import ../../../materials/themes {}).blue;
  teal = (import ../../../materials/themes {}).teal;
  red = (import ../../../materials/themes {}).red;
  yellow = (import ../../../materials/themes {}).yellow;
  green = (import ../../../materials/themes {}).green; 
  peach = (import ../../../materials/themes {}).peach;
  overlay0 = (import ../../../materials/themes {}).selection;
  surface2 = (import ../../../materials/themes {}).surface;
in
{
  programs.kitty = {
    enable = true;

    keybindings = {
  	"ctrl+left" = "neighboring_window left";
  	"ctrl+up" = "neighboring_window up";
  	"ctrl+right" = "neighboring_window right";
  	"ctrl+down" = "neighboring_window down";
  	"shift+left" = "move_window left";
  	"shift+up" = "move_window up";
  	"shift+right" = "move_window right";
  	"shift+down" = "move_window down";
    };

    settings = {
      shell = "zsh";
      font_family = "Cartograph CF Nerd Font"; 
      font_size = 12;

      # Catppuccin Macchiato Mauve colors
      background = base; # base
      foreground = text; # text
      selection_background = overlay0; # surface2
      cursor = mauve;
      url_cursor = blue;

      # Tabs
      active_tab_background = mauve; # mauve
      active_tab_foreground = crust; # mantle
      inactive_tab_background = crust; # crust
      inactive_tab_foreground = overlay0; # overlay0
      tab_bar_background = mantle; # mantle

      # Windows
      active_border_color = mauve; # mauve
      inactive_border_color = surface2; # surface1
      
      tab_bar_style = "powerline";
      tab_bar_align = "left";
      tab_bar_min_tabs = 2;
      tab_powerline_style = "round";

     };
  };
}
