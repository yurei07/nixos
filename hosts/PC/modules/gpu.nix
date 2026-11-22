# The PC's GPU: NVIDIA RTX 3070 Ti, proprietary driver (best for games and video).
# The open NVK was fine for the desktop, but slower for anything 3D.
#
# The kernel stays on 6.18: NVIDIA 595.x doesn't build against 7.3 yet (strncpy was
# removed there), and NixOS ships this driver for 6.18 without a problem.
{ config, pkgs, ... }:
{
	boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_18;

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
