# GPU module for Huawei MateBook D (NBLK-WAX9X) — AMD Ryzen 5 3500U / Vega 8 iGPU.
# No discrete NVIDIA GPU is present in this laptop.
{ pkgs, ... }:
{
  # Use the open-source AMDGPU driver (correct for Picasso/Raven 2 iGPU).
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      libva # VA-API (video decode/encode on radeonsi, comes with Mesa)
      libva-utils # for `vainfo` debugging
    ];
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools # vulkaninfo / vkcube
    mesa-demos # glxinfo / eglinfo / glmark
  ];
}
