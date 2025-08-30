{ config, pkgs, inputs, ... }:

{
  imports = [ inputs.lazyvim.homeManagerModules.default ];
  programs.lazyvim = {
    enable = true;
    # Add LSP servers and tools
    extraPackages = with pkgs; [
      rust-analyzer
      gopls
      nodePackages.typescript-language-server
    ];
  
    # Add treesitter parsers
    treesitterParsers = with pkgs.tree-sitter-grammars; [
      tree-sitter-rust
      tree-sitter-go
      tree-sitter-typescript
      tree-sitter-tsx
    ];

    # Maps to lua/config/ directory
    config = {
      # Custom autocmds → lua/config/autocmds.lua
      autocmds = ''
        vim.api.nvim_create_autocmd("FocusLost", {
          command = "silent! wa",
        })
      '';
    
      # Custom keymaps → lua/config/keymaps.lua
      keymaps = ''
        vim.keymap.set("n", "<C-s>", "<cmd>w<cr>", { desc = "Save file" })
      '';
    
      # Custom options → lua/config/options.lua
      options = ''
        vim.opt.relativenumber = false
        vim.opt.wrap = true
      '';
    };
    
    # Maps to lua/plugins/ directory
    plugins = {
      # Each key becomes lua/plugins/{key}.lua
      custom-theme = ''
        return {
          "folke/tokyonight.nvim",
          opts = { style = "night", transparent = true },
        }
      '';
      
      lsp-config = ''
        return {
          "neovim/nvim-lspconfig",
          opts = function(_, opts)
            opts.servers.rust_analyzer = {
              settings = {
                ["rust-analyzer"] = {
                  checkOnSave = { command = "clippy" },
                },
              },
            }
            return opts
          end,
        }
      '';
    };
  };

}
