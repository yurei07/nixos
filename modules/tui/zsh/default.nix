{config, pkgs, lib, ...}:
let 
  base00 = (import ../../../materials/themes {}).base00;
  base01 = (import ../../../materials/themes {}).base01;
  base02 = (import ../../../materials/themes {}).base02;
  base03 = (import ../../../materials/themes {}).base03;
  base04 = (import ../../../materials/themes {}).base04;
  base05 = (import ../../../materials/themes {}).base05;
  base06 = (import ../../../materials/themes {}).base06;
  base07 = (import ../../../materials/themes {}).base07;
  base08 = (import ../../../materials/themes {}).base08;
  base09 = (import ../../../materials/themes {}).base09;
  base0A = (import ../../../materials/themes {}).base0A;
  base0B = (import ../../../materials/themes {}).base0B;
  base0C = (import ../../../materials/themes {}).base0C;
  base0D = (import ../../../materials/themes {}).base0D;
  base0E = (import ../../../materials/themes {}).base0E;
  base0F = (import ../../../materials/themes {}).base0F;
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

      PROMPT="%F{${base0D}}%n%f@%F{${base0C}}%m%f %F{${base0B}}%~%f %# "

      RPROMPT="[%F{${base0A}}%?%f]"

      setopt PROMPT_SUBST

      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${base04}"

      typeset -A ZSH_HIGHLIGHT_STYLES
      ZSH_HIGHLIGHT_STYLES[command]="fg=${base0B}"      
      ZSH_HIGHLIGHT_STYLES[alias]="fg=${base0D}"        
      ZSH_HIGHLIGHT_STYLES[builtin]="fg=${base0C}"      
      ZSH_HIGHLIGHT_STYLES[function]="fg=${base0A}"    
      ZSH_HIGHLIGHT_STYLES[path]="fg=${base05},bold"    
      ZSH_HIGHLIGHT_STYLES[default]="fg=${base05}"
      ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=${base08}" 
      ZSH_HIGHLIGHT_STYLES[is-alias]="fg=${base0D}"
      ZSH_HIGHLIGHT_STYLES[is-function]="fg=${base0A}"
      ZSH_HIGHLIGHT_STYLES[globbing]="fg=${base0E}"     
    '';
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "macos"];
      theme = "fishy";
    };

    shellAliases = {
      u = "cd /etc/nixos; sudo nixos-rebuild switch --flake .#nixos; nh os switch /etc/nixos; cd ";
      u-full = "cd /etc/nixos; sudo nix flake update; nh os switch /etc/nixos";

    };

    
    history.size = 10000;
  };
}
