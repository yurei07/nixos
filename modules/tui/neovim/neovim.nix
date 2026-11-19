# Neovim editor and toolchain.
{
  config,
  pkgs,
  lib,
  theme,
  ...
}:
let
  # Python used for nvim-dap-python.
  myPython = pkgs.python3.withPackages (
    ps: with ps; [
      click
      debugpy
      pillow
      tkinter
      requests
    ]
  );
in
{
  home.packages = with pkgs; [
    # search / navigation
    ripgrep
    fd
    lazygit
    xclip

    # language servers / toolchains
    gcc
    clang-tools
    dotnet-aspnetcore_10
    icu
    openssl
    zlib
    docker
    rustc
    cargo
    rust-analyzer
    rustfmt
    clippy
    basedpyright
    ruff
    myPython
    prettierd
    asm-lsp
    bash-language-server
    shfmt
    shellcheck
    fpc
    nixd
    nixfmt

    # file manager
    yazi
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withRuby = false;
    withPython3 = false;

    plugins = with pkgs.vimPlugins; [
      # ui
      mini-nvim
      lualine-nvim
      nvim-web-devicons
      alpha-nvim
      indent-blankline-nvim
      which-key-nvim

      # navigation / fuzzy finder
      telescope-nvim
      plenary-nvim
      yazi-nvim

      # coding / ide
      nvim-treesitter.withAllGrammars
      comment-nvim
      auto-save-nvim

      # lsp / completion
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      luasnip
      cmp_luasnip
      friendly-snippets

      # debugging
      nvim-dap
      nvim-dap-ui
      nvim-dap-virtual-text
      nvim-dap-python
      nvim-nio
      rustaceanvim
    ];

    initLua = ''
         vim.g.lspconfig_suppress_deprecation_warnings = true

         -- basics
         vim.opt.number = true
         vim.opt.relativenumber = true
         vim.opt.tabstop = 2
         vim.opt.shiftwidth = 2
         vim.opt.expandtab = true
         vim.opt.autoindent = true
         vim.opt.smartindent = true
         vim.opt.scrolloff = 8
         vim.opt.signcolumn = "yes"
         vim.opt.termguicolors = true
         vim.opt.updatetime = 50
         vim.schedule(function()
           vim.opt.clipboard = 'unnamedplus'
         end)
         vim.g.mapleader = " "
         vim.g.maplocalleader = " "

         -- theme (kanso-zen palette)
         require('mini.base16').setup({
           palette = {
             base00 = "${theme.palette.zen0}",
             base01 = "${theme.palette.zen1}",
             base02 = "${theme.palette.zen2}",
             base03 = "${theme.palette.zen3}",
             base04 = "${theme.palette.katanaGray}",
             base05 = "${theme.palette.oldWhite}",
             base06 = "${theme.palette.fujiWhite}",
             base07 = "${theme.palette.fujiWhite}",
             base08 = "${theme.palette.zenRed}",
             base09 = "${theme.palette.carpYellow}",
             base0A = "${theme.palette.roninYellow}",
             base0B = "${theme.palette.autumnGreen}",
             base0C = "${theme.palette.zenAqua1}",
             base0D = "${theme.palette.springBlue}",
             base0E = "${theme.palette.springViolet1}",
             base0F = "${theme.palette.zenAqua2}",
           },
         })

         vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
         vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })

         -- telescope
         local builtin = require('telescope.builtin')
         vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find Files' })
         vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Grep Text' })
         vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find Buffers' })
         vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help' })

         -- treesitter
         require'nvim-treesitter'.setup {
           highlight = { enable = true },
           indent = { enable = true },
           ensure_installed = {},
           sync_install = false,
           auto_install = false,
         }

         -- yazi
         local yazi = require("yazi")
         yazi.setup({
           open_for_directories = true,
         })
         vim.keymap.set("n", "<leader>yr", function() yazi.yazi() end, { desc = "Open Yazi" })

         -- dashboard
         local alpha = require("alpha")
         local dashboard = require("alpha.themes.dashboard")

         dashboard.section.header.val = {
         	[[                                  ]],
      	[[   ██████╗ ██████╗ ██╗███████╗    ]],
       	[[   ██╔══██╗██╔══██╗██║╚══███╔╝    ]],
       	[[   ██████╔╝██████╔╝██║  ███╔╝     ]],
       	[[   ██╔═══╝ ██╔══██╗██║ ███╔╝      ]],
       	[[   ██║     ██║  ██║██║███████╗    ]],
       	[[   ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝    ]],
       	[[                                  ]],
       	[[          Prizrak_幽霊          ]],
         }

         dashboard.section.buttons.val = {
           dashboard.button("f", "  Find file", ":Telescope find_files<CR>"),
           dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
           dashboard.button("r", "  Recent files", ":Telescope oldfiles<CR>"),
           dashboard.button("y", "  File Manager (Yazi)", ":Yazi<CR>"),
           dashboard.button("q", "  Quit NVIM", ":qa<CR>"),
         }
         alpha.setup(dashboard.config)

         require('Comment').setup()

         require("auto-save").setup({})

         require("which-key").setup()

         -- lsp + completion
         local capabilities = require('cmp_nvim_lsp').default_capabilities()

         local servers = {
           "clangd", "rust_analyzer", "basedpyright",
           "asm_lsp", "nixd", "bashls"
         }

         for _, lsp in ipairs(servers) do
           vim.lsp.config(lsp, { capabilities = capabilities })
         end

         vim.lsp.enable(servers)

         vim.api.nvim_create_autocmd('LspAttach', {
           callback = function(ev)
             local opts = { buffer = ev.buf, noremap = true, silent = true }
             vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
             vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
             vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
             vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
             vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
             vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
             vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
             vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, opts)
           end,
         })

         local cmp = require('cmp')
         cmp.setup({
           snippet = {
             expand = function(args)
               require('luasnip').lsp_expand(args.body)
             end,
           },
           mapping = cmp.mapping.preset.insert({
             ['<C-b>'] = cmp.mapping.scroll_docs(-4),
             ['<C-f>'] = cmp.mapping.scroll_docs(4),
             ['<C-Space>'] = cmp.mapping.complete(),
             ['<C-e>'] = cmp.mapping.abort(),
             ['<CR>'] = cmp.mapping.confirm({ select = true }),
             ['<Tab>'] = cmp.mapping.select_next_item(),
           }),
           sources = cmp.config.sources({
             { name = 'nvim_lsp' },
             { name = 'luasnip' },
           }, {
             { name = 'buffer' },
             { name = 'path' },
           })
         })

         -- debugging
         local dap = require('dap')
         local dapui = require('dapui')
         local ok, nio = pcall(require, 'nio')
         if not ok then
           vim.notify("nvim-nio not found, dap-ui may not work", vim.log.levels.WARN)
         end

         dapui.setup()
         require("nvim-dap-virtual-text").setup()

         dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
         dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
         dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

         require('dap-python').setup('${myPython}/bin/python')

         vim.keymap.set('n', '<F5>', function() dap.continue() end, {desc = "Debug Continue"})
         vim.keymap.set('n', '<F10>', function() dap.step_over() end, {desc = "Debug Step Over"})
         vim.keymap.set('n', '<F11>', function() dap.step_into() end, {desc = "Debug Step Into"})
         vim.keymap.set('n', '<leader>b', function() dap.toggle_breakpoint() end, {desc = "Toggle Breakpoint"})
    '';
  };
}
