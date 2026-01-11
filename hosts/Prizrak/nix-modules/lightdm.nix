{
  pkgs,
  inputs,
  username,
  ...
}:
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
    sessionPackages = [ inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    defaultSession = "hyprland";
    autoLogin = {
      user = "${username}";
      enable = true;
    };
  };
}
