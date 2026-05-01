{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Определяем python с пакетами для отладки
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
    # --- System Utilities ---
    ripgrep # Для поиска текста (нужен telescope)
    fd # Для поиска файлов
    lazygit # TUI для гита (опционально, но круто)
    xclip # / wl-clipboard # Для буфера обмена (зависит от x11 или wayland)

    # --- Languages & LSP ---
    # C/C++
    gcc
    clang-tools # clangd (LSP)

    # Rust (Чистый Nix Way, без rustup скриптов)
    rustc
    cargo
    rust-analyzer
    rustfmt
    clippy

    # Python
    basedpyright # Или просто pyright
    ruff # Линтер/Форматтер
    myPython

    # Web (HTML/CSS/JS)
    # nodePackages.vscode-langservers-extracted # HTML/CSS/JSON/ESLint
    # nodePackages.typescript-language-server # JS/TS
    prettierd # Форматтер

    # Assembly
    asm-lsp

    # Shell
    bash-language-server
    shfmt
    shellcheck

    # Pascal (Сложно с LSP, но компилятор добавим)
    fpc

    # Nix
    nixd
    nixfmt-rfc-style

    # File Manager
    yazi
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # --- Plugins ---
    plugins = with pkgs.vimPlugins; [
      # UI & Design
      onedark-nvim # Тема
      lualine-nvim # Статус бар снизу
      nvim-web-devicons # Иконки
      alpha-nvim # Дэшборд (Стартовый экран)
      indent-blankline-nvim # Линии отступов
      which-key-nvim # Подсказки клавиш (меню при нажатии Space)

      # Navigation & Fuzzy Finder
      telescope-nvim # Главная искалка всего
      plenary-nvim # Зависимость для telescope
      yazi-nvim # Файловый менеджер внутри nvim

      # Coding & IDE Features
      nvim-treesitter.withAllGrammars # Подсветка синтаксиса (лучшая)
      comment-nvim # Умное комментирование (gcc)
      auto-save-nvim # Автосохранение

      # LSP & Completion (Замена CoC)
      nvim-lspconfig # Настройка серверов
      nvim-cmp # Движок автодополнения
      cmp-nvim-lsp # Источник для LSP
      cmp-buffer # Источник из текущего файла
      cmp-path # Источник путей
      cmp-cmdline # Источник для командной строки
      luasnip # Сниппеты
      cmp_luasnip # Связка сниппетов и cmp
      friendly-snippets # Набор готовых сниппетов

      # Debugging (DAP)
      nvim-dap
      nvim-dap-ui
      nvim-dap-virtual-text
      nvim-dap-python
      nvim-nio
      rustaceanvim
    ];

    # --- Lua Config ---
    extraLuaConfig = ''
         vim.g.lspconfig_suppress_deprecation_warnings = true
         -- 1. BASIC SETTINGS
         vim.opt.number = true
         vim.opt.relativenumber = true -- Относительные номера строк (удобно для прыжков)
         vim.opt.tabstop = 2
         vim.opt.shiftwidth = 2
         vim.opt.expandtab = true
         vim.opt.autoindent = true
         vim.opt.smartindent = true
         vim.opt.scrolloff = 8 -- Курсор всегда в центре при скролле
         vim.opt.signcolumn = "yes"
         vim.opt.termguicolors = true
         vim.opt.updatetime = 50
         
         -- Clipboard setup (попытка определить систему)
         vim.schedule(function()
           vim.opt.clipboard = 'unnamedplus'
         end)
         
         -- Leader key
         vim.g.mapleader = " " 
         vim.g.maplocalleader = " "

         -- 2. THEME (OneDark)
         require('onedark').setup {
             style = 'deep',
             transparent = true, -- Прозрачный фон как ты хотел
             term_colors = true,
         }
         require('onedark').load()

         -- 3. TELESCOPE (Поиск)
         local builtin = require('telescope.builtin')
         vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find Files' })
         vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Grep Text' })
         vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find Buffers' })
         vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help' })

        -- 4. TREESITTER
         require'nvim-treesitter'.setup {
           highlight = { enable = true },
           indent = { enable = true },
           ensure_installed = {}, 
           sync_install = false,
           auto_install = false,
         }

         -- 5. YAZI (File Manager)
         local yazi = require("yazi")
         yazi.setup({
           open_for_directories = true,
         })
         vim.keymap.set("n", "<leader>yr", function() yazi.yazi() end, { desc = "Open Yazi" })

         -- 6. DASHBOARD (Alpha)
         local alpha = require("alpha")
         local dashboard = require("alpha.themes.dashboard")

         -- ASCII 
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

         -- 7. COMMENTING
         require('Comment').setup()

         -- 8. AUTOSAVE
         require("auto-save").setup({
            -- execution_message
         })
         
         -- 9. WHICH-KEY (Подсказки биндов)
         require("which-key").setup()
        
        -- 10. LSP & COMPLETION (nvim 0.11+)
        local capabilities = require('cmp_nvim_lsp').default_capabilities()

        local servers = {
          "clangd", "rust_analyzer", "basedpyright",
          "asm_lsp", "nixd", "bashls"
        }
        
        for _, lsp in ipairs(servers) do
          vim.lsp.config(lsp, { capabilities = capabilities })
        end
        
        vim.lsp.enable(servers)
        
        -- Бинды LSP
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
        
        -- cmp
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
        
        -- 11. DEBUGGING (DAP)
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
