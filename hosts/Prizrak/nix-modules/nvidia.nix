{
  pkgs,
  config,
  ...
}: 
{
  services.xserver.videoDrivers = ["nvidia"];  
  boot.kernelParams = [
    "nvidia-drm.modeset=1" # Enable mode setting for Wayland
    "nvidia.NVreg_EnableMSI=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];


  environment.variables = {
    LIBVA_DRIVER_NAME = "nvidia"; # Hardware video acceleration
    XDG_SESSION_TYPE = "wayland"; # Force Wayland
    GBM_BACKEND = "nvidia-drm"; # Graphics backend for Wayland
    __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # Use Nvidia driver for GLX
    WLR_NO_HARDWARE_CURSORS = "1"; # Fix for cursors on Wayland
    WLR_DRM_NO_ATOMIC = "1"; # Fix for some issues with Hyprland
  };

  # Configuration for proprietary packages
  nixpkgs.config = {
    nvidia.acceptLicense = true;
  };

  # Nvidia configuration
  hardware = {
    nvidia = {
      open = false; # Proprietary driver for better performance
      nvidiaSettings = true; # Nvidia settings utility
      modesetting.enable = true; # Required for Wayland
      forceFullCompositionPipeline = true; # Prevents screen tearing

    };

    graphics = {
      enable = true;
      package =  config.boot.kernelPackages.nvidiaPackages.beta;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        vaapiVdpau
        libvdpau-va-gl
        mesa
        egl-wayland
        vulkan-loader
        vulkan-validation-layers
        libva
      ];
    };
  };

  # Additional useful packages
  environment.systemPackages = with pkgs; [
    vulkan-tools
    glxinfo
    libva-utils # VA-API debugging tools
  ];
}
