{pkgs, ...}: 
let 
  colors = import ../../../materials/themes { };
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

      background = colors.base00;
      foreground = colors.base05;
      selection_background = colors.base01;
      cursor = colors.base0D;
      url_cursor = colors.base08;

      # Tabs
      active_tab_background = colors.base0D;
      active_tab_foreground = colors.base04;
      inactive_tab_background = colors.base03;
      inactive_tab_foreground = colors.base0E;
      tab_bar_background = colors.base00;

      # Windows
      active_border_color = colors.base0D;
      inactive_border_color = colors.base01;

      tab_bar_style = "powerline";
      tab_bar_align = "left";
      tab_bar_min_tabs = 2;
      tab_powerline_style = "round";

      allow_remote_control = "yes";
    };
  };
}
