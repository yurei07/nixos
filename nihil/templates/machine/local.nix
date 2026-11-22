{ config, lib, pkgs, ... }:
{
	system.stateVersion = "26.05";

	nihil.extraWallpapers = lib.optional (builtins.pathExists ./wallpapers) ./wallpapers;
}
