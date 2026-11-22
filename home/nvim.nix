# nvim.nix by poligle

{ config, osConfig, pkgs, ... }:
let
    t = osConfig.nihil.tokens;

    rainbowDelimiters = pkgs.vimPlugins.rainbow-delimiters-nvim.overrideAttrs
    {
        src = pkgs.fetchFromGitHub
        {
            owner = "HiPhish";
            repo = "rainbow-delimiters.nvim";
            rev = "v0.12.0";
            hash = "sha256-q4cBvF8d5h+BM1LTm5aq02OBVmwSUb9rC1smHlxbRzg=";
        };
    };
in
{
    programs.neovim = 
    {
        enable = true;

        viAlias = true;
        vimAlias = true;
        defaultEditor = true;

        extraPackages = with pkgs;
        [
            ripgrep
            fd
            wl-clipboard
            nil
            lua-language-server
            pyright
            nixfmt
            stylua
        ];

        plugins = with pkgs.vimPlugins;
        [
            (nvim-treesitter.withPlugins (grammars:
            [
                grammars.nix
                grammars.lua
                grammars.python
                grammars.bash
                grammars.markdown
                grammars.markdown_inline
                grammars.json
                grammars.yaml
                grammars.toml
                grammars.c
                grammars.vim
                grammars.vimdoc
            ]))

            plenary-nvim
            telescope-nvim
            telescope-fzf-native-nvim

            nvim-lspconfig
            nvim-cmp
            cmp-nvim-lsp
            cmp-buffer
            cmp-path
            luasnip
            cmp_luasnip

            conform-nvim
            gitsigns-nvim
            comment-nvim
            nvim-autopairs
            indent-blankline-nvim
            rainbowDelimiters
            which-key-nvim
            lualine-nvim
            oil-nvim
        ];

        initLua = ''
            vim.g.mapleader = " "
            vim.g.maplocalleader = " "

            vim.opt.number = true
            vim.opt.relativenumber = true
            vim.opt.scrolloff = 8
            vim.opt.sidescrolloff = 8

            vim.opt.tabstop = 4
            vim.opt.shiftwidth = 4
            vim.opt.softtabstop = 4
            vim.opt.expandtab = true
            vim.opt.smartindent = true
            vim.opt.breakindent = true

            vim.opt.termguicolors = true
            vim.opt.cursorline = true
            vim.opt.signcolumn = "yes"
            vim.opt.wrap = false
            vim.opt.splitright = true
            vim.opt.splitbelow = true
            vim.opt.showmode = false
            vim.opt.list = true
            vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
            vim.opt.updatetime = 250
            vim.opt.timeoutlen = 400
            vim.opt.confirm = true

            vim.opt.ignorecase = true
            vim.opt.smartcase = true
            vim.opt.inccommand = "split"

            vim.opt.undofile = true
            vim.opt.swapfile = false
            vim.opt.backup = false

            vim.opt.mouse = "a"
            vim.opt.clipboard = "unnamedplus"

            vim.opt.completeopt = { "menu", "menuone", "noselect" }

            vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
            vim.keymap.set("n", "<leader>w", "<cmd>write<CR>", { desc = "Write buffer" })
            vim.keymap.set("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })
            vim.keymap.set("n", "<leader>e", "<cmd>Oil<CR>", { desc = "Open file explorer" })

            vim.keymap.set({ "n", "v" }, "<leader>y", "\"+y", { desc = "Yank to system clipboard" })
            vim.keymap.set("n", "<leader>Y", "\"+Y", { desc = "Yank line to system clipboard" })
            vim.keymap.set({ "n", "v" }, "<leader>p", "\"+p", { desc = "Paste from system clipboard" })
            vim.keymap.set("x", "<leader>P", "\"_dP", { desc = "Paste without clobbering register" })

            vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Focus window left" })
            vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Focus window down" })
            vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Focus window up" })
            vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Focus window right" })

            vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
            vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

            local telescopeBuiltin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", telescopeBuiltin.find_files,  { desc = "Find files" })
            vim.keymap.set("n", "<leader>fg", telescopeBuiltin.live_grep,   { desc = "Grep in project" })
            vim.keymap.set("n", "<leader>fb", telescopeBuiltin.buffers,     { desc = "Find buffers" })
            vim.keymap.set("n", "<leader>fh", telescopeBuiltin.help_tags,   { desc = "Find help tags" })
            vim.keymap.set("n", "<leader>fd", telescopeBuiltin.diagnostics, { desc = "Find diagnostics" })

            vim.api.nvim_create_autocmd("TextYankPost",
            {
                group = vim.api.nvim_create_augroup("HighlightOnYank", { clear = true }),
                callback = function()
                    vim.hl.on_yank({ timeout = 150 })
                end,
            })

            vim.api.nvim_create_autocmd("FileType",
            {
                group = vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true }),
                callback = function(event)
                    pcall(vim.treesitter.start, event.buf)
                end,
            })

            require("telescope").setup({})
            pcall(require("telescope").load_extension, "fzf")

            local cmp = require("cmp")
            local luasnip = require("luasnip")

            cmp.setup(
            {
                snippet =
                {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert(
                {
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<CR>"]      = cmp.mapping.confirm({ select = true }),
                    ["<C-n>"]     = cmp.mapping.select_next_item(),
                    ["<C-p>"]     = cmp.mapping.select_prev_item(),
                }),
                sources = cmp.config.sources(
                {
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "path" },
                    { name = "buffer" },
                }),
            })

            local lspCapabilities = require("cmp_nvim_lsp").default_capabilities()

            vim.lsp.config("*", { capabilities = lspCapabilities })

            vim.lsp.config("lua_ls",
            {
                settings = { Lua = { diagnostics = { globals = { "vim" } } } },
            })

            vim.lsp.enable({ "nil_ls", "lua_ls", "pyright" })

            vim.api.nvim_create_autocmd("LspAttach",
            {
                group = vim.api.nvim_create_augroup("LspKeymaps", { clear = true }),
                callback = function(event)
                    local options = { buffer = event.buf }
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition,  options)
                    vim.keymap.set("n", "gr", vim.lsp.buf.references,  options)
                    vim.keymap.set("n", "K",  vim.lsp.buf.hover,       options)
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,      options)
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, options)
                end,
            })

            require("conform").setup(
            {
                formatters_by_ft =
                {
                    nix = { "nixfmt" },
                    lua = { "stylua" },
                },
            })

            vim.keymap.set("n", "<leader>fm", function()
                require("conform").format({ lsp_format = "fallback" })
            end, { desc = "Format buffer" })

            require("Comment").setup()
            require("nvim-autopairs").setup({})
            require("gitsigns").setup({})
            require("which-key").setup({})
            require("oil").setup({})

            require("ibl").setup({ scope = { enabled = true } })

            require("lualine").setup(
            {
                options = { theme = "auto", globalstatus = true },
            })

            local function nihilHighlights()
                local foreground = "#${t.base16.base05}"
                for _, group in ipairs({ "Identifier", "@variable", "@variable.member", "@variable.parameter", "@property", "@field", "@parameter", "@tag", "@tag.attribute" }) do
                    vim.api.nvim_set_hl(0, group, { fg = foreground })
                end
                vim.api.nvim_set_hl(0, "Keyword", { fg = "#${t.base16.base0E}", bold = true })
                vim.api.nvim_set_hl(0, "@keyword", { fg = "#${t.base16.base0E}", bold = true })
            end

            vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" },
            {
                group = vim.api.nvim_create_augroup("NihilHighlights", { clear = true }),
                callback = nihilHighlights,
            })
        '';
    };
}
