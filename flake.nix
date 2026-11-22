# Prizrak's machines: NIHIL, vendored in-tree at ./nihil, plus this repo's own.
# Every folder in hosts/ is a machine: hosts/<name>/settings.json names it
# (host.name), and rebuilds pick it with `nihil rebuild` or `#<name>`.

{
	description = "Prizrak's NixOS machines running NIHIL";

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

		# NIHIL stamps its source into the system, as its own flake did.
		date = self.lastModifiedDate or "19700101000000";
		at = start: length: builtins.substring start length date;
		revision = "${self.rev or self.dirtyRev or "local"} (${at 0 4}-${at 4 2}-${at 6 2} ${at 8 2}:${at 10 2})";

		# A machine: its folder, its settings.json, its own nixosConfiguration.
		mkHost = host:
		let
			settings = builtins.fromJSON (builtins.readFile (host + "/settings.json"));
		in
		{
			name = settings.host.name;
			value = nixpkgs.lib.nixosSystem
			{
				inherit system;
				modules =
				[
					# NIHIL itself, vendored: the same as its flake's nixosModules.default.
					stylix.nixosModules.stylix
					home-manager.nixosModules.home-manager
					./nihil/modules
					{
						nihil = { inherit settings revision; home = [ (host + "/home.nix") ]; machineDir = "hosts/${baseNameOf host}"; };
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

		# The machines: every hosts/<name>/ with a settings.json in it.
		machines = builtins.filter (host: builtins.pathExists (host + "/settings.json"))
			(nixpkgs.lib.map (name: ./hosts + "/${name}") (builtins.attrNames (builtins.readDir ./hosts)));
	in
	{
		nixosConfigurations = builtins.listToAttrs (map mkHost machines);
	};
}
