return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim",  'nvim-telescope/telescope.nvim'},
    config = function ()
      local harpoon = require("harpoon")

      harpoon:setup()

      vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)

      for i = 1, 9 do
       vim.keymap.set("n", "<leader>".. i , function() harpoon:list():select(i) end)
      end

      -- Toggle previous & next buffers stored within Harpoon list
      vim.keymap.set("n", "<leader>b", function() harpoon:list():prev() end)
      vim.keymap.set("n", "<leader>n", function() harpoon:list():next() end)

      vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
    end
  }
}
