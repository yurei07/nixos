{ pkgs, config, lib, inputs, ... }:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  color = import ../../../materials/themes {};
in {
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.text;


    customColorScheme = {
      accent = color.base0D;
      accent-active = color.base0D;
      border-active = color.base0D;
      tab-active = color.base0D;
      player = color.base00;
      sidebar = color.base00;
      highlight = color.base0D;
    };


    enabledExtensions = with spicePkgs.extensions; [
      playlistIcons
      lastfm
      historyShortcut
      hidePodcasts
      adblock
      fullAppDisplay
      keyboardShortcut
    ];
  };
}
