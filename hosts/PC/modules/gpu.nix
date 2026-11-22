# The PC's GPU: NVIDIA RTX 3070 Ti, proprietary driver (best for games and video).
# The open NVK was fine for the desktop, but slower for anything 3D.
{ config, ... }:
{
	services.xserver.videoDrivers = [ "nvidia" ];

	hardware.nvidia =
	{
		# Wayland: modesetting and the open kernel module (Turing and newer).
		modesetting.enable = true;
		open = true;
		nvidiaSettings = true;
		package = config.boot.kernelPackages.nvidiaPackages.stable;
		powerManagement.enable = true;
		nvidiaPersistenced = true;
	};

	hardware.graphics.enable = true;
}
