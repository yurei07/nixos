{ pkgs ? import <nixpkgs> {} }:
let
  colors = import ../../../materials/themes {};
in
with pkgs;
stdenv.mkDerivation rec {
  pname = "Goth_theme";
  version = "2025-04-17";

  src = pkgs.fetchFromGitHub {
    owner = "vinceliuice";
    repo = "Fluent-gtk-theme";
    rev = "6a3110ac0e5a24174cf506769e5802675e85266f";
    sha256 = "sha256-kRCQWUNz+iHOEB/e62NxZtbG/xRMUPLeW8lOkn6zwWM=";
  };

  nativeBuildInputs = with pkgs; [ sassc python3 glib bash ];
  buildInputs = [ pkgs.gnome-themes-extra ];

  postPatch = ''
    substituteInPlace ./src/_sass/_color-palette.scss \
      --replace "$blue-600:    #1A73E8;" "$blue-600:    ${colors.base0D};" \
      --replace "$red-600:     #D93025;" "$red-600:     ${colors.base08};" \
      --replace "$green-500:   #0F9D58;" "$green-500:   ${colors.base0B};" \
      --replace "$orange-700:  #FF7043;" "$orange-700:  ${colors.base09};" \
      --replace "$yellow-700:  #F4B400;" "$yellow-700:  ${colors.base0A};" \
      --replace "$purple-400:  #8751A6;" "$purple-400:  ${colors.base0E};" \
      --replace "$pink-400:    #d11f7c;" "$pink-400:    ${colors.base0F};" \
      --replace "$teal-500:    #00A78F;" "$teal-500:    ${colors.base0C};" \
      --replace "$grey-700:    #363636;" "$grey-700:    ${colors.base03};"

    substituteInPlace ./src/_sass/_colors.scss \
      --replace "$primary: theme(color);" "$primary: ${colors.base0D};" \
      --replace "$drop_target_color: #FF7043;" "$drop_target_color: ${colors.base09};" \
      --replace "if(\$variant == 'light', #F2F2F2, #333333)" "if(\$variant == 'light', #F2F2F2, ${colors.base00})" \
      --replace "if(\$variant == 'light', #FFFFFF, #3C3C3C)" "if(\$variant == 'light', #FFFFFF, ${colors.base01})" \
      --replace "if(\$variant == 'light', #FFFFFF, #2B2B2B)" "if(\$variant == 'light', #FFFFFF, ${colors.base02})" \
      --replace "if(\$variant == 'light', #FAFAFA, #303030)" "if(\$variant == 'light', #FAFAFA, ${colors.base03})" \
      --replace "rgba(#363636, 0.9)" "rgba(${colors.base03}, 0.9)" \
      --replace "if(\$topbar == 'light', rgba(#F7F7F7, 0.8), rgba(#1F1F1F, 0.8))" "if(\$topbar == 'light', rgba(#F7F7F7, 0.8), rgba(${colors.base00}, 0.8))" \
      --replace "if(\$topbar == 'light', #F7F7F7, #1F1F1F)" "if(\$topbar == 'light', #F7F7F7, ${colors.base00})" \
      --replace "if(\$variant == 'light', \$purple-500, \$purple-200)" "if(\$variant == 'light', \$purple-500, ${colors.base0E})"
  '';

  installPhase = ''
    mkdir -p $out/share/themes
    bash ./install.sh --dest $out/share/themes --color dark --theme grey --name Goth_theme --tweaks solid
  '';

  meta = with pkgs.lib; {
    description = "Fluent GTK theme with Gothic color scheme";
    homepage = "https://github.com/vinceliuice/Fluent-gtk-theme";
    license = licenses.gpl3Plus;
    platforms = platforms.all;
  };
}
