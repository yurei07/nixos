{pkgs, inputs, ...}:
{
  imports = [ inputs.zen-browser.packages.${system}.default ];
  
  programs.zen-browser = {
    enable = true;
    
    config = {
      useQuickCss = true;
      themeLinks = [
        "https://refact0r.github.io/system24/build/system24.css"
      ];
    };
  };
}
