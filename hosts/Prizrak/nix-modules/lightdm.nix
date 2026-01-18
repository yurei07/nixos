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
    sessionData.autologinSession = "niri";
    sessionPackages = [ inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    defaultSession = "niri";
    autoLogin = {
      user = "${username}";
      enable = true;
    };
  };
}
