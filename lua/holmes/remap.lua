-- All keymaps (global + plugin-specific)
-- Plugin declarations live in plugins.lua, setup/config lives in setup.lua.

vim.g.mapleader = " "

---------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------
vim.keymap.set("n", "<leader>fv", ":Lexplore<CR>", { desc = "Toggle Netrw Sidebar" })
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })
vim.keymap.set("n", "<leader>nh", ":nohlsearch<CR>", { desc = "Clear search highlights" })
vim.keymap.set("i", "jk", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor" })

-- Clipboard / register helpers
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without overwriting register" })
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>d", "\"_d", { desc = "Delete without copying" })

---------------------------------------------------------------------------
-- Tmux navigation
---------------------------------------------------------------------------
vim.keymap.set("n", "<C-h>", "<Cmd>TmuxNavigateLeft<CR>")
vim.keymap.set("n", "<C-j>", "<Cmd>TmuxNavigateDown<CR>")
vim.keymap.set("n", "<C-k>", "<Cmd>TmuxNavigateUp<CR>")
vim.keymap.set("n", "<C-l>", "<Cmd>TmuxNavigateRight<CR>")

-- Open tmux split in current directory
vim.keymap.set("n", "<leader>t", function()
    local cwd = vim.fn.getcwd()
    vim.fn.system("tmux split-window -v -p 30 -c " .. vim.fn.shellescape(cwd))
end, { desc = "Open tmux horizontal split (bottom)" })

---------------------------------------------------------------------------
-- Telescope
---------------------------------------------------------------------------
local telescope_ok, builtin = pcall(require, "telescope.builtin")
if telescope_ok then
    vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
    vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Telescope diagnostics" })
    vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Telescope fuzzy find in current buffer" })
    vim.keymap.set("n", "<leader>fs", function()
        builtin.grep_string({ search = vim.fn.input("Grep > ") })
    end, { desc = "Telescope grep string input" })
end

---------------------------------------------------------------------------
-- Harpoon
---------------------------------------------------------------------------
local harpoon_ok, mark = pcall(require, "harpoon.mark")
if harpoon_ok then
    local ui = require("harpoon.ui")
    vim.keymap.set("n", "<leader><leader>a", mark.add_file, { desc = "Harpoon: Add file" })
    vim.keymap.set("n", "<leader><leader>e", ui.toggle_quick_menu, { desc = "Harpoon: Toggle menu" })
    vim.keymap.set("n", "<leader><leader>h", function() ui.nav_file(1) end, { desc = "Harpoon: Nav file 1" })
    vim.keymap.set("n", "<leader><leader>t", function() ui.nav_file(2) end, { desc = "Harpoon: Nav file 2" })
    vim.keymap.set("n", "<leader><leader>n", function() ui.nav_file(3) end, { desc = "Harpoon: Nav file 3" })
    vim.keymap.set("n", "<leader><leader>s", function() ui.nav_file(4) end, { desc = "Harpoon: Nav file 4" })
end

---------------------------------------------------------------------------
-- Undotree
---------------------------------------------------------------------------
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Toggle UndoTree" })

---------------------------------------------------------------------------
-- Fugitive
---------------------------------------------------------------------------
vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Git status" })

---------------------------------------------------------------------------
-- Conform (Formatting)
---------------------------------------------------------------------------
local conform_ok, conform = pcall(require, "conform")
if conform_ok then
    vim.keymap.set({ "n", "v" }, "<leader>cf", function()
        conform.format({
            lsp_fallback = true,
            async = false,
            timeout_ms = 3000,
        })
    end, { desc = "Format file or range" })
end

---------------------------------------------------------------------------
-- LSP (buffer-local keymaps on LspAttach)
---------------------------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
        vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to Definition" })
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = ev.buf, desc = "Hover Documentation" })
        vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, { buffer = ev.buf, desc = "Workspace Symbol" })
        vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, { buffer = ev.buf, desc = "Open Diagnostic Float" })
        vim.keymap.set("n", "[d", vim.diagnostic.goto_next, { buffer = ev.buf, desc = "Next Diagnostic" })
        vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, { buffer = ev.buf, desc = "Previous Diagnostic" })
        vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, { buffer = ev.buf, desc = "Code Action" })
        vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, { buffer = ev.buf, desc = "References" })
        vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, { buffer = ev.buf, desc = "Rename" })
        vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, { buffer = ev.buf, desc = "Signature Help" })
    end,
})

---------------------------------------------------------------------------
-- LuaSnip
---------------------------------------------------------------------------
local ls_ok, ls = pcall(require, "luasnip")
if ls_ok then
    vim.keymap.set({ "i", "s" }, "<C-k>", function()
        if ls.expand_or_jumpable() then
            ls.expand_or_jump()
        end
    end, { silent = true })

    vim.keymap.set({ "i", "s" }, "<C-j>", function()
        if ls.jumpable(-1) then
            ls.jump(-1)
        end
    end, { silent = true })
end

---------------------------------------------------------------------------
-- Opencode
---------------------------------------------------------------------------
local opencode_ok, opencode = pcall(require, "opencode")
if opencode_ok then
    vim.keymap.set({ "n", "x" }, "<leader>oa", function() opencode.ask("@this: ", { submit = true }) end, { desc = "Opencode: Ask" })
    vim.keymap.set("n", "<leader>ob", function() opencode.ask("@buffer: ", { submit = true }) end, { desc = "Opencode: Ask (Whole Buffer)" })
    vim.keymap.set("n", "<leader>ov", function() opencode.ask("@visible: ", { submit = true }) end, { desc = "Opencode: Ask (Visible Text)" })
    vim.keymap.set({ "n", "x" }, "<leader>os", function() opencode.select() end, { desc = "Opencode: Select action" })
    vim.keymap.set({ "n", "t" }, "<leader>ot", function() opencode.toggle() end, { desc = "Opencode: Toggle" })
    vim.keymap.set({ "n", "x" }, "go", function() return opencode.operator("@this ") end, { desc = "Opencode: Add range", expr = true })
    vim.keymap.set("n", "goo", function() return opencode.operator("@this ") .. "_" end, { desc = "Opencode: Add line", expr = true })
    vim.keymap.set("n", "<leader>ou", function() opencode.command("session.half.page.up") end, { desc = "Opencode: Scroll up" })
    vim.keymap.set("n", "<leader>od", function() opencode.command("session.half.page.down") end, { desc = "Opencode: Scroll down" })
end

---------------------------------------------------------------------------
-- Which-Key group labels
---------------------------------------------------------------------------
local wk_ok, wk = pcall(require, "which-key")
if wk_ok then
    wk.add({
        { "<leader>n", group = "Obsidian" },
        { "<leader>f", group = "Find (Telescope)" },
        { "<leader>?", function() wk.show() end, desc = "Show Keymaps (Which-Key)" },
    })
end
