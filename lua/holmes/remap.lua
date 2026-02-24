vim.g.mapleader=" "
vim.keymap.set("n", "<leader>fv", ":Lexplore<CR>", { desc = "Toggle Netrw Sidebar" })
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })

vim.keymap.set("n", "<leader>nh", ":nohlsearch<CR>", { desc = "Clear search highlights" })
vim.keymap.set("i", "jk", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })

-- Quick search and replace for the word under cursor
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor" })

-- Primeagen remap and sets.
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without overwriting register" })
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>d", "\"_d", { desc = "Delete without copying" })

-- Tmux navigation
vim.keymap.set("n", "<C-h>", "<Cmd>TmuxNavigateLeft<CR>")
vim.keymap.set("n", "<C-j>", "<Cmd>TmuxNavigateDown<CR>")
vim.keymap.set("n", "<C-k>", "<Cmd>TmuxNavigateUp<CR>")
vim.keymap.set("n", "<C-l>", "<Cmd>TmuxNavigateRight<CR>")

-- Open tmux split in current directory
vim.keymap.set("n", "<leader>t", function()
    local cwd = vim.fn.getcwd()
    vim.fn.system("tmux split-window -v -p 30 -c " .. vim.fn.shellescape(cwd))
end, { desc = "Open tmux horizontal split (bottom)" })