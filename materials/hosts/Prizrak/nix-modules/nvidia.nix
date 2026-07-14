{ config, pkgs, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
        libva
      ];
    };

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = false;

      package = config.boot.kernelPackages.nvidiaPackages.beta;    
    };
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
    mesa-demos
    libva-utils # VA-API debugging tools
  ];
}
