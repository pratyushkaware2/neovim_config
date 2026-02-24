local status, opencode = pcall(require, "opencode")
if not status then
    return
end

vim.g.opencode_opts = {}
vim.o.autoread = true

-- Keybindings using <leader>o prefix
vim.keymap.set({ "n", "x" }, "<leader>oa", function() opencode.ask("@this: ", { submit = true }) end, { desc = "Opencode: Ask" })
vim.keymap.set("n", "<leader>ob", function() opencode.ask("@buffer: ", { submit = true }) end, { desc = "Opencode: Ask (Whole Buffer)" })
vim.keymap.set("n", "<leader>ov", function() opencode.ask("@visible: ", { submit = true }) end, { desc = "Opencode: Ask (Visible Text)" })
vim.keymap.set({ "n", "x" }, "<leader>os", function() opencode.select() end, { desc = "Opencode: Select action" })
vim.keymap.set({ "n", "t" }, "<leader>ot", function() opencode.toggle() end, { desc = "Opencode: Toggle" })

-- Operator mappings (keeping standard 'go' convention)
vim.keymap.set({ "n", "x" }, "go", function() return opencode.operator("@this ") end, { desc = "Opencode: Add range", expr = true })
vim.keymap.set("n", "goo", function() return opencode.operator("@this ") .. "_" end, { desc = "Opencode: Add line", expr = true })

-- Scrolling
vim.keymap.set("n", "<leader>ou", function() opencode.command("session.half.page.up") end, { desc = "Opencode: Scroll up" })
vim.keymap.set("n", "<leader>od", function() opencode.command("session.half.page.down") end, { desc = "Opencode: Scroll down" })
