{pkgs, inputs, ...}:
{
  services.xserver = {
    enable = true;
    displayManager.lightdm = {
      enable = true;
      greeter.enable = false;
    };
  };

  services.displayManager = {
    sessionData.autologinSession = "hyprland";
    sessionPackages = [ inputs.hyprland.packages.${pkgs.system}.default ];
    defaultSession = "hyprland";
    autoLogin = {
      user = "laptop_Prizrak";
      enable = true;
    };
  };
}
