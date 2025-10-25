{
  config,
  pkgs,
  lib,
  ...
}:
let
  colors = import ../../../materials/themes { };
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;
    initContent = ''
      autoload -U colors && colors

      PROMPT="%F{${colors.base0D}}%n%f@%F{${colors.base0C}}%m%f %F{${colors.base0B}}%~%f %# "

      RPROMPT="[%F{${colors.base0A}}%?%f]"

      setopt PROMPT_SUBST

      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${colors.base04}"

      typeset -A ZSH_HIGHLIGHT_STYLES
      ZSH_HIGHLIGHT_STYLES[command]="fg=${colors.base0B}"      
      ZSH_HIGHLIGHT_STYLES[alias]="fg=${colors.base0D}"        
      ZSH_HIGHLIGHT_STYLES[builtin]="fg=${colors.base0C}"      
      ZSH_HIGHLIGHT_STYLES[function]="fg=${colors.base0A}"    
      ZSH_HIGHLIGHT_STYLES[path]="fg=${colors.base05},bold"    
      ZSH_HIGHLIGHT_STYLES[default]="fg=${colors.base05}"
      ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=${colors.base08}" 
      ZSH_HIGHLIGHT_STYLES[is-alias]="fg=${colors.base0D}"
      ZSH_HIGHLIGHT_STYLES[is-function]="fg=${colors.base0A}"
      ZSH_HIGHLIGHT_STYLES[globbing]="fg=${colors.base0E}"     
    '';
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "macos"
      ];
      theme = "fishy";
    };

    shellAliases = {
      u = "nh os switch /etc/nixos";
      u-full = "(cd /etc/nixos; sudo nix flake update; nh os switch /etc/nixos)";

    };

    history.size = 10000;
  };
}
