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

  # codelldb: the debug adapter for C/C++ (and Rust through rustaceanvim).
  lldb = pkgs.vscode-extensions.vadimcn.vscode-lldb;
  codelldb = "${lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
  liblldb = "${lldb}/share/vscode/extensions/vadimcn.vscode-lldb/lldb/lib/liblldb.so";
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

    # php
    php84
    intelephense

    # web stack
    typescript
    typescript-language-server
    vscode-langservers-extracted
    tailwindcss-language-server
    emmet-language-server

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
      bufferline-nvim
      vim-illuminate

      # navigation / fuzzy finder
      telescope-nvim
      plenary-nvim
      yazi-nvim
      neo-tree-nvim
      nui-nvim

      # coding / ide
      nvim-treesitter.withAllGrammars
      comment-nvim
      auto-save-nvim
      gitsigns-nvim
      conform-nvim

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

      # diagnostics / trouble
      trouble-nvim

      # terminal / sessions
      toggleterm-nvim
      persistence-nvim

      # debugging
      nvim-dap
      nvim-dap-ui
      nvim-dap-virtual-text
      nvim-dap-python
      nvim-nio
      rustaceanvim

      # ai (opencode)
      opencode-nvim
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
             base00 = "#${theme.palette.zen0}",
             base01 = "#${theme.palette.zen1}",
             base02 = "#${theme.palette.zen2}",
             base03 = "#${theme.palette.zen3}",
             base04 = "#${theme.palette.katanaGray}",
             base05 = "#${theme.palette.oldWhite}",
             base06 = "#${theme.palette.fujiWhite}",
             base07 = "#${theme.palette.fujiWhite}",
             base08 = "#${theme.palette.zenRed}",
             base09 = "#${theme.palette.carpYellow}",
             base0A = "#${theme.palette.roninYellow}",
             base0B = "#${theme.palette.autumnGreen}",
             base0C = "#${theme.palette.zenAqua1}",
             base0D = "#${theme.palette.springBlue}",
             base0E = "#${theme.palette.springViolet1}",
             base0F = "#${theme.palette.zenAqua2}",
           },
         })

         vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
         vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })

         -- onehalf-flavoured syntax, in the kanso-zen palette: italic violet keywords,
         -- orange strings, dim italic comments, italic calls and fields (Victor Mono's
         -- cursive italics carry it)
         local syn = {
           ['@keyword'] = { fg = '#9d7cd8', italic = true },
           ['@keyword.function'] = { fg = '#9d7cd8', italic = true },
           ['@keyword.operator'] = { fg = '#9d7cd8', italic = true },
           ['@keyword.modifier'] = { fg = '#9d7cd8', italic = true },
           ['@keyword.coroutine'] = { fg = '#9d7cd8', italic = true },
           ['@keyword.return'] = { fg = '#9d7cd8', italic = true },
           ['@string'] = { fg = '#ff9e3b' },
           ['@string.escape'] = { fg = '#e7c09a' },
           ['@comment'] = { fg = '#6b6b6b', italic = true },
           ['@function'] = { fg = '#dcd7ba' },
           ['@function.call'] = { fg = '#dcd7ba', italic = true },
           ['@method'] = { fg = '#dcd7ba' },
           ['@function.method'] = { fg = '#dcd7ba' },
           ['@function.method.call'] = { fg = '#dcd7ba', italic = true },
           ['@constructor'] = { fg = '#e8e5d8' },
           ['@type'] = { fg = '#e8e5d8' },
           ['@property'] = { fg = '#dcd7ba', italic = true },
           ['@variable.member'] = { fg = '#dcd7ba', italic = true },
           ['@number'] = { fg = '#e8e5d8' },
           ['@boolean'] = { fg = '#9d7cd8', italic = true },
           ['@operator'] = { fg = '#e46876' },
           ['@punctuation.delimiter'] = { fg = '#e8e5d8' },
           ['@punctuation.bracket'] = { fg = '#dcd7ba' },
         }
         for name, attrs in pairs(syn) do
           vim.api.nvim_set_hl(0, name, attrs)
           -- plain syntax fallbacks for filetypes without treesitter
         end
         vim.api.nvim_set_hl(0, 'Statement', { fg = '#9d7cd8', italic = true })
         vim.api.nvim_set_hl(0, 'String', { fg = '#ff9e3b' })
         vim.api.nvim_set_hl(0, 'Comment', { fg = '#6b6b6b', italic = true })
         vim.api.nvim_set_hl(0, 'Function', { fg = '#dcd7ba', italic = true })
         vim.api.nvim_set_hl(0, 'Special', { fg = '#dcd7ba', italic = true })
         vim.api.nvim_set_hl(0, 'Operator', { fg = '#e46876' })
         vim.api.nvim_set_hl(0, 'Type', { fg = '#e8e5d8' })

         -- which-key groups (everything else groups itself by desc)
         require("which-key").add({
           { "<leader>f", group = "Find" },
           { "<leader>g", group = "Git" },
           { "<leader>c", group = "Code" },
           { "<leader>x", group = "Diagnostics" },
           { "<leader>d", group = "Debug" },
           { "<leader>q", group = "Session" },
           { "<leader>a", group = "AI (OpenCode)" },
           { "<leader>y", group = "Yazi" },
         })
         require("which-key").setup()

         -- telescope
         local builtin = require('telescope.builtin')
         vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find Files' })
         vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Grep Text' })
         vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find Buffers' })
         vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help' })
         -- the cheatsheet: every binding, searchable
         vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = 'Keymaps (Cheatsheet)' })

         -- treesitter
         require'nvim-treesitter'.setup {
           highlight = { enable = true },
           indent = { enable = true },
           ensure_installed = {},
           sync_install = false,
           auto_install = false,
         }

         -- file tree
         require("neo-tree").setup({
           close_if_last_window = true,
           window = { width = 30 },
           filesystem = {
             follow_current_file = { enabled = true },
             use_libuv_file_watcher = true,
           },
         })
         vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "File Tree" })

         -- yazi
         local yazi = require("yazi")
         yazi.setup({
           open_for_directories = true,
         })
         vim.keymap.set("n", "<leader>yr", function() yazi.yazi() end, { desc = "Open Yazi" })

         -- tabs (bufferline)
         require("bufferline").setup({
           options = {
             diagnostics = "nvim_lsp",
             separator_style = "thin",
             show_buffer_close_icons = false,
             show_close_icon = false,
           },
         })
         vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })
         vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })
         vim.keymap.set("n", "<leader>bd", "<cmd>bd<cr>", { desc = "Close Buffer" })

         -- git
         require("gitsigns").setup({
           on_attach = function(bufnr)
             local gs = package.loaded.gitsigns
             local opts = { buffer = bufnr }
             vim.keymap.set("n", "]h", gs.next_hunk, { buffer = bufnr, desc = "Next Hunk" })
             vim.keymap.set("n", "[h", gs.prev_hunk, { buffer = bufnr, desc = "Prev Hunk" })
             vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { buffer = bufnr, desc = "Preview Hunk" })
             vim.keymap.set("n", "<leader>gb", function() gs.blame_line { full = true } end, { buffer = bufnr, desc = "Blame Line" })
             vim.keymap.set("n", "<leader>gs", gs.stage_hunk, { buffer = bufnr, desc = "Stage Hunk" })
             vim.keymap.set("n", "<leader>gr", gs.reset_hunk, { buffer = bufnr, desc = "Reset Hunk" })
           end,
         })

         -- formatting (conform)
         require("conform").setup({
           formatters_by_ft = {
             javascript = { "prettierd" },
             typescript = { "prettierd" },
             javascriptreact = { "prettierd" },
             typescriptreact = { "prettierd" },
             html = { "prettierd" },
             css = { "prettierd" },
             json = { "prettierd" },
             nix = { "nixfmt" },
             rust = { "rustfmt" },
             c = { "clang-format" },
             cpp = { "clang-format" },
             sh = { "shfmt" },
             python = { "ruff" },
           },
         })
         vim.keymap.set("n", "<leader>cf", function() require("conform").format({ async = true, lsp_fallback = true }) end, { desc = "Format" })

         -- diagnostics (trouble)
         require("trouble").setup({})
         vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "All Diagnostics" })
         vim.keymap.set("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics" })
         vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Next Diagnostic" })
         vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Prev Diagnostic" })

         -- highlight word uses (illuminate)
         require("illuminate").configure({ delay = 100 })
         vim.keymap.set("n", "<A-n>", require("illuminate").goto_next_reference, { desc = "Next Reference" })
         vim.keymap.set("n", "<A-p>", require("illuminate").goto_prev_reference, { desc = "Prev Reference" })

         -- float terminal
         require("toggleterm").setup({
           direction = "float",
           float_opts = { border = "rounded" },
         })
         vim.keymap.set({ "n", "t" }, "<C-\\>", "<cmd>ToggleTerm<cr>", { desc = "Toggle Terminal" })

         -- lazygit in a float
         local Terminal = require("toggleterm.terminal").Terminal
         local lazygitTerm = Terminal:new({
           cmd = "lazygit",
           hidden = true,
           direction = "float",
           float_opts = { border = "rounded" },
         })
         vim.keymap.set("n", "<leader>gg", function() lazygitTerm:toggle() end, { desc = "Lazygit" })

         -- sessions (persistence)
         require("persistence").setup({})
         vim.keymap.set("n", "<leader>qs", function() require("persistence").load() end, { desc = "Restore Session (cwd)" })
         vim.keymap.set("n", "<leader>qS", function() require("persistence").load({ last = true }) end, { desc = "Restore Last Session" })

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
           dashboard.button("r", "  Recent files", ":Telescope oldfiles<CR>"),
           dashboard.button("s", "  Restore session", ":lua require('persistence').load({ last = true })<CR>"),
           dashboard.button("y", "  File Manager (Yazi)", ":Yazi<CR>"),
           dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
           dashboard.button("q", "  Quit NVIM", ":qa<CR>"),
         }
         alpha.setup(dashboard.config)

         require('Comment').setup()

         require("auto-save").setup({})

         -- lsp + completion
         local capabilities = require('cmp_nvim_lsp').default_capabilities()

         local servers = {
           "clangd", "rust_analyzer", "basedpyright",
           "asm_lsp", "nixd", "bashls",
           "ts_ls", "html", "cssls", "jsonls", "tailwindcss", "emmet_language_server",
           "intelephense",
         }

         for _, lsp in ipairs(servers) do
           vim.lsp.config(lsp, { capabilities = capabilities })
         end

         -- php files: intelephense covers php + the html inside them;
         -- emmet adds html/css expansions right in .php buffers
         vim.lsp.config("intelephense", {
           capabilities = capabilities,
           settings = { intelephense = { telemetry = { enabled = false } } },
         })
         vim.lsp.config("emmet_language_server", {
           capabilities = capabilities,
           filetypes = { "html", "php", "css", "less", "sass", "scss", "javascriptreact", "typescriptreact" },
         })

         vim.lsp.enable(servers)

         vim.api.nvim_create_autocmd('LspAttach', {
           callback = function(ev)
             local opts = { buffer = ev.buf, noremap = true, silent = true }
             vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
             vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
             vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
             vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
             vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { buffer = ev.buf, desc = 'Rename' })
             vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = ev.buf, desc = 'Code Action' })
             vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
             -- inlay hints on by default, toggle with a key
             vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
           end,
         })
         vim.keymap.set('n', '<leader>ih', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, { desc = 'Toggle Inlay Hints' })

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

         -- codelldb adapter: C/C++ here, Rust through rustaceanvim
         dap.adapters.codelldb = { type = "executable", command = "${codelldb}", name = "codelldb" }
         local launch_program = function()
           return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
         end
         for _, lang in ipairs({ "c", "cpp" }) do
           dap.configurations[lang] = {
             { name = "Launch", type = "codelldb", request = "launch", program = launch_program, cwd = "''${workspaceFolder}", stopOnEntry = false },
           }
         end

         vim.g.rustaceanvim = {
           dap = {
             adapter = require('rustaceanvim.config').get_codelldb_adapter("${codelldb}", "${liblldb}"),
           },
         }

         require('dap-python').setup('${myPython}/bin/python')

         vim.keymap.set('n', '<F5>', function() dap.continue() end, {desc = "Debug Continue"})
         vim.keymap.set('n', '<F10>', function() dap.step_over() end, {desc = "Debug Step Over"})
         vim.keymap.set('n', '<F11>', function() dap.step_into() end, {desc = "Debug Step Into"})
         vim.keymap.set('n', '<leader>db', function() dap.toggle_breakpoint() end, {desc = "Toggle Breakpoint"})

         -- ai (opencode): the daemon is found automatically, or opens itself
         vim.g.opencode_opts = {}

         vim.keymap.set({ "n", "x" }, "<leader>aa", function() require("opencode").ask("@this: ") end, { desc = "Ask OpenCode" })
         vim.keymap.set({ "n", "x" }, "<leader>ax", function() require("opencode").select() end, { desc = "OpenCode Menu" })
         vim.keymap.set("n", "<leader>ap", function() require("opencode").prompt("diagnostics") end, { desc = "AI: Explain Diagnostics" })
         vim.keymap.set("n", "go", function() return require("opencode").operator("@this") end, { expr = true, desc = "Send Range to OpenCode" })
         vim.keymap.set("n", "goo", function() return require("opencode").operator("@this") .. "_" end, { expr = true, desc = "Send Line to OpenCode" })
    '';
  };
}
