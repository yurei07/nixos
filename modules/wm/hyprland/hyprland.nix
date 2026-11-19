{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  # Raw Lua expressions for Home Manager's Lua config generator.
  lua = lib.generators.mkLuaInline;

  # Nix string -> quoted Lua string literal.
  str = value: lua (builtins.toJSON value);

  exec = command: lua "hl.dsp.exec_cmd(${builtins.toJSON command})";

  # Key references using the `mod` local defined in settings.
  modPlus = keys: lua "mod .. \" + ${keys}\"";

  # hl.bind(key, action) / hl.bind(key, action, { mouse = true })
  bind = key: action: {
    _args = [
      key
      action
    ];
  };
  mouseBind = key: action: {
    _args = [
      key
      action
      { mouse = true; }
    ];
  };

  closeWindow = lua "hl.dsp.window.close()";
  toggleFloat = lua "hl.dsp.window.float({ action = \"toggle\" })";
  toggleFullscreen = lua "hl.dsp.window.fullscreen({ action = \"toggle\" })";
  dragWindow = lua "hl.dsp.window.drag()";
  resizeWindow = lua "hl.dsp.window.resize()";

  focusWorkspace = workspace: lua "hl.dsp.focus({ workspace = ${toString workspace} })";
  moveToWorkspace = workspace: lua "hl.dsp.window.move({ workspace = ${toString workspace} })";

  targetOpacity = "0.99 override 0.99 override";

  opacityRule = match: {
    match = match;
    opacity = targetOpacity;
  };
in
{
  home.packages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    hyprshot
    hyprpicker
    swappy
    wf-recorder
    wlr-randr
    wl-clipboard
    cliphist
  ];

  wayland.windowManager.hyprland = {
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    enable = true;
    xwayland.enable = true;
    # Hyprland 0.57 reads hyprland.lua only; the old hyprlang .conf is ignored.
    configType = "lua";

    settings = {
      mod = {
        _var = "SUPER";
      };
      shiftMod = {
        _var = "SUPER_SHIFT";
      };

      # General config options -> hl.config({ ... })
      config = {
        general = {
          resize_on_border = true;
          border_size = 2;
          gaps_out = 25;
          gaps_in = 10;
          layout = "dwindle";
        };
        decoration = {
          active_opacity = 1;
          inactive_opacity = 0.85;
          rounding = 0;
          blur = {
            enabled = true;
            popups = true;
            popups_ignorealpha = 0;
            ignore_opacity = true;
            size = 10;
            brightness = 0.6;
            passes = 4;
            noise = 0;
            vibrancy = 0;
          };
        };
        cursor = {
          no_hardware_cursors = 1;
          default_monitor = "DP-1";
        };
        input = {
          kb_layout = "us,ru";
          kb_options = "grp:alt_shift_toggle";
          follow_mouse = 1;
        };
        misc = {
          enable_swallow = true;
          animate_manual_resizes = false;
          animate_mouse_windowdragging = false;
          swallow_regex = "^(kitty|lutris|bottles|alacritty)$";
          swallow_exception_regex = "^(ncspot)$";
          force_default_wallpaper = 2;
          disable_hyprland_logo = true;
        };
        animations = {
          enabled = true;
        };
      };

      monitor = [
        # Internal laptop panel (Huawei MateBook D, 15.6" 1920x1080).
        {
          output = "eDP-1";
          mode = "preferred";
          position = "0x0";
          scale = 1;
        }
        {
          output = "DP-1";
          mode = "2560x1440@165.00";
          position = "0x0";
          scale = 1;
        }
        {
          output = "HDMI-A-1";
          mode = "2560x1080@180";
          position = "-1080x0";
          scale = 1;
          transform = 1;
        }
      ];

      curve = [
        {
          _args = [
            "easein"
            {
              type = "bezier";
              points = [
                [ 0.11 0 ]
                [ 0.5 0 ]
              ];
            }
          ];
        }
        {
          _args = [
            "easeout"
            {
              type = "bezier";
              points = [
                [ 0.5 1 ]
                [ 0.89 1 ]
              ];
            }
          ];
        }
        {
          _args = [
            "easeinout"
            {
              type = "bezier";
              points = [
                [ 0.65 0 ]
                [ 0.35 1 ]
              ];
            }
          ];
        }
      ];

      animation = [
        {
          leaf = "windows";
          enabled = true;
          speed = 3;
          bezier = "easeout";
          style = "slide";
        }
        {
          leaf = "windowsOut";
          enabled = true;
          speed = 3;
          bezier = "easein";
          style = "slide";
        }
        {
          leaf = "border";
          enabled = true;
          speed = 10;
          bezier = "default";
        }
        {
          leaf = "fade";
          enabled = true;
          speed = 5;
          bezier = "default";
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = 4;
          bezier = "easeinout";
          style = "slide";
        }
      ];

      bind = [
        (bind (modPlus "RETURN") (exec "kitty"))
        (bind (modPlus "Y") (exec "${../../../scripts/nvim.sh}"))
        (bind (modPlus "E") (exec "nautilus"))
        (bind (modPlus "B") (exec "zen-beta"))
        (bind (modPlus "D") (exec "discord"))
        (bind (modPlus "O") (exec "obsidian"))
        (bind (modPlus "Q") closeWindow)
        (bind (modPlus "W") toggleFloat)
        (bind (modPlus "G") toggleFullscreen)
        (bind (modPlus "SPACE") (exec "noctalia msg panel-toggle launcher"))
        (bind (modPlus "CTRL + R") (exec "killall -SIGUSR1 gpu-screen-recorder && notify-send 'GPU-Screen-Recorder' 'Повтор успешно сохранён'"))

        (bind "Print" (exec "hyprshot -m output"))
        (bind "SHIFT + Print" (exec "hyprshot -m region"))

        (bind (modPlus "V") (exec "hyprctl keyword monitor 'HDMI-A-1', 2560x1080@180, -1080x0, 1, transform, 1"))
        (bind (modPlus "H") (exec "hyprctl keyword monitor 'HDMI-A-1', 2560x1080@180, -2560x0, 1, transform, 0"))

        (bind (modPlus "1") (focusWorkspace 1))
        (bind (modPlus "2") (focusWorkspace 2))
        (bind (modPlus "3") (focusWorkspace 3))
        (bind (modPlus "4") (focusWorkspace 4))
        (bind (modPlus "5") (focusWorkspace 5))
        (bind (modPlus "6") (focusWorkspace 6))
        (bind (modPlus "7") (focusWorkspace 7))
        (bind (modPlus "8") (focusWorkspace 8))
        (bind (modPlus "9") (focusWorkspace 9))
        (bind (modPlus "0") (focusWorkspace 10))

        (bind (modPlus "SHIFT + 1") (moveToWorkspace 1))
        (bind (modPlus "SHIFT + 2") (moveToWorkspace 2))
        (bind (modPlus "SHIFT + 3") (moveToWorkspace 3))
        (bind (modPlus "SHIFT + 4") (moveToWorkspace 4))
        (bind (modPlus "SHIFT + 5") (moveToWorkspace 5))
        (bind (modPlus "SHIFT + 6") (moveToWorkspace 6))
        (bind (modPlus "SHIFT + 7") (moveToWorkspace 7))
        (bind (modPlus "SHIFT + 8") (moveToWorkspace 8))
        (bind (modPlus "SHIFT + 9") (moveToWorkspace 9))
        (bind (modPlus "SHIFT + 0") (moveToWorkspace 10))

        (bind (modPlus "S") (lua "hl.dsp.workspace.toggle_special(\"magic\")"))
        (bind (modPlus "SHIFT + S") (lua "hl.dsp.window.move({ workspace = \"special:magic\" })"))

        # Mouse binds: hl.bindm does not exist in Hyprland 0.57 Lua.
        (mouseBind (modPlus "mouse:272") dragWindow)
        (mouseBind (modPlus "mouse:273") resizeWindow)
      ];

      env = [
        { _args = [ "XCURSOR_THEME" "Numix-Cursor" ]; }
        { _args = [ "XDG_CURRENT_DESKTOP" "Hyprland" ]; }
        { _args = [ "XDG_SESSION_TYPE" "wayland" ]; }
        { _args = [ "XDG_SESSION_DESKTOP" "Hyprland" ]; }
        { _args = [ "QT_QPA_PLATFORM" "wayland" ]; }
        { _args = [ "QT_WAYLAND_DISABLE_WINDOWDECORATION" "1" ]; }
        { _args = [ "QT_AUTO_SCREEN_SCALE_FACTOR" "1" ]; }
        { _args = [ "XCURSOR_SIZE" "24" ]; }
        { _args = [ "NIXOS_OZONE_WL" "1" ]; }
      ];

      # Autostart. Home Manager already emits the systemd/dbus startup hook
      # when systemd.enable is true (the default), so this is just your app.
      on = {
        _args = [
          "hyprland.start"
          (lua "function() hl.exec_cmd(\"noctalia\") end")
        ];
      };

      window_rule = [
        {
          match.class = "polkit-mate-authentication-agent-1";
          no_max_size = true;
          pin = true;
        }
        (opacityRule { title = "QDiskInfo"; })
        (opacityRule { title = "MainPicker"; })
        (opacityRule { class = "thunderbird"; })
        (opacityRule { class = "spotify"; })
        (opacityRule { class = "org.prismlauncher.PrismLauncher"; })
        (opacityRule { class = "mpv"; })
        (opacityRule { class = "org.qbittorrent.qBittorrent"; })
        (opacityRule { class = "die"; })
      ];

      layer_rule = [
        {
          match.namespace = ".*";
          blur_popups = true;
        }
        {
          match.namespace = "selection";
          no_anim = true;
          ignore_alpha = 0.9;
        }
        {
          match.namespace = "corner0";
          ignore_alpha = 0;
        }
        {
          match.namespace = "overview";
          ignore_alpha = 0;
        }
        {
          match.namespace = "indicator0";
          ignore_alpha = 0;
        }
        {
          match.namespace = "datemenu";
          ignore_alpha = 0;
        }
        {
          match.namespace = "launcher";
          ignore_alpha = 0;
        }
        {
          match.namespace = "quicksettings";
          ignore_alpha = 0;
        }
        {
          match.namespace = "swaync-control-center";
          ignore_alpha = 0;
        }
        {
          match.namespace = "swaync-notification-window";
          ignore_alpha = 0;
        }
        {
          match.namespace = "logout_dialog";
          animation = "popin 90%";
        }
        {
          match.namespace = "swaync-control-center";
          animation = "slide left";
        }
      ];
    };
  };
}
