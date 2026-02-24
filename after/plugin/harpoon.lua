local status, mark = pcall(require, "harpoon.mark")
if not status then
    return
end

local ui = require("harpoon.ui")

vim.keymap.set("n", "<leader><leader>a", mark.add_file, { desc = "Harpoon: Add file" })
vim.keymap.set("n", "<leader><leader>e", ui.toggle_quick_menu, { desc = "Harpoon: Toggle menu" })

vim.keymap.set("n", "<leader><leader>h", function() ui.nav_file(1) end, { desc = "Harpoon: Nav file 1" })
vim.keymap.set("n", "<leader><leader>t", function() ui.nav_file(2) end, { desc = "Harpoon: Nav file 2" })
vim.keymap.set("n", "<leader><leader>n", function() ui.nav_file(3) end, { desc = "Harpoon: Nav file 3" })
vim.keymap.set("n", "<leader><leader>s", function() ui.nav_file(4) end, { desc = "Harpoon: Nav file 4" })
