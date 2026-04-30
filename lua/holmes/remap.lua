-- All keymaps (global + plugin-specific)
-- Plugin declarations live in plugins.lua, setup/config lives in setup.lua.

vim.g.mapleader = " "

local function set_repeat(sequence, count)
    if vim.fn.exists("*repeat#set") == 1 then
        vim.fn["repeat#set"](sequence, count)
    end
end

local function set_repeatable_map(lhs, plug_name, rhs, opts)
    local plug = "<Plug>(" .. plug_name .. ")"
    local base_opts = vim.tbl_extend("force", { silent = true }, opts or {})

    vim.keymap.set("n", plug, function()
        rhs(vim.v.count1)
        set_repeat("\\<Plug>(" .. plug_name .. ")", vim.v.count)
    end, base_opts)

    vim.keymap.set("n", lhs, plug, vim.tbl_extend("force", base_opts, { remap = true }))
end

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
set_repeatable_map("<C-w>>", "HolmesWindowWidthIncrease", function(count)
    vim.cmd("vertical resize +" .. count)
end, { desc = "Window: Increase width" })
set_repeatable_map("<C-w><", "HolmesWindowWidthDecrease", function(count)
    vim.cmd("vertical resize -" .. count)
end, { desc = "Window: Decrease width" })
set_repeatable_map("<C-w>+", "HolmesWindowHeightIncrease", function(count)
    vim.cmd("resize +" .. count)
end, { desc = "Window: Increase height" })
set_repeatable_map("<C-w>-", "HolmesWindowHeightDecrease", function(count)
    vim.cmd("resize -" .. count)
end, { desc = "Window: Decrease height" })

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
    
    vim.keymap.set("n", "<leader>/", function()
        local ext = require("telescope").extensions
        if ext.live_grep_args then
            ext.live_grep_args.live_grep_args()
        else
            builtin.live_grep()
        end
    end, { desc = "Live grep (with args)" })
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
-- Buffers (Bufferline)
---------------------------------------------------------------------------
set_repeatable_map("<leader>bn", "HolmesBufferNext", function(count)
    for _ = 1, count do vim.cmd("BufferLineCycleNext") end
end, { desc = "Buffer: Next" })
set_repeatable_map("<leader>bp", "HolmesBufferPrev", function(count)
    for _ = 1, count do vim.cmd("BufferLineCyclePrev") end
end, { desc = "Buffer: Previous" })
vim.keymap.set("n", "<leader><Tab>", "<Plug>(HolmesBufferNext)", { remap = true, desc = "Buffer: Next" })
vim.keymap.set("n", "<leader><S-Tab>", "<Plug>(HolmesBufferPrev)", { remap = true, desc = "Buffer: Previous" })
vim.keymap.set("n", "<leader>bc", "<Cmd>BufferLinePickClose<CR>", { desc = "Buffer: Pick close" })
vim.keymap.set("n", "<leader>bb", "<Cmd>BufferLinePick<CR>", { desc = "Buffer: Pick" })


---------------------------------------------------------------------------
-- Harpoon
---------------------------------------------------------------------------
local harpoon_ok, mark = pcall(require, "harpoon.mark")
if harpoon_ok then
    local ui = require("harpoon.ui")
    vim.keymap.set("n", "<leader>ha", mark.add_file, { desc = "Harpoon: Add file" })
    vim.keymap.set("n", "<leader>hh", ui.toggle_quick_menu, { desc = "Harpoon: Toggle menu" })
    vim.keymap.set("n", "<leader>h1", function() ui.nav_file(1) end, { desc = "Harpoon: File 1" })
    vim.keymap.set("n", "<leader>h2", function() ui.nav_file(2) end, { desc = "Harpoon: File 2" })
    vim.keymap.set("n", "<leader>h3", function() ui.nav_file(3) end, { desc = "Harpoon: File 3" })
    vim.keymap.set("n", "<leader>h4", function() ui.nav_file(4) end, { desc = "Harpoon: File 4" })
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
-- Python env
---------------------------------------------------------------------------
local venv_selector_ok = pcall(require, "venv-selector")
if venv_selector_ok then
    vim.keymap.set("n", "<leader>cv", "<Cmd>VenvSelect<CR>", { desc = "Select Python virtualenv" })
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

        -- Diagnostics navigation (dot-repeatable)
        local function repeatable_buf_map(lhs, plug_name, fn, desc)
            local plug = "<Plug>(" .. plug_name .. ")"
            vim.keymap.set("n", plug, function()
                fn(vim.v.count1)
                set_repeat("\\<Plug>(" .. plug_name .. ")", vim.v.count)
            end, { buffer = ev.buf, silent = true, desc = desc })
            vim.keymap.set("n", lhs, plug, { buffer = ev.buf, remap = true, desc = desc })
        end

        repeatable_buf_map("]d", "HolmesDiagNext", function(count)
            for _ = 1, count do vim.diagnostic.goto_next() end
        end, "Next diagnostic")
        repeatable_buf_map("[d", "HolmesDiagPrev", function(count)
            for _ = 1, count do vim.diagnostic.goto_prev() end
        end, "Previous diagnostic")
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
    set_repeatable_map("]t", "HolmesTodoNext", function(count)
        for _ = 1, count do todo.jump_next() end
    end, { desc = "Next todo comment" })
    set_repeatable_map("[t", "HolmesTodoPrev", function(count)
        for _ = 1, count do todo.jump_prev() end
    end, { desc = "Previous todo comment" })
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
    set_repeatable_map("<leader>di", "HolmesDapStepInto", function()
        dap.step_into()
    end, { desc = "Step into" })
    set_repeatable_map("<leader>dO", "HolmesDapStepOver", function()
        dap.step_over()
    end, { desc = "Step over" })
    set_repeatable_map("<leader>do", "HolmesDapStepOut", function()
        dap.step_out()
    end, { desc = "Step out" })
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
    set_repeatable_map("<leader>ou", "HolmesOpencodeHalfPageUp", function(count)
        for _ = 1, count do
            opencode.command("session.half.page.up")
        end
    end, { desc = "Scroll up" })
    set_repeatable_map("<leader>od", "HolmesOpencodeHalfPageDown", function(count)
        for _ = 1, count do
            opencode.command("session.half.page.down")
        end
    end, { desc = "Scroll down" })
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
        { "<leader>b", group = "Buffer" },
        { "<leader>c", group = "Code" },
        { "<leader>d", group = "Debug" },
        { "<leader>f", group = "File/Find" },
        { "<leader>g", group = "Git" },
        { "<leader>gb", group = "Buffer" },
        { "<leader>gh", group = "Hunks" },
        { "<leader>gt", group = "Toggle" },
        { "<leader>h", group = "Harpoon" },
        { "<leader>o", group = "Opencode" },
        { "<leader>s", group = "Search", mode = { "n", "x" } },
        { "<leader>?", function() wk.show() end, desc = "Show all keymaps" },
    })
end
