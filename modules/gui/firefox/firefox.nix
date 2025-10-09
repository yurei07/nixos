{ inputs, config, lib, pkgs, ... }:
{
  imports = [
    inputs.textfox.homeManagerModules.default
  ];

  textfox = {
    enable = true;
    profile = "/home/Prizrak/.zen/w9wtn217.Default Profile";
    config = {
        # Optional config
    };
  };

  programs.firefox = {
    enable = true;
  };
}
