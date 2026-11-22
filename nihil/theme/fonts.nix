# fonts.nix by poligle

# Doto, Space Grotesk and Space Mono, from google/fonts at the revision nixpkgs' google-fonts
# uses. That package isn't in the binary cache, so building it fetched the whole repository,
# gigabytes, for 1 MB of fonts: these are the six files, and nothing else.
{ pkgs }:
let
    rev = "5174b3333331c966c38f4355d50b03ca1c1df2f9";
    font = name: path: hash:
    {
        inherit name;
        file = pkgs.fetchurl
        {
            name = builtins.replaceStrings [ "[" "]" "," ] [ "-" "" "-" ] name;
            url = "https://raw.githubusercontent.com/google/fonts/${rev}/${path}";
            inherit hash;
        };
    };
    files =
    [
        (font "Doto[ROND,wght].ttf" "ofl/doto/Doto%5BROND,wght%5D.ttf" "sha256-b0/n03hTuR3zaY2qhM3i2+HJaV2IyYbmUQE0kQM31CY=")
        (font "SpaceGrotesk[wght].ttf" "ofl/spacegrotesk/SpaceGrotesk%5Bwght%5D.ttf" "sha256-rK1t4fyTQ29cDx9BN3Ue8E8a6jBj5wNlNZcP/PvXn3I=")
        (font "SpaceMono-Regular.ttf" "ofl/spacemono/SpaceMono-Regular.ttf" "sha256-lYN+GCuu6tqDNo93SNsoNX8KG3XGuE/3Blte35M8jhg=")
        (font "SpaceMono-Bold.ttf" "ofl/spacemono/SpaceMono-Bold.ttf" "sha256-QF5z1Br7flkG784gajJq9clW844lXzVCHCYOhh5ZnFk=")
        (font "SpaceMono-Italic.ttf" "ofl/spacemono/SpaceMono-Italic.ttf" "sha256-7KJkyGkKkf6DfRmmut8tiJYWEMTIqvyxllJhkqnyWMU=")
        (font "SpaceMono-BoldItalic.ttf" "ofl/spacemono/SpaceMono-BoldItalic.ttf" "sha256-zcyV7d7jEoealyhJTllfWRyxWfPydtebxYZz3sflcTg=")
    ];
in
pkgs.runCommand "nihil-fonts" { } (pkgs.lib.concatMapStrings (font: ''
    install -Dm444 ${font.file} "$out/share/fonts/truetype/${font.name}"
'') files)
