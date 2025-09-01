return {
  {
    'nvim-mini/mini.nvim',
    version = false,
    config = function ()
      vim.keymap.set('n', 's', '<Nop>', { noremap = true })
      require("mini.extra").setup()
      require("mini.icons").setup()
      require("mini.files").setup()
      require("mini.notify").setup()
      -- require("mini.indentscope").setup({draw = {delay = 0, animation = require('mini.indentscope').gen_animation.none()}, mappings = {}, symbol="┃", options={try_as_boarder=true }})
      require('mini.indentscope').gen_animation.none()
      require("mini.surround").setup({ mappings = { add = 's'}})
      require("mini.comment").setup({ mappings = { comment = 'sc', comment_line = 'scc', comment_visual = 'sc', textobject = 'sc' } })
      require("mini.splitjoin").setup({ mappings = { toggle = 'sS'} })

      vim.keymap.set("n", "<leader>e", function ()
        MiniFiles.open()
      end) 
    end
  }
}
