# wallpapers.nix by poligle

{ pkgs, lib, outputs, dirs }:
let
	python = pkgs.python3.withPackages (ps: [ ps.numpy ps.pillow ]);

	extensions = [ "png" "jpg" "jpeg" "gif" "webp" ];
	parts = file: builtins.match "(.+)\\.([^.]+)" file;
	extension = file: lib.toLower (lib.last (parts file));
	isImage = file: type: type == "regular" && !lib.hasPrefix "." file && parts file != null
		&& lib.elem (extension file) extensions;

	accents =
	{
		"á" = "a"; "à" = "a"; "â" = "a"; "ä" = "a"; "ã" = "a"; "å" = "a";
		"é" = "e"; "è" = "e"; "ê" = "e"; "ë" = "e";
		"í" = "i"; "ì" = "i"; "î" = "i"; "ï" = "i";
		"ó" = "o"; "ò" = "o"; "ô" = "o"; "ö" = "o"; "õ" = "o";
		"ú" = "u"; "ù" = "u"; "û" = "u"; "ü" = "u";
		"ñ" = "n"; "ç" = "c"; "ý" = "y"; "ÿ" = "y";
		"Á" = "A"; "À" = "A"; "Â" = "A"; "Ä" = "A"; "Ã" = "A"; "Å" = "A";
		"É" = "E"; "È" = "E"; "Ê" = "E"; "Ë" = "E";
		"Í" = "I"; "Ì" = "I"; "Î" = "I"; "Ï" = "I";
		"Ó" = "O"; "Ò" = "O"; "Ô" = "O"; "Ö" = "O"; "Õ" = "O";
		"Ú" = "U"; "Ù" = "U"; "Û" = "U"; "Ü" = "U";
		"Ñ" = "N"; "Ç" = "C"; "Ý" = "Y";
	};
	plain = builtins.replaceStrings (builtins.attrNames accents) (builtins.attrValues accents);
	nameOf = file:
		let
			name = lib.concatStringsSep "-" (builtins.filter (part: builtins.isString part && part != "")
				(builtins.split "[^A-Za-z0-9_]+" (plain (lib.head (parts file)))));
		in
		if name != "" then name else "wallpaper";

	pictures = lib.foldl' (found: dir: found // lib.mapAttrs' (file: _: lib.nameValuePair (nameOf file) (builtins.path
	{
		path = dir + "/${file}";
		name = "${nameOf file}.${extension file}";
	}))
		(lib.filterAttrs isImage (builtins.readDir dir))) { } dirs;

	renderer = builtins.path { path = ./dotmatrix.py; name = "nihil-dotmatrix.py"; };

	render = name: picture: output: size: pkgs.runCommand "nihil-wallpaper-${name}-${output}"
		{ nativeBuildInputs = [ python ]; }
		''
			echo "nihil: rendering ${name} for ${output}"
			python3 ${renderer} ${picture} $out --output ${output}:${toString size.width}x${toString size.height}:${toString size.pitch}
		'';

	link = name: picture: ''
		mkdir -p $out/${name}
		${lib.concatStrings (lib.mapAttrsToList (output: size: ''
			ln -s ${render name picture output size}/* $out/${name}/
		'') outputs)}
	'';
in
pkgs.runCommand "nihil-wallpapers"
{
	passthru.names = builtins.attrNames pictures;
}
''
	mkdir -p $out
	${lib.concatStrings (lib.mapAttrsToList link pictures)}
''
