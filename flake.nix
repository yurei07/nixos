# Prizrak's machine running NIHIL: https://github.com/poligle/Nihil-Shell
{
	description = "Prizrak's NixOS machine running NIHIL";

	inputs.nihil.url = "path:/home/Prizrak/Nihil-Shell";
	inputs.freesm-launcher.url = "github:FreesmTeam/FreesmLauncher";
	inputs.theme.url = "path:./themes/chiaroscuro-stub";
	# share NIHIL's nixpkgs with the local theme stub
	inputs.theme.inputs.nixpkgs.follows = "nihil/nixpkgs";

	outputs = { nihil, freesm-launcher, theme, ... }:
	let
		settings = builtins.fromJSON (builtins.readFile ./settings.json);
	in
	{
		nixosConfigurations.${settings.host.name} = nihil.lib.mkSystem
		{
			inherit settings;
			modules = [
				./hardware-configuration.nix
				./local.nix
				# extra args for home.nix: this machine's own flake inputs
				{
					home-manager.extraSpecialArgs = {
						theme = theme.themes.kanso-zen;
						machineInputs = { inherit freesm-launcher; };
					};
				}
			];
			home = [ ./home.nix ];
		};
	};
}
