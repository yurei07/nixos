{ config, pkgs, inputs, ... }:

{
  imports = [ inputs.lazyvim.homeManagerModules.default ];
  programs.lazyvim = {
    enable = true;
    extraPackages = with pkgs; [
      # LSP servers
      lua-language-server
      nil
      nixd
      pyright
      ruff
      clang
      yaml-language-server
      rPackages.languageserver
      vim-language-server

      # Formatters
      alejandra
      stylua
      ruff
      shfmt

      # Tools
      ripgrep
      ast-grep
      fd
      git
      lua5_1
      luarocks
      tree-sitter
      sqlite # used by snacks for storing history
      xdotool # for vimtex forward search

      # Image preview tools
      viu
      chafa

      # SQLite for Snacks.picker frecency/history
      sqlite
      lua51Packages.luasql-sqlite3

      # Tools for Snacks.image rendering
      ghostscript # for PDF rendering
      mermaid-cli # for Mermaid diagrams
    ];

    # Add treesitter parsers
    treesitterParsers = with pkgs.tree-sitter-grammars; [
      tree-sitter-bash
      tree-sitter-bibtex
      tree-sitter-css
      tree-sitter-html
      tree-sitter-javascript
      tree-sitter-json
      tree-sitter-julia
      tree-sitter-latex
      tree-sitter-lua
      tree-sitter-markdown
      tree-sitter-nix
      tree-sitter-norg
      tree-sitter-nu
      tree-sitter-python
      tree-sitter-r
      tree-sitter-regex
      tree-sitter-scss
      tree-sitter-svelte
      tree-sitter-toml
      tree-sitter-tsx
      tree-sitter-typescript
      tree-sitter-typst
      tree-sitter-yaml
      tree-sitter-vue
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
