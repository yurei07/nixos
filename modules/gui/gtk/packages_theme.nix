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
        --replace "#1A73E8" "${colors.base0D}" \
        --replace "#D93025" "${colors.base08}" \
        --replace "#0F9D58" "${colors.base0B}" \
        --replace "#FF7043" "${colors.base09}" \
        --replace "#F4B400" "${colors.base0A}" \
        --replace "#8751A6" "${colors.base0E}" \
        --replace "#d11f7c" "${colors.base0F}" \
        --replace "#00A78F" "${colors.base0C}" \
        --replace "#363636" "${colors.base03}"

      substituteInPlace ./src/_sass/_colors.scss \
        --replace "#1A73E8" "${colors.base0D}" \
        --replace "#D93025" "${colors.base08}" \
        --replace "#0F9D58" "${colors.base0B}" \
        --replace "#FF7043" "${colors.base09}" \
        --replace "#F4B400" "${colors.base0A}" \
        --replace "#8751A6" "${colors.base0E}" \
        --replace "#d11f7c" "${colors.base0F}" \
        --replace "#00A78F" "${colors.base0C}" \
        --replace "#363636" "${colors.base03}" \
        --replace "#333333" "${colors.base00}" \
        --replace "#3C3C3C" "${colors.base01}" \
        --replace "#2B2B2B" "${colors.base00}" \
        --replace "#303030" "${colors.base00}" \
        --replace "#1F1F1F" "${colors.base00}" \
        --replace "#202020" "${colors.base00}" \
        --replace "#2C2C2C" "${colors.base01}" \
        --replace "#3281EA" "${colors.base0D}" \
        --replace "#F28B82" "${colors.base08}" \
        --replace "#81C995" "${colors.base0B}" \
        --replace "#FFB74D" "${colors.base09}" \
        --replace "#FDD633" "${colors.base0A}" \
        --replace "#BA68C8" "${colors.base0E}" \
        --replace "#F06292" "${colors.base0F}" \
        --replace "#26A69A" "${colors.base0C}" \
        --replace "#616161" "${colors.base03}"

      substituteInPlace ./src/_sass/_colors.scss \
        --replace "#F2F2F2" "${colors.base06}" \
        --replace "#FFFFFF" "${colors.base07}" \
        --replace "#FAFAFA" "${colors.base07}" \
        --replace "#F7F7F7" "${colors.base07}" \
        --replace "#E53935" "${colors.base08}" \
        --replace "#43A047" "${colors.base0B}" \
        --replace "#FB8C00" "${colors.base09}" \
        --replace "#FFD600" "${colors.base0A}" \
        --replace "#7B1FA2" "${colors.base0E}" \
        --replace "#E91E63" "${colors.base0F}" \
        --replace "#00897B" "${colors.base0C}" \
        --replace "#757575" "${colors.base04}"

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
