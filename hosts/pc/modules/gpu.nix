# GPU setup for the target machine. Overwritten by scripts/nixinstall with the
# vendor chosen during install (AMD / Intel / NVIDIA).
{ pkgs, ... }:
{
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
    mesa-demos
  ];
}
