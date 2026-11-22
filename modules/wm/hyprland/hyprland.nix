# Hyprland configuration.
# Written as Hyprland 0.57 Lua: Home Manager renders every attrset below into
# `hl.*` calls (`hl.config`, `hl.bind`, `hl.monitor`, ...). Keep helper Lua
# snippets inline when the HM generator can't express a call directly.
{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  # Raw Lua expressions for Home Manager's Lua config generator.
  lua = lib.generators.mkLuaInline;

  exec = command: lua "hl.dsp.exec_cmd(${builtins.toJSON command})";

  # Key strings built from the `mod` local in the generated Lua.
  modPlus = keys: lua "mod .. \" + ${keys}\"";

  bind = key: action: {
    _args = [
      key
      action
    ];
  };

  # Hyprland 0.57 Lua has no `hl.bindm`; mouse binds are normal binds with
  # `{ mouse = true }`.
  mouseBind =
    key: action:
    {
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

  opacityRule =
    match:
    {
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
    configType = "lua";

    settings = {
      mod = {
        _var = "SUPER";
      };
      shiftMod = {
        _var = "SUPER_SHIFT";
      };

      config = {
        general = {
          resize_on_border = true;
          border_size = 1;
          gaps_out = 14;
          gaps_in = 7;
          layout = "dwindle";
        };
        decoration = {
          active_opacity = 1;
          inactive_opacity = 0.9;
          dim_inactive = true;
          dim_strength = 0.1;
          rounding = 16;
          blur = {
            enabled = true;
            popups = true;
            popups_ignorealpha = 0;
            ignore_opacity = true;
            size = 6;
            passes = 3;
            xray = true;
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
            "nothingOut"
            {
              type = "bezier";
              points = [
                [ 0.22 1 ]
                [ 0.36 1 ]
              ];
            }
          ];
        }
        {
          _args = [
            "nothingExpo"
            {
              type = "bezier";
              points = [
                [ 0.16 1 ]
                [ 0.3 1 ]
              ];
            }
          ];
        }
        {
          _args = [
            "linear"
            {
              type = "bezier";
              points = [
                [ 0 0 ]
                [ 1 1 ]
              ];
            }
          ];
        }
      ];

      animation = [
        {
          leaf = "global";
          enabled = true;
          speed = 2;
          bezier = "nothingOut";
        }
        {
          leaf = "windows";
          enabled = true;
          speed = 2.5;
          bezier = "nothingOut";
          style = "popin 90%";
        }
        {
          leaf = "windowsOut";
          enabled = true;
          speed = 1.8;
          bezier = "nothingExpo";
          style = "popin 90%";
        }
        {
          leaf = "windowsMove";
          enabled = true;
          speed = 2.5;
          bezier = "nothingOut";
        }
        {
          leaf = "layers";
          enabled = true;
          speed = 1.8;
          bezier = "nothingExpo";
          style = "fade";
        }
        {
          leaf = "fade";
          enabled = true;
          speed = 2;
          bezier = "nothingOut";
        }
        {
          leaf = "border";
          enabled = true;
          speed = 1.5;
          bezier = "linear";
        }
        {
          leaf = "borderangle";
          enabled = false;
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = 3;
          bezier = "nothingOut";
          style = "slide";
        }
      ];

      bind = [
        # apps
        (bind (modPlus "RETURN") (exec "kitty"))
        (bind (modPlus "Y") (exec "${../../../scripts/nvim.sh}"))
        (bind (modPlus "E") (exec "nautilus"))
        (bind (modPlus "B") (exec "zen-beta"))
        (bind (modPlus "SHIFT + D") (exec "vesktop"))
        (bind (modPlus "O") (exec "obsidian"))

        # window management
        (bind (modPlus "Q") closeWindow)
        (bind (modPlus "W") toggleFloat)
        (bind (modPlus "G") toggleFullscreen)
        (bind (modPlus "SPACE") (exec "qs ipc -c nothing call controlcenter toggle"))
        (bind (modPlus "D") (exec "sh -c 'rofi -show drun -theme $HOME/.config/rofi/nothing-grid.rasi'"))
        (bind "CTRL + ALT + P" (exec "qs ipc -c nothing call powermenu toggle"))
        (bind (modPlus "CTRL + R") (exec "killall -SIGUSR1 gpu-screen-recorder && notify-send 'GPU-Screen-Recorder' 'Replay saved'"))

        # media / brightness keys
        (bind "XF86AudioRaiseVolume" (exec "sh -c 'wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+; qs ipc -c nothing call osd volume'"))
        (bind "XF86AudioLowerVolume" (exec "sh -c 'wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-; qs ipc -c nothing call osd volume'"))
        (bind "XF86AudioMute" (exec "sh -c 'wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; qs ipc -c nothing call osd volume'"))
        (bind "XF86AudioMicMute" (exec "sh -c 'wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; qs ipc -c nothing call osd mic'"))
        (bind "XF86MonBrightnessUp" (exec "sh -c 'brightnessctl -q set 5%+; qs ipc -c nothing call osd brightness'"))
        (bind "XF86MonBrightnessDown" (exec "sh -c 'brightnessctl -q set 5%-; qs ipc -c nothing call osd brightness'"))

        # screenshots / monitor toggle
        (bind "Print" (exec "hyprshot -m output"))
        (bind "SHIFT + Print" (exec "hyprshot -m region"))
        (bind (modPlus "V") (exec "hyprctl keyword monitor 'HDMI-A-1', 2560x1080@180, -1080x0, 1, transform, 1"))
        (bind (modPlus "H") (exec "hyprctl keyword monitor 'HDMI-A-1', 2560x1080@180, -2560x0, 1, transform, 0"))

        # workspaces
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

        # mouse
        (mouseBind (modPlus "mouse:272") dragWindow)
        (mouseBind (modPlus "mouse:273") resizeWindow)
      ];

      env = [
        { _args = [ "XCURSOR_THEME" "Bibata-Modern-Ice" ]; }
        { _args = [ "XDG_CURRENT_DESKTOP" "Hyprland" ]; }
        { _args = [ "XDG_SESSION_TYPE" "wayland" ]; }
        { _args = [ "XDG_SESSION_DESKTOP" "Hyprland" ]; }
        { _args = [ "QT_QPA_PLATFORM" "wayland" ]; }
        { _args = [ "QT_WAYLAND_DISABLE_WINDOWDECORATION" "1" ]; }
        { _args = [ "QT_AUTO_SCREEN_SCALE_FACTOR" "1" ]; }
        { _args = [ "XCURSOR_SIZE" "24" ]; }
        { _args = [ "NIXOS_OZONE_WL" "1" ]; }
      ];

      # Autostart: the systemd/dbus hook comes from Home Manager, this is only
      # for user-facing daemons/apps.
      on = {
        _args = [
          "hyprland.start"
          (lua ''
            function()
              hl.exec_cmd("awww-daemon")
              hl.exec_cmd("sh $HOME/Pictures/wallpapers/nothing/nothing-wallpaper.sh")
              hl.exec_cmd("swaync")
              hl.exec_cmd("qs -c nothing")
              -- live ISO: show the welcome card once the desktop is up
              hl.exec_cmd("sh -c '[ -f /etc/nixos-live/flag ] && kitty --title welcome /etc/nixos-live/welcome'")
            end
          '')
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
          match.namespace = "nothing-widgets";
          blur = true;
          ignore_alpha = 0.2;
        }
        {
          match.namespace = "nothing-dock";
          blur = true;
          ignore_alpha = 0.3;
          xray = false;
          no_anim = true;
        }
        {
          match.namespace = "nothing-controlcenter";
          blur = true;
          ignore_alpha = 0.3;
          xray = false;
          no_anim = true;
        }
        {
          match.namespace = "nothing-osd";
          blur = true;
          ignore_alpha = 0.3;
          xray = false;
        }
        {
          match.namespace = "nothing-powermenu";
          blur = true;
          xray = false;
          no_anim = true;
        }
        {
          match.namespace = "rofi";
          animation = "popin 90%";
        }
        {
          match.namespace = "swaync-control-center";
          animation = "slide right";
        }
        {
          match.namespace = "swaync-notification-window";
          animation = "slide top";
        }
      ];
    };
  };
}
