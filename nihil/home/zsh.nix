# zsh.nix by poligle

{ config, osConfig, pkgs, ... }:
let
    p = osConfig.nihil.tokens.palette;
in
{
    programs.zsh = 
    {
        enable = true;
        enableCompletion = true;

        oh-my-zsh = 
        {
            enable = true;
            theme = ""; 
            plugins = 
            [
                "git"
                "sudo"
            ];
        };

        # Home Manager's own: the plugin list looks for a .plugin.zsh, which syntax highlighting
        # doesn't have, and it never loaded.
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        shellAliases = 
        {
            trash = "trash-put";
            ".." = "cd ..";
            "..." = "cd ../..";
            ll = "ls -lah";
            la = "ls -A";

            nrebuild = "nihil rebuild";
            nupdate = "nihil update";
            ngc = "nihil generations clean ${toString osConfig.nihil.generations.days}";
            
            gs = "git status";
            ga = "git add .";
            gc = "git commit -m";
            gp = "git push";
            gl = "git log --oneline -10";
            gd = "git diff";
        };
    };

    programs.starship =
    {
        enable = true;
        enableZshIntegration = true;
        settings =
        {
            add_newline = true;
            format = "$directory$git_branch$git_status$nix_shell$cmd_duration$line_break$character";

            character =
            {
                success_symbol = "[›](bold #${p.ink})";
                error_symbol = "[›](bold #${p.signal})";
            };
            directory =
            {
                style = "bold #${p.ink}";
                truncation_length = 3;
                truncate_to_repo = true;
                format = "[$path]($style)[$read_only]($read_only_style) ";
            };
            git_branch =
            {
                style = "#${p.dim}";
                symbol = "";
                format = "[$branch]($style) ";
            };
            git_status =
            {
                style = "#${p.muted}";
                format = "([$all_status$ahead_behind]($style) )";
            };
            nix_shell =
            {
                style = "#${p.dim}";
                format = "[nix $state]($style) ";
            };
            cmd_duration =
            {
                style = "#${p.muted}";
                min_time = 2000;
                format = "[$duration]($style) ";
            };
        };
    };
}
