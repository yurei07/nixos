# hypridle.nix by poligle

{ config, osConfig, pkgs, ... }:
let
	brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
	dpms = state: "${osConfig.programs.hyprland.package}/bin/hyprctl dispatch 'hl.dsp.dpms({ action = \"${state}\" })'";
in
{
	services.hypridle =
	{
		enable = true;

		settings =
		{
			general =
			{
				# In a scope of its own: a restart of hypridle (any update) would kill it with its
				# children and leave the session locked with nothing on it.
				lock_cmd = "pidof hyprlock || ${pkgs.systemd}/bin/systemd-run --user --scope --collect --quiet ${config.programs.hyprlock.package}/bin/hyprlock";
				before_sleep_cmd = "loginctl lock-session";
				after_sleep_cmd = dpms "on";
			};

			listener =
			[
				{
					timeout = 150;
					on-timeout = "${brightnessctl} -s set 10";
					on-resume = "${brightnessctl} -r";
				}
				{
					timeout = 240;
					on-timeout = "loginctl lock-session";
				}
				{
					timeout = 270;
					on-timeout = dpms "off";
					on-resume = dpms "on";
				}
				{
					timeout = 900;
					on-timeout = "systemctl suspend";
				}
			];
		};
	};
}
