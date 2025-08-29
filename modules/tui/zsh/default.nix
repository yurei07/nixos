{config, pkgs, lib, ...}:
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
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;
 
    initContent = ''
      autoload -U colors && colors
      PROMPT="%F{${mauve}}%n%f@%F{${blue}}%m%f %F{${yellow}}%~%f %# "
      RPROMPT="[%F{${peach}}%?%f]"

      setopt PROMPT_SUBST

      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${overlay0}"

      typeset -A ZSH_HIGHLIGHT_STYLES
      ZSH_HIGHLIGHT_STYLES[command]="fg=${green}"
      ZSH_HIGHLIGHT_STYLES[alias]="fg=${blue}"
      ZSH_HIGHLIGHT_STYLES[builtin]="fg=${teal}"
      ZSH_HIGHLIGHT_STYLES[function]="fg=${peach}"
      ZSH_HIGHLIGHT_STYLES[path]="fg=${text},underline"
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
