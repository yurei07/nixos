# cli.nix by poligle

{ pkgs, ... }:
{
    programs.gh =
    {
        enable = true;
        settings.git_protocol = "ssh";
    };

    programs.lazygit.enable = true;
    programs.bat.enable = true;

    programs.fzf =
    {
        enable = true;
        enableZshIntegration = true;
    };

    programs.tealdeer =
    {
        enable = true;
        settings.updates.auto_update = true;
    };

    home.packages = with pkgs;
    [
        ripgrep
        fd
        jq
        dust
    ];
}
