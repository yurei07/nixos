# viewers.nix by poligle

{ config, osConfig, pkgs, lib, ... }:
let
	p = osConfig.nihil.tokens.palette;
	f = osConfig.nihil.tokens.fonts;

	bare = package: pkgs.symlinkJoin
	{
		name = "${package.name}-bare";
		paths = [ package ];
		postBuild = "rm -rf $out/share/applications";
	};

	imv = bare pkgs.imv;
	mpv = bare pkgs.mpv;
	zathura = bare pkgs.zathura;

	pictures =
	[
		"image/png"
		"image/jpeg"
		"image/gif"
		"image/webp"
		"image/avif"
		"image/heic"
		"image/heif"
		"image/jxl"
		"image/bmp"
		"image/tiff"
		"image/svg+xml"
	];

	videos =
	[
		"video/mp4"
		"video/webm"
		"video/x-matroska"
		"video/quicktime"
		"video/x-msvideo"
		"video/mpeg"
		"video/ogg"
		"video/3gpp"
		"video/mp2t"
		"video/x-flv"
		"video/x-ms-wmv"
		"audio/mpeg"
		"audio/flac"
		"audio/x-flac"
		"audio/ogg"
		"audio/x-vorbis+ogg"
		"audio/opus"
		"audio/x-opus+ogg"
		"audio/wav"
		"audio/x-wav"
		"audio/mp4"
		"audio/x-m4a"
		"audio/aac"
	];

	documents =
	[
		"application/pdf"
		"application/epub+zip"
		"application/oxps"
		"application/vnd.ms-xpsdocument"
		"application/postscript"
		"image/vnd.djvu"
		"application/vnd.comicbook+zip"
		"application/x-cbz"
	];

	viewer = pkgs.writeShellScript "nihil-viewer" ''
		if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
			exec ${imv}/bin/imv -- "$@"
		fi
		shopt -s nullglob
		file="$(${pkgs.coreutils}/bin/realpath -s -- "$1")"
		folder="$(${pkgs.coreutils}/bin/dirname -- "$file")"
		all=()
		for each in "$folder"/*; do
			case "''${each,,}" in
				*.png | *.jpg | *.jpeg | *.jfif | *.gif | *.webp | *.avif | *.heic | *.heif | *.jxl | *.bmp | *.tif | *.tiff | *.svg | *.qoi)
					all+=( "$each" ) ;;
			esac
		done
		for each in "''${all[@]}"; do
			if [ "$each" = "$file" ]; then
				exec ${imv}/bin/imv -n "$file" -- "''${all[@]}"
			fi
		done
		exec ${imv}/bin/imv -- "$file"
	'';
in
{
	home.packages = [ imv mpv zathura ];

	xdg.configFile."imv/config".text = lib.generators.toINI { }
	{
		options =
		{
			background = p.void;
			overlay_font = "${f.mono}:11";
			overlay_text_color = p.dim;
			overlay_background_color = p.void;
			overlay_background_alpha = "cc";
			overlay_position_bottom = true;
		};
	};

	xdg.configFile."mpv/mpv.conf".text = lib.generators.toKeyValue { }
	{
		osd-font = "\"${f.sans}\"";
		osd-color = "\"#${p.ink}\"";
		keep-open = "yes";
		hwdec = "auto-safe";
	};

	xdg.configFile."zathura/zathurarc".text = lib.concatStrings (lib.mapAttrsToList (name: value: "set ${name} ${value}\n")
	{
		font = "\"${f.mono} 10\"";
		default-bg = "\"#${p.void}\"";
		default-fg = "\"#${p.ink}\"";
		statusbar-bg = "\"#${p.void}\"";
		statusbar-fg = "\"#${p.dim}\"";
		inputbar-bg = "\"#${p.void}\"";
		inputbar-fg = "\"#${p.ink}\"";
		notification-bg = "\"#${p.surface}\"";
		notification-fg = "\"#${p.ink}\"";
		notification-warning-bg = "\"#${p.surface}\"";
		notification-warning-fg = "\"#${p.ink}\"";
		notification-error-bg = "\"#${p.signal}\"";
		notification-error-fg = "\"#${p.ink}\"";
		completion-bg = "\"#${p.surface}\"";
		completion-fg = "\"#${p.dim}\"";
		completion-group-bg = "\"#${p.void}\"";
		completion-group-fg = "\"#${p.muted}\"";
		completion-highlight-bg = "\"#${p.raised}\"";
		completion-highlight-fg = "\"#${p.ink}\"";
		index-bg = "\"#${p.void}\"";
		index-fg = "\"#${p.dim}\"";
		index-active-bg = "\"#${p.raised}\"";
		index-active-fg = "\"#${p.ink}\"";
		highlight-color = "\"rgba(242, 242, 242, 0.25)\"";
		highlight-active-color = "\"rgba(242, 242, 242, 0.5)\"";
		render-loading-bg = "\"#${p.void}\"";
		render-loading-fg = "\"#${p.muted}\"";
		recolor-lightcolor = "\"#${p.void}\"";
		recolor-darkcolor = "\"#${p.ink}\"";
		selection-clipboard = "clipboard";
		window-title-basename = "true";
	});

	xdg.desktopEntries =
	{
		nihil-viewer =
		{
			name = "imv";
			genericName = "Image viewer";
			exec = "${viewer} %F";
			terminal = false;
			noDisplay = true;
			mimeType = pictures;
		};

		nihil-player =
		{
			name = "mpv";
			genericName = "Video player";
			exec = "${mpv}/bin/mpv --player-operation-mode=pseudo-gui -- %U";
			terminal = false;
			noDisplay = true;
			mimeType = videos;
		};

		nihil-reader =
		{
			name = "Zathura";
			genericName = "Document viewer";
			exec = "${zathura}/bin/zathura %F";
			terminal = false;
			noDisplay = true;
			mimeType = documents;
		};
	};

	xdg.mimeApps.defaultApplications =
		lib.genAttrs pictures (_: "nihil-viewer.desktop")
		// lib.genAttrs videos (_: "nihil-player.desktop")
		// lib.genAttrs documents (_: "nihil-reader.desktop");
}
