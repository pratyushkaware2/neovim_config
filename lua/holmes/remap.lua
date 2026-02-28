-- All keymaps (global + plugin-specific)
-- Plugin declarations live in plugins.lua, setup/config lives in setup.lua.

vim.g.mapleader = " "

---------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------
vim.keymap.set("n", "<leader>e", "<Cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR>", { desc = "Clear search highlights" })
vim.keymap.set("i", "jk", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })
vim.keymap.set("n", "<leader>cR", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor" })

-- Clipboard / register helpers
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without overwriting register" })
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>x", "\"_d", { desc = "Delete without copying" })

---------------------------------------------------------------------------
-- Window / Tmux navigation
---------------------------------------------------------------------------
vim.keymap.set("n", "<C-h>", "<Cmd>TmuxNavigateLeft<CR>", { desc = "Navigate left" })
vim.keymap.set("n", "<C-j>", "<Cmd>TmuxNavigateDown<CR>", { desc = "Navigate down" })
vim.keymap.set("n", "<C-k>", "<Cmd>TmuxNavigateUp<CR>", { desc = "Navigate up" })
vim.keymap.set("n", "<C-l>", "<Cmd>TmuxNavigateRight<CR>", { desc = "Navigate right" })

-- Open tmux split in current directory
vim.keymap.set("n", "<leader>t", function()
    local cwd = vim.fn.getcwd()
    vim.fn.system("tmux split-window -v -p 30 -c " .. vim.fn.shellescape(cwd))
end, { desc = "Open tmux terminal split" })

---------------------------------------------------------------------------
-- Telescope (search)
---------------------------------------------------------------------------
local telescope_ok, builtin = pcall(require, "telescope.builtin")
if telescope_ok then
    vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
    vim.keymap.set("n", "<leader>/", builtin.live_grep, { desc = "Live grep" })
    vim.keymap.set("n", "<leader>,", builtin.buffers, { desc = "Switch buffer" })
    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
    vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "Search help" })
    vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "Search diagnostics" })
    vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "Search keymaps" })
    vim.keymap.set("n", "<leader>sb", builtin.current_buffer_fuzzy_find, { desc = "Search in buffer" })
    vim.keymap.set("n", "<leader>sw", function()
        builtin.grep_string({ search = vim.fn.input("Grep > ") })
    end, { desc = "Search word/string" })
    vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "Search resume (last picker)" })
    vim.keymap.set("n", "<leader>s\"", builtin.registers, { desc = "Search registers (yanks/deletes)" })
    vim.keymap.set("n", "<leader>gc", builtin.git_commits, { desc = "Search commits" })
    vim.keymap.set("n", "<leader>gbc", builtin.git_bcommits, { desc = "Search buffer commits" })
end

---------------------------------------------------------------------------
-- Harpoon
---------------------------------------------------------------------------
local harpoon_ok, mark = pcall(require, "harpoon.mark")
if harpoon_ok then
    local ui = require("harpoon.ui")
    vim.keymap.set("n", "<leader>a", mark.add_file, { desc = "Harpoon: Add file" })
    vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu, { desc = "Harpoon: Toggle menu" })
    vim.keymap.set("n", "<leader>1", function() ui.nav_file(1) end, { desc = "Harpoon: File 1" })
    vim.keymap.set("n", "<leader>2", function() ui.nav_file(2) end, { desc = "Harpoon: File 2" })
    vim.keymap.set("n", "<leader>3", function() ui.nav_file(3) end, { desc = "Harpoon: File 3" })
    vim.keymap.set("n", "<leader>4", function() ui.nav_file(4) end, { desc = "Harpoon: File 4" })
end

---------------------------------------------------------------------------
-- Undotree
---------------------------------------------------------------------------
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Toggle UndoTree" })

---------------------------------------------------------------------------
-- Git (Fugitive)
---------------------------------------------------------------------------
vim.keymap.set("n", "<leader>gg", vim.cmd.Git, { desc = "Git status (Fugitive)" })
vim.keymap.set("n", "<leader>gl", "<Cmd>Git log<CR>", { desc = "Git log (Fugitive)" })

---------------------------------------------------------------------------
-- Diffview (VS Code-like diff viewer)
---------------------------------------------------------------------------
vim.keymap.set("n", "<leader>gd", "<Cmd>DiffviewOpen<CR>", { desc = "Diffview: Open (working changes)" })
vim.keymap.set("n", "<leader>gD", "<Cmd>DiffviewClose<CR>", { desc = "Diffview: Close" })
vim.keymap.set("n", "<leader>gf", "<Cmd>DiffviewFileHistory %<CR>", { desc = "Diffview: File history (current)" })
vim.keymap.set("n", "<leader>gL", "<Cmd>DiffviewFileHistory<CR>", { desc = "Diffview: File history (all)" })

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
        local opts = function(desc)
            return { buffer = ev.buf, desc = desc }
        end

        -- Navigation
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
        vim.keymap.set("n", "gI", vim.lsp.buf.implementation, opts("Go to implementation"))
        vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts("Go to type definition"))
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts("Find references"))
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts("Hover documentation"))
        vim.keymap.set("n", "gK", vim.lsp.buf.signature_help, opts("Signature help"))
        vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, opts("Signature help"))

        -- Actions
        vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, opts("Rename symbol"))
        vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts("Code action"))
        vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, opts("Line diagnostics"))

        -- Workspace
        vim.keymap.set("n", "<leader>cs", vim.lsp.buf.workspace_symbol, opts("Workspace symbols"))

        -- Diagnostics navigation
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts("Next diagnostic"))
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts("Previous diagnostic"))
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
    end, { silent = true, desc = "Snippet: Expand or jump forward" })

    vim.keymap.set({ "i", "s" }, "<C-j>", function()
        if ls.jumpable(-1) then
            ls.jump(-1)
        end
    end, { silent = true, desc = "Snippet: Jump backward" })
end

---------------------------------------------------------------------------
-- Todo Comments
---------------------------------------------------------------------------
local todo_ok, todo = pcall(require, "todo-comments")
if todo_ok then
    vim.keymap.set("n", "]t", function() todo.jump_next() end, { desc = "Next todo comment" })
    vim.keymap.set("n", "[t", function() todo.jump_prev() end, { desc = "Previous todo comment" })
    vim.keymap.set("n", "<leader>st", "<Cmd>TodoTelescope<CR>", { desc = "Search todos" })
end

---------------------------------------------------------------------------
-- DAP (Debugging)
---------------------------------------------------------------------------
local dap_ok, dap = pcall(require, "dap")
if dap_ok then
    vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
    vim.keymap.set("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
    end, { desc = "Conditional breakpoint" })
    vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue / Start" })
    vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step into" })
    vim.keymap.set("n", "<leader>dO", dap.step_over, { desc = "Step over" })
    vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step out" })
    vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Run last" })
    vim.keymap.set("n", "<leader>dq", dap.terminate, { desc = "Terminate" })

    local dapui_ok, dapui = pcall(require, "dapui")
    if dapui_ok then
        vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI" })
        vim.keymap.set({ "n", "v" }, "<leader>de", dapui.eval, { desc = "Evaluate expression" })
    end
end

---------------------------------------------------------------------------
-- Opencode
---------------------------------------------------------------------------
local opencode_ok, opencode = pcall(require, "opencode")
if opencode_ok then
    vim.keymap.set({ "n", "x" }, "<leader>oa", function() opencode.ask("@this: ", { submit = true }) end, { desc = "Ask (selection)" })
    vim.keymap.set("n", "<leader>ob", function() opencode.ask("@buffer: ", { submit = true }) end, { desc = "Ask (whole buffer)" })
    vim.keymap.set("n", "<leader>ov", function() opencode.ask("@visible: ", { submit = true }) end, { desc = "Ask (visible text)" })
    vim.keymap.set({ "n", "x" }, "<leader>os", function() opencode.select() end, { desc = "Select action" })
    vim.keymap.set({ "n", "t" }, "<leader>ot", function() opencode.toggle() end, { desc = "Toggle" })
    vim.keymap.set({ "n", "x" }, "go", function() return opencode.operator("@this ") end, { desc = "Opencode: Add range", expr = true })
    vim.keymap.set("n", "goo", function() return opencode.operator("@this ") .. "_" end, { desc = "Opencode: Add line", expr = true })
    vim.keymap.set("n", "<leader>ou", function() opencode.command("session.half.page.up") end, { desc = "Scroll up" })
    vim.keymap.set("n", "<leader>od", function() opencode.command("session.half.page.down") end, { desc = "Scroll down" })
end

---------------------------------------------------------------------------
-- Which-Key group labels
---------------------------------------------------------------------------
-- Image hover (snacks.nvim) — works in leetcode and markdown buffers
---------------------------------------------------------------------------
local _img_hover = nil
local _img_hover_close = function()
    if _img_hover then
        if _img_hover.win and _img_hover.win:valid() then
            _img_hover.win:close()
        end
        _img_hover = nil
    end
end

vim.keymap.set("n", "<leader>ci", function()
    local Snacks = require("snacks")

    -- If already showing hover on this buffer, close it (toggle behavior)
    if _img_hover and _img_hover.buf == vim.api.nvim_get_current_buf() then
        _img_hover_close()
        return
    end
    _img_hover_close()

    -- First try the native snacks hover (works for markdown with treesitter)
    -- For leetcode buffers, extract the URL from the line text directly
    local line = vim.api.nvim_get_current_line()
    local src = line:match("%]%((https?://%S+)%)")
        or line:match("%(([^%)]+%.png)%)")
        or line:match("%(([^%)]+%.jpg)%)")
        or line:match("%(([^%)]+%.jpeg)%)")
        or line:match("%(([^%)]+%.gif)%)")
        or line:match("%(([^%)]+%.webp)%)")

    if not src then
        -- Fallback to snacks native hover for proper markdown buffers
        Snacks.image.hover()
        return
    end

    -- Create a floating window and render the image using snacks internals
    local win = Snacks.win(Snacks.win.resolve(Snacks.image.config.doc, "snacks_image", {
        show = false,
        enter = false,
        wo = { winblend = Snacks.image.terminal.env().placeholders and 0 or nil },
    }))
    win:open_buf()

    local updated = false
    local opts = Snacks.config.merge({}, Snacks.image.config.doc, {
        on_update_pre = function()
            if _img_hover and not updated then
                updated = true
                local loc = _img_hover.img:state().loc
                win.opts.width = loc.width
                win.opts.height = loc.height
                win:show()
            end
        end,
        inline = false,
    })

    _img_hover = {
        win = win,
        buf = vim.api.nvim_get_current_buf(),
        img = Snacks.image.placement.new(win.buf, src, opts),
    }

    -- Auto-close on cursor move, mode change, or buffer leave
    vim.api.nvim_create_autocmd({ "CursorMoved", "ModeChanged", "BufLeave" }, {
        group = vim.api.nvim_create_augroup("leetcode_image_hover", { clear = true }),
        callback = function()
            _img_hover_close()
            return true -- remove the autocmd
        end,
    })
end, { desc = "Show image under cursor" })

---------------------------------------------------------------------------
local wk_ok, wk = pcall(require, "which-key")
if wk_ok then
    wk.add({
        { "<leader>c", group = "Code" },
        { "<leader>d", group = "Debug" },
        { "<leader>f", group = "File/Find" },
        { "<leader>g", group = "Git" },
        { "<leader>gb", group = "Buffer" },
        { "<leader>gh", group = "Hunks" },
        { "<leader>gt", group = "Toggle" },
        { "<leader>o", group = "Opencode" },
        { "<leader>s", group = "Search", mode = { "n", "x" } },
        { "<leader>?", function() wk.show() end, desc = "Show all keymaps" },
    })
end
