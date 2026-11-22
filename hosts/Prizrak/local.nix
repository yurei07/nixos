# Everything system-level that is this machine's own, beyond NIHIL.
{ config, lib, pkgs, ... }:
{
	imports = [
		./modules/arduino.nix
		./modules/fonts.nix
		./modules/gpu.nix
		./modules/laptop.nix
		./modules/obs.nix
	];

	# keyboard: switch us/ru with Alt+Shift
	services.xserver.xkb.options = "grp:alt_shift_toggle";

	# the state this system has always had; never change it on an installed machine
	system.stateVersion = "25.05";

	# services this machine uses
	virtualisation.docker.enable = true;
	services.zerotierone.enable = true;
	services.tailscale.enable = true;
	services.flatpak.enable = true;
	services.usbmuxd.enable = true;
	services.gvfs.enable = true;
	services.gnome.gnome-browser-connector.enable = true;
	services.upower.enable = true; # battery info for desktop widgets

	services.hardware.openrgb = {
		enable = true;
		package = pkgs.openrgb-with-all-plugins;
		motherboard = "amd";
		server.port = 6742;
	};

	# groups beyond NIHIL's defaults (wheel, networkmanager, video, nihil-leds)
	users.users.${config.nihil.user.name}.extraGroups = [ "docker" "adbusers" ];

	# patool tests fail in the Nix build env; needed by bottles
	nixpkgs.overlays = [
		(final: prev: {
			pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
				(pyFinal: pyPrev: {
					patool = pyPrev.patool.overridePythonAttrs (old: {
						doCheck = false;
					});
				})
			];
		})
	];
}
