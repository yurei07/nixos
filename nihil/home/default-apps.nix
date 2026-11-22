# default-apps.nix by poligle

{ config, lib, pkgs, ... }:
let
	profile = "${config.home.profileDirectory}/bin";

	text =
	[
		"text/plain"
		"text/markdown"
		"text/x-markdown"
		"text/x-log"
		"text/x-nix"
		"text/x-python"
		"text/x-lua"
		"text/x-csrc"
		"text/x-chdr"
		"text/x-c++src"
		"text/x-c++hdr"
		"text/x-java"
		"text/rust"
		"text/x-go"
		"text/css"
		"text/javascript"
		"application/javascript"
		"application/toml"
		"application/yaml"
		"application/x-yaml"
		"text/x-shellscript"
		"application/x-shellscript"
		"text/x-patch"
		"text/x-diff"
	];
in
{
	home.packages = [ pkgs.xdg-utils ];

	xdg.desktopEntries.nihil-editor =
	{
		name = "Neovim";
		genericName = "Text editor";
		exec = "${profile}/kitty -e ${profile}/nvim %F";
		terminal = false;
		noDisplay = true;
		mimeType = text;
	};

	xdg.mimeApps =
	{
		enable = true;
		defaultApplications = lib.genAttrs text (_: "nihil-editor.desktop")
			// { "inode/directory" = "thunar.desktop"; };
	};
}
