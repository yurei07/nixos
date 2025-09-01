--adding all the lsp configs

--huge dict with most important lsps

local servers = {
  lua_ls = "lua-language-server", -- Lua
  clangd = "clangd", -- C/C++
  pyright = "pyright-langserver", -- Python
  ts_ls = "typescript-language-server", -- JavaScript / TypeScript
  html = "vscode-html-language-server", -- HTML
  cssls = "vscode-css-language-server", -- CSS
  jsonls = "vscode-json-language-server", -- JSON
  eslint = "vscode-eslint-language-server", -- ESLint
  yamlls = "yaml-language-server", -- YAML
  bashls = "bash-language-server", -- Bash
  dockerls = "docker-langserver", -- Docker
  cmake = "cmake-language-server", -- CMake
  vimls = "vim-language-server", -- VimScript
  gopls = "gopls", -- Go
  intelephense = "intelephense", -- PHP
  solargraph = "solargraph", -- Ruby
  jdtls = "jdtls", -- Java
  hls = "haskell-language-server-wrapper", -- Haskell
  clojure_lsp = "clojure-lsp", -- Clojure
  elixirls = "elixir-ls", -- Elixir
  sourcekit = "sourcekit-lsp", -- Swift
  perlnavigator = "perlnavigator", -- Perl
  kotlin_language_server = "kotlin-language-server", -- Kotlin
  tailwindcss = "tailwindcss-language-server", -- Tailwind CSS
  marksman = "marksman", -- Markdown
  svelte = "svelteserver", -- Svelte
  volar = "vue-language-server", -- Vue (Volar)
  rescriptls = "rescript-language-server", -- ReScript
  reason_ls = "reason-language-server", -- ReasonML
  sqls = "sqls", -- SQL
}

--this little function checks if the lsp is executable
--if true it will enable its config so i dont get errors
--when i manage the lsp with a nix-shell :D

for config, binary in pairs(servers) do
  if vim.fn.executable(binary) == 1 then
    vim.lsp.enable(config)
  end
end

vim.diagnostic.config({
  virtual_lines ={
    current_line = true
  },
  update_in_insert = true
})



