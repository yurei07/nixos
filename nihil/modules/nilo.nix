# nilo.nix by poligle

{ config, lib, pkgs, ... }:
let
    cfg = config.nihil.nilo;

    packages =
    {
        cpu = pkgs.ollama-cpu;
        vulkan = pkgs.ollama-vulkan;
        rocm = pkgs.ollama-rocm;
        cuda = pkgs.ollama-cuda;
    };

    modelType = lib.types.submodule
    {
        options =
        {
            tag = lib.mkOption
            {
                type = lib.types.str;
                example = "qwen3.5:9b";
                description = "Model name on ollama.com/library.";
            };
            label = lib.mkOption
            {
                type = lib.types.str;
                description = "Name shown in the shell.";
            };
            size = lib.mkOption
            {
                type = lib.types.number;
                description = "Download size in GB.";
            };
            ram = lib.mkOption
            {
                type = lib.types.number;
                description = ''
                    Memory it takes once loaded, in GB, roughly. The shell recommends
                    the largest model that fits in 45 % of the RAM.
                '';
            };
        };
    };
in
{
    options.nihil.nilo =
    {
        enable = lib.mkEnableOption "Nilo, the shell's assistant, with a local model on Ollama";

        acceleration = lib.mkOption
        {
            type = lib.types.enum [ "cpu" "vulkan" "rocm" "cuda" ];
            default = "cpu";
            example = "vulkan";
            description = ''
                What runs the model: the CPU, or the GPU through Vulkan (AMD, Intel,
                NVIDIA), ROCm (AMD) or CUDA (NVIDIA).
            '';
        };

        integratedGpu = lib.mkOption
        {
            type = lib.types.bool;
            default = false;
            description = ''
                Let Ollama use an integrated GPU, like the Radeon of a Ryzen laptop
                with `acceleration = "vulkan"`. Ollama leaves them out unless told
                (`OLLAMA_IGPU_ENABLE`), since a weak one can be slower than the CPU.
                Such a GPU works in a window of the RAM (its GTT, about half of
                it), which the screen needs too: a model bigger than that window
                doesn't fit there.
            '';
        };

        models = lib.mkOption
        {
            type = lib.types.listOf modelType;
            default =
            [
                { tag = "qwen3.5:0.8b"; label = "Qwen 3.5 0.8B"; size = 1.3; ram = 2; }
                { tag = "qwen3.5:2b"; label = "Qwen 3.5 2B"; size = 2.7; ram = 3.5; }
                { tag = "qwen3.5:4b"; label = "Qwen 3.5 4B"; size = 3.4; ram = 5; }
                { tag = "qwen3.5:9b"; label = "Qwen 3.5 9B"; size = 6.6; ram = 8.5; }
                { tag = "qwen3.5:35b-a3b"; label = "Qwen 3.5 35B-A3B"; size = 22; ram = 25; }
            ];
            description = ''
                Models offered in Nilo's settings. Any model on ollama.com/library
                that supports tools works; others installed with `ollama pull` show
                up too.
            '';
        };

        loadedModels = lib.mkOption
        {
            type = lib.types.ints.between 1 4;
            default = 1;
            example = 2;
            description = ''
                Models Ollama keeps in memory at once. With 2, Nilo's automatic
                choice (a small model for simple questions) switches between the
                small one and the chosen one without loading them again, at the
                cost of the memory of both.
            '';
        };

        contextLength = lib.mkOption
        {
            type = lib.types.ints.between 2048 262144;
            default = 16384;
            description = "Context window Nilo asks for, in tokens: more remembers more and takes more memory.";
        };

        coauthor = lib.mkOption
        {
            type = lib.types.nullOr (lib.types.submodule
            {
                options =
                {
                    name = lib.mkOption
                    {
                        type = lib.types.str;
                        default = "Nilo";
                        description = "Name in the trailer.";
                    };
                    email = lib.mkOption
                    {
                        type = lib.types.str;
                        description = "Email in the trailer: GitHub matches it to an account.";
                    };
                };
            });
            default =
            {
                name = "Nilo";
                email = "351236008+nilo-nihil@users.noreply.github.com";
            };
            description = ''
                Who Nilo signs its commits as, with a Co-authored-by trailer, so they
                show both of you. By default the account github.com/nilo-nihil
                (picture: assets/brand/nilo-avatar.png); GitHub shows the picture of
                whichever account the email belongs to. null leaves commits as they are.
            '';
        };

        searxng = lib.mkOption
        {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "http://127.0.0.1:8888";
            description = ''
                A SearXNG instance (with the JSON format enabled) for Nilo's web
                searches. By default it searches DuckDuckGo through ddgr.
            '';
        };
    };

    config = lib.mkIf cfg.enable
    {
        services.ollama =
        {
            enable = true;
            package = packages.${cfg.acceleration};
            environmentVariables = lib.mapAttrs (_: lib.mkDefault) (
            {
                OLLAMA_KEEP_ALIVE = "5m";
                OLLAMA_MAX_LOADED_MODELS = toString cfg.loadedModels;
                OLLAMA_NO_CLOUD = "1";
            }
            // lib.optionalAttrs cfg.integratedGpu
            {
                OLLAMA_IGPU_ENABLE = "1";
                LLAMA_ARG_NO_HOST = "1";
                LLAMA_ARG_FIT_TARGET = "4096";
            });
        };

        systemd.services.ollama.serviceConfig =
        {
            Restart = lib.mkDefault "on-failure";
            RestartSec = lib.mkDefault "2s";
            RestartSteps = lib.mkDefault 5;
            RestartMaxDelaySec = lib.mkDefault "1min";
            OOMScoreAdjust = lib.mkDefault 1000;
        };

        security.polkit.extraConfig = ''
            polkit.addRule(function(action, subject)
            {
                if (action.id == "org.freedesktop.systemd1.manage-units"
                    && action.lookup("unit") == "ollama.service"
                    && (action.lookup("verb") == "start" || action.lookup("verb") == "restart")
                    && subject.local && subject.active && subject.isInGroup("wheel"))
                    return polkit.Result.YES;
            });
        '';
    };
}
