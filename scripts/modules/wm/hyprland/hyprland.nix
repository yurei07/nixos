{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:
let
  crust1 = (import ../../../materials/themes { }).crust1;
  mantle1 = (import ../../../materials/themes { }).mantle1;
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

    settings = {
      "$mod" = "SUPER";
      "$shiftMod" = "SUPER_SHIFT";

      bind = [
        "$mod, RETURN, exec, kitty"
        "$mod, Y, exec, ${../../../scripts/nvim.sh}"
        "$mod, E, exec, nautilus"
        "$mod, B, exec, zen"
        "$mod, D, exec, discord"
        "$mod, O, exec, obsidian"
        "$mod, Q, killactive"
        "$mod, W, togglefloating"
        "$mod, G, fullscreen"
        "$mod, SPACE, exec, noctalia-shell ipc call launcher toggle"
        "$mod CTRL, R, exec, killall -SIGUSR1 gpu-screen-recorder && notify-send 'GPU-Screen-Recorder' 'Повтор успешно сохранён'"
        # "$mod, SPACE, exec, caelestia shell drawers toggle launcher "

        ", Print, exec, hyprshot -m output"
        "SHIFT, Print, exec, hyprshot -m region"

        "$mod, V, exec, hyprctl keyword monitor 'HDMI-A-1', 2560x1080@180, -1080x0, 1, transform, 1'"
        "$mod, H, exec, hyprctl keyword monitor 'HDMI-A-1', 2560x1080@180, -2560x0, 1, transform, 0'"

        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"

        # Thinkpad
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86AudioLowerVolume, exec, noctalia-shell ipc call volume decrease"
        ", XF86AudioRaiseVolume, exec, noctalia-shell ipc call volume increase"
        ", XF86AudioMute, exec, noctalia-shell ipc call volume muteOutpute"

      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
      exec-once = [
        "noctalia-shell"
      ];

      monitor = [
        # Thinkpad
        #"DPe-1,1920x1080@60,0x0,1.2" # FOR MY LAPTOP

        "DP-1,2560x1440@165.00,0x0,1"
        "DP-2,2560x1080@200,-1080x0,1, transform, 1"

      ];
      windowrule = [
        "no_max_size on, match:class polkit-mate-authentication-agent-1"
        "pin on, match:class polkit-mate-authentication-agent-1"
        "opacity 0.99 override 0.99 override, match:title QDiskInfo"
        "opacity 0.99 override 0.99 override, match:title MainPicker"
        "opacity 0.99 override 0.99 override, match:class thunderbird"
        "opacity 0.99 override 0.99 override, match:class spotify"
        "opacity 0.99 override 0.99 override, match:class org.prismlauncher.PrismLauncher"
        "opacity 0.99 override 0.99 override, match:class mpv"
        "opacity 0.99 override 0.99 override, match:class org.qbittorrent.qBittorrent"
        "opacity 0.99 override 0.99 override, match:class die"
      ];
      layerrule = [
        # "blur on, match:namespace .*"
        "blur_popups on, match:namespace .*"
        "no_anim on, match:namespace selection"
        "ignore_alpha 0.9, match:namespace selection"
        "ignore_alpha 0, match:namespace corner0"
        "ignore_alpha 0, match:namespace overview"
        "ignore_alpha 0, match:namespace indicator0"
        "ignore_alpha 0, match:namespace datemenu"
        "ignore_alpha 0, match:namespace launcher"
        "ignore_alpha 0, match:namespace quicksettings"
        "ignore_alpha 0, match:namespace swaync-control-center"
        "ignore_alpha 0, match:namespace swaync-notification-window"
        "animation popin 90%, match:namespace logout_dialog"
        "animation slide left, match:namespace swaync-control-center"
      ];

      env = [
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "__GL_GSYNC_ALLOWED,0"
        "__GL_VRR_ALLOWED,0"
        "QT_QPA_PLATFORM,wayland"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "XCURSOR_SIZE,24"
        "NIXOS_OZONE_WL,1"
        "WLR_NO_HARDWARE_CURSORS,1"
      ];

      general = {
        resize_on_border = true;
        border_size = 2;
        gaps_out = 25;
        gaps_in = 10;
        layout = "dwindle";
        "col.active_border" = lib.mkForce "rgb(${config.lib.stylix.colors.base0D})"; 
      };
      decoration = {
        active_opacity = 1;
        inactive_opacity = 0.85;
        rounding = 12;
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
        shadow = {
          enabled = true;
          range = 20;
        };
      };

      cursor = {
        no_hardware_cursors = true;
        default_monitor = "DP-1";
      };

      input = {
        kb_layout = "us,ru, de";
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
      };

      animations = {
        enabled = true;
        bezier = [
          "easein, 0.11, 0, 0.5, 0"
          "easeout, 0.5, 1, 0.89, 1"
          "easeinout, 0.65, 0, 0.35, 1"
        ];
        animation = [
          "windows, 1, 3, easeout, slide"
          "windowsOut, 1, 3, easein, slide"
          "border, 1, 10, default"
          "fade, 1, 5, default"
          "workspaces, 1, 4, easeinout, slide"
        ];
      };

      windowrulev2 = [
        # "noborder, fullscreen:1"
        # "opacity 0.95 0.90, class:^(kitty)$"
        # "opacity 0.92 0.88, class:^(Code)$"
      ];

      misc = {
        disable_hyprland_logo = true;
      };
    };
  };
}
