{pkgs, config, inputs, ... }:
let 
  crust1 = (import ../../../materials/themes {}).crust1;
  mantle1 = (import ../../../materials/themes {}).mantle1;
in
{

  home.packages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.qt5ct
    qt6ct
    hyprshot
    hyprpicker
    swappy
    nautilus
    wf-recorder
    wlr-randr
    wl-clipboard
    cliphist  
  ];


  wayland.windowManager.hyprland = {
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
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
	"$mod, SPACE, exec, rofi -show drun"
        
        ", Print, exec, hyprshot -m output"
        "SHIFT, Print, exec, hyprshot -m region"

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
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
      exec-once = [
      "qs -d"
      ];

      monitor = [
        "DP-1,1920x1080@60,-1920x0,1" 
        "HDMI-A-1,1920x1080@120,0x0,1"
        "DP-2,1920x1080@60,0x-1080,1"
      ];

      env = [
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "__GL_GSYNC_ALLOWED,0"
        "__GL_VRR_ALLOWED,0"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "XCURSOR_SIZE,24"
        "NIXOS_OZONE_WL,1"  
      ];

      windowrule = [
	"nomaxsize, class:^(polkit-mate-authentication-agent-1)$"
        "pin, class:^(polkit-mate-authentication-agent-1)$"
      ];

      general = {
        resize_on_border = true;
        border_size = 2;  
        gaps_out = 25;
	      gaps_in = 10;
        layout = "dwindle";  
      };

      decoration = {
        active_opacity = 1;
	      inactive_opacity = 0.9;
        rounding = 12;
        blur = {
          enabled = true;  
          size = 18;
          passes = 3;
        };
	shadow = {
	  enabled = true;
	  range = 20;
	};
      };

      cursor = {
        no_hardware_cursors = true;
        default_monitor = "HDMI-A-1"; 
      };
      
      input = {
        kb_layout = "us,ru, de";
        kb_options = "grp:alt_shift_toggle";
        follow_mouse = 1;
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
        "noborder, fullscreen:1"
        "opacity 0.95 0.90, class:^(kitty)$"
        "opacity 0.92 0.88, class:^(Code)$"
      ];
      
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        vfr = true;
        vrr = 0;
      };
    };
  };
}
