{config, pkgs, ...}:
{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [ 
      ubuntu_font_family
      liberation_ttf
      material-symbols
      nerd-fonts.jetbrains-mono
      vazir-fonts
  ];

  fontconfig = {
    defaultFonts = {
      serif = [  "Liberation Serif" "Vazirmatn" ];
      sansSerif = [ "Ubuntu" "Vazirmatn" ];
      monospace = [ "Ubuntu Mono" ];
    };
   };
  };  
}
