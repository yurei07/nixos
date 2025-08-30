{pkgs, ...}: 
let 
  base00 = (import ../../../materials/themes {}).base00;
  base01 = (import ../../../materials/themes {}).base01;
  base02 = (import ../../../materials/themes {}).base02;
  base03 = (import ../../../materials/themes {}).base03;
  base04 = (import ../../../materials/themes {}).base04;
  base05 = (import ../../../materials/themes {}).base05;
  base06 = (import ../../../materials/themes {}).base06;
  base07 = (import ../../../materials/themes {}).base07;
  base08 = (import ../../../materials/themes {}).base08;
  base09 = (import ../../../materials/themes {}).base09;
  base0A = (import ../../../materials/themes {}).base0A;
  base0B = (import ../../../materials/themes {}).base0B;
  base0C = (import ../../../materials/themes {}).base0C;
  base0D = (import ../../../materials/themes {}).base0D;
  base0E = (import ../../../materials/themes {}).base0E;
  base0F = (import ../../../materials/themes {}).base0F;
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

      background = base00;
      foreground = base05;
      selection_background = base01;
      cursor = base0D;
      url_cursor = base08;

      # Tabs
      active_tab_background = base0D;
      active_tab_foreground = base04;
      inactive_tab_background = base03;
      inactive_tab_foreground = base0E;
      tab_bar_background = base00;

      # Windows
      active_border_color = base0D;
      inactive_border_color = base01;

      tab_bar_style = "powerline";
      tab_bar_align = "left";
      tab_bar_min_tabs = 2;
      tab_powerline_style = "round";
    };
  };
}
