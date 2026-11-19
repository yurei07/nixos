# kitty terminal configuration.
{ pkgs, lib, config, ... }:
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
      scrollback_lines = 10000;
      initial_window_width = 1200;
      initial_window_height = 600;
      update_check_interval = 0;
      enable_audio_bell = false;
      confirm_os_window_close = "0";
      remember_window_size = "no";
      disable_ligatures = "never";
      url_style = "curly";
      copy_on_select = "clipboard";
      cursor_shape = "Underline";
      cursor_underline_thickness = 3;
      cursor_trail = 3;
      cursor_trail_decay = "0.1 0.4";
      window_padding_width = 10;
      open_url_with = "default";
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/mykitty";

      # Nothing OS look: black background, white text, red accent.
      font_family = "Lettera Mono LL";
      bold_font = "Lettera Mono LL Medium";
      italic_font = "Lettera Mono LL Italic";
      bold_italic_font = "Lettera Mono LL Medium Italic";
      font_size = 13;

      foreground = "#E8E8E8";
      background = "#000000";
      cursor = "#D71921";

      active_tab_foreground = "#000000";
      active_tab_background = "#FFFFFF";
      inactive_tab_foreground = "#8C8C8C";
      inactive_tab_background = "#000000";
      active_border_color = "#FFFFFF";
      inactive_border_color = "#2E2E2E";
      bell_border_color = "#D71921";

      color0 = "#000000";
      color1 = "#D71921";
      color2 = "#A3BE9A";
      color3 = "#D8C27E";
      color4 = "#8FA6BD";
      color5 = "#B69CB8";
      color6 = "#92B8B4";
      color7 = "#BDBDBD";
      color8 = "#4D4D4D";
      color9 = "#FF4D4D";
      color10 = "#C2D9BA";
      color11 = "#E9D9A6";
      color12 = "#B3C4D6";
      color13 = "#D0BBD2";
      color14 = "#B6D3CF";
      color15 = "#FFFFFF";

      selection_foreground = "#000000";
      selection_background = "#FFFFFF";
      background_opacity = 0.95;
      tab_bar_style = "powerline";
      tab_powerline_style = "round";
    };
  };

  xdg.configFile = {
    # Kitty kittens for vim-aware window navigation.
    "kitty/pass_keys.py".text = ''
      import re

      from kittens.tui.handler import result_handler
      from kitty.key_encoding import KeyEvent, parse_shortcut


      def is_window_vim(window, vim_id):
          fp = window.child.foreground_processes
          return any(re.search(vim_id, p['cmdline'][0] if len(p['cmdline']) else "", re.I) for p in fp)


      def encode_key_mapping(window, key_mapping):
          mods, key = parse_shortcut(key_mapping)
          event = KeyEvent(
              mods=mods,
              key=key,
              shift=bool(mods & 1),
              alt=bool(mods & 2),
              ctrl=bool(mods & 4),
              super=bool(mods & 8),
              hyper=bool(mods & 16),
              meta=bool(mods & 32),
          ).as_window_system_event()

          return window.encoded_key(event)


      def main():
          pass


      @result_handler(no_ui=True)
      def handle_result(args, result, target_window_id, boss):
          direction = args[1]
          key_mapping = args[2]
          vim_id = args[3] if len(args) > 3 else "n?vim"

          window = boss.window_id_map.get(target_window_id)

          if window is None:
              return
          if is_window_vim(window, vim_id):
              for keymap in key_mapping.split(">"):
                  encoded = encode_key_mapping(window, keymap)
                  window.write_to_child(encoded)
          else:
              boss.active_tab.neighboring_window(direction)
    '';
    "kitty/neighboring_window.py".text = ''
      def main():
          pass


      def handle_result(args, result, target_window_id, boss):
          return boss.active_tab.current_layout.name


      handle_result.no_ui = True
    '';
  };
}
