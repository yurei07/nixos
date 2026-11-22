# Prizrak's machine: NIHIL, vendored in-tree at ./nihil, plus this machine's own.
{
	description = "Prizrak's NixOS machine running NIHIL";

	inputs =
	{
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

		home-manager =
		{
			url = "github:nix-community/home-manager/release-26.05";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		stylix =
		{
			url = "github:nix-community/stylix/release-26.05";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		zen-browser =
		{
			url = "github:0xc000022070/zen-browser-flake";
			inputs.nixpkgs.follows = "nixpkgs";
			inputs.home-manager.follows = "home-manager";
		};

		freesm-launcher.url = "github:FreesmTeam/FreesmLauncher";
	};

	outputs = inputs@{ self, nixpkgs, home-manager, stylix, zen-browser, freesm-launcher, ... }:
	let
		system = "x86_64-linux";
		host = ./hosts/Prizrak;
		settings = builtins.fromJSON (builtins.readFile (host + "/settings.json"));

		# NIHIL stamps its source into the system, as its own flake did.
		date = self.lastModifiedDate or "19700101000000";
		at = start: length: builtins.substring start length date;
		revision = "${self.shortRev or self.dirtyShortRev or "local"} (${at 0 4}-${at 4 2}-${at 6 2} ${at 8 2}:${at 10 2})";
	in
	{
		nixosConfigurations.${settings.host.name} = nixpkgs.lib.nixosSystem
		{
			inherit system;
			modules =
			[
				# NIHIL itself, vendored: the same as its flake's nixosModules.default.
				stylix.nixosModules.stylix
				home-manager.nixosModules.home-manager
				./nihil/modules
				{
					nihil = { inherit settings revision; home = [ (host + "/home.nix") ]; machineDir = "hosts/Prizrak"; };
					nixpkgs.config.allowUnfree = true;
				}
				{
					home-manager =
					{
						useGlobalPkgs = true;
						useUserPackages = true;
						backupFileExtension = "hm-backup";
						overwriteBackup = true;
						extraSpecialArgs = { inherit inputs; theme = import (host + "/themes/kanso-zen.nix"); machineInputs = { inherit freesm-launcher; }; };
						users.${settings.user.name}.imports = [ ./nihil/home.nix ] ++ [ (host + "/home.nix") ];
					};
				}

				(host + "/hardware-configuration.nix")
				(host + "/local.nix")
			];
		};
	};
}
