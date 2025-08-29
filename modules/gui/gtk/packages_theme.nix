{pkgs ? import <nixpkgs> {} }:
let 
  base = (import ../../../materials/themes {}).base;
  mantle = (import ../../../materials/themes {}).surface;
  crust = (import ../../../materials/themes {}).background;
  text = (import ../../../materials/themes {}).foreground;
  subtext = (import ../../../materials/themes {}).foreground-secondary;
  mauve = (import ../../../materials/themes {}).mauve;
  blue = (import ../../../materials/themes {}).blue;
  teal = (import ../../../materials/themes {}).teal;
  red = (import ../../../materials/themes {}).red;
  yellow = (import ../../../materials/themes {}).yellow;
  green = (import ../../../materials/themes {}).green; 
  peach = (import ../../../materials/themes {}).peach;
  overlay0 = (import ../../../materials/themes {}).selection;
  surface2 = (import ../../../materials/themes {}).surface;

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

#  postPatch = ''
#    substituteInPlace ./src/gtk-3.0/sass/_colors.scss \
#      --replace "#333333" "${colors.background}" \
#      --replace "#3C3C3C" "${colors.surface}" \
#      --replace "#2B2B2B" "${colors.base}" \
#      --replace "#303030" "${colors.base-alt}" \
#      --replace "#202020" "${colors.background}" \
#      --replace "#2C2C2C" "${colors.surface}" \
#      --replace "#1F1F1F" "${colors.background}" \
#      --replace "#81C995" "${colors.success}" \
#      --replace "#F28B82" "${colors.error}" \
#      --replace "#FDD633" "${colors.warning}" \
#      --replace "#3281EA" "${colors.primary}"
#  '';

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
