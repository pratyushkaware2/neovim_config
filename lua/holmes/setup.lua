-- Plugin setup/configuration
-- All plugin .setup() calls and configuration logic lives here.
-- Keymaps live in remap.lua, plugin declarations live in plugins.lua.

---------------------------------------------------------------------------
-- Colorscheme
---------------------------------------------------------------------------
function ColorMyPencils(color)
    color = color or "gruvbox"
    vim.opt.background = "dark"
    pcall(vim.cmd.colorscheme, color)
    vim.api.nvim_set_hl(0, "NotifyBackground", { link = "Normal" })
end

ColorMyPencils()

---------------------------------------------------------------------------
-- Treesitter
---------------------------------------------------------------------------
local ts_ok, ts_configs = pcall(require, "nvim-treesitter.configs")
if ts_ok then
    ts_configs.setup({
        ensure_installed = {
            "cpp", "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "diff",
            "javascript", "typescript", "html", "css", "python", "regex", "bash", "latex", "yaml",
        },
        sync_install = false,
        auto_install = true,
        ignore_install = {},
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
        },
    })
end

---------------------------------------------------------------------------
-- Mason + LSP + Completion
---------------------------------------------------------------------------
local mason_ok, mason = pcall(require, "mason")
if mason_ok then
    local mason_lspconfig = require("mason-lspconfig")
    local lspconfig = require("lspconfig")
    local cmp = require("cmp")
    local cmp_lsp = require("cmp_nvim_lsp")
    local ls = require("luasnip")

    -- Mason
    mason.setup({})

    -- Mason-LspConfig
    mason_lspconfig.setup({
        ensure_installed = {
            "ts_ls",
            "eslint",
            "html",
            "cssls",
            "jsonls",
            "pyright",
            "lua_ls",
            "clangd",
        },
        handlers = {
            function(server_name)
                lspconfig[server_name].setup({
                    capabilities = cmp_lsp.default_capabilities(),
                })
            end,

            ["clangd"] = function()
                local capabilities = cmp_lsp.default_capabilities()
                capabilities.offsetEncoding = nil
                capabilities.positionEncodings = { "utf-16" }
                local clangd_path = "/opt/homebrew/opt/llvm/bin/clangd"
                if vim.fn.executable(clangd_path) ~= 1 then
                    clangd_path = "clangd"
                end
                lspconfig.clangd.setup({
                    capabilities = capabilities,
                    cmd = {
                        clangd_path,
                        "--background-index",
                        "--clang-tidy",
                        "--header-insertion=never",
                        "--completion-style=detailed",
                        "--function-arg-placeholders",
                        "--fallback-style=llvm",
                        "--all-scopes-completion",
                        "--completion-limit=0",
                        "--query-driver=/usr/bin/clang++,/usr/bin/g++,/opt/homebrew/bin/g++*",
                    },
                    init_options = {
                        fallbackFlags = {
                            "-std=c++20",
                            "-x", "c++",
                            "-isysroot", "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk",
                        },
                    },
                })
            end,

            ["lua_ls"] = function()
                lspconfig.lua_ls.setup({
                    capabilities = cmp_lsp.default_capabilities(),
                    settings = {
                        Lua = {
                            diagnostics = {
                                globals = { "vim" },
                            },
                        },
                    },
                })
            end,
        },
    })

    -- Completion (nvim-cmp)
    local cmp_select = { behavior = cmp.SelectBehavior.Select }

    cmp.setup({
        snippet = {
            expand = function(args)
                ls.lsp_expand(args.body)
            end,
        },
        mapping = cmp.mapping.preset.insert({
            ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
            ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
            ["<C-y>"] = cmp.mapping.confirm({ select = true }),
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ["<C-Space>"] = cmp.mapping.complete(),
        }),
        sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "luasnip" },
        }, {
            { name = "buffer" },
        }),
    })
end

---------------------------------------------------------------------------
-- Conform (Formatting)
---------------------------------------------------------------------------
local conform_ok, conform = pcall(require, "conform")
if conform_ok then
    conform.setup({
        formatters_by_ft = {
            javascript = { "prettier" },
            typescript = { "prettier" },
            javascriptreact = { "prettier" },
            typescriptreact = { "prettier" },
            svelte = { "prettier" },
            css = { "prettier" },
            html = { "prettier" },
            json = { "prettier" },
            yaml = { "prettier" },
            markdown = { "prettier" },
            graphql = { "prettier" },
            python = { "isort", "black" },
            lua = { "stylua" },
        },
        format_on_save = {
            lsp_fallback = true,
            async = false,
            timeout_ms = 3000,
        },
    })
end

---------------------------------------------------------------------------
-- Gitsigns
---------------------------------------------------------------------------
local gitsigns_ok, gitsigns = pcall(require, "gitsigns")
if gitsigns_ok then
    gitsigns.setup({
        on_attach = function(bufnr)
            local gs = package.loaded.gitsigns

            local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
            end

            -- Navigation
            map("n", "]c", function()
                if vim.wo.diff then return "]c" end
                vim.schedule(function() gs.next_hunk() end)
                return "<Ignore>"
            end, { expr = true, desc = "Git: Next hunk" })

            map("n", "[c", function()
                if vim.wo.diff then return "[c" end
                vim.schedule(function() gs.prev_hunk() end)
                return "<Ignore>"
            end, { expr = true, desc = "Git: Previous hunk" })

            -- Actions
            map("n", "<leader>hs", gs.stage_hunk, { desc = "Git: Stage hunk" })
            map("n", "<leader>hr", gs.reset_hunk, { desc = "Git: Reset hunk" })
            map("v", "<leader>hs", function() gs.stage_hunk { vim.fn.line("."), vim.fn.line("v") } end, { desc = "Git: Stage hunk (visual)" })
            map("v", "<leader>hr", function() gs.reset_hunk { vim.fn.line("."), vim.fn.line("v") } end, { desc = "Git: Reset hunk (visual)" })
            map("n", "<leader>hS", gs.stage_buffer, { desc = "Git: Stage buffer" })
            map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Git: Undo stage hunk" })
            map("n", "<leader>hp", gs.preview_hunk, { desc = "Git: Preview hunk" })
            map("n", "<leader>hb", function() gs.blame_line { full = true } end, { desc = "Git: Blame line" })
            map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "Git: Toggle blame line" })
            map("n", "<leader>hd", gs.diffthis, { desc = "Git: Diff this" })
            map("n", "<leader>hD", function() gs.diffthis("~") end, { desc = "Git: Diff this (HEAD)" })
            map("n", "<leader>td", gs.toggle_deleted, { desc = "Git: Toggle deleted" })
        end,
    })
end

---------------------------------------------------------------------------
-- Snacks (opencode dependency)
---------------------------------------------------------------------------
local snacks_ok, snacks = pcall(require, "snacks")
if snacks_ok then
    snacks.setup({
        input = { enabled = true },
        picker = { enabled = true },
        terminal = { enabled = true },
    })
end

---------------------------------------------------------------------------
-- Opencode
---------------------------------------------------------------------------
local opencode_ok = pcall(require, "opencode")
if opencode_ok then
    vim.g.opencode_opts = {}
    vim.o.autoread = true
end

---------------------------------------------------------------------------
-- LeetCode
---------------------------------------------------------------------------
local leetcode_ok = pcall(require, "leetcode")
if leetcode_ok then
    require("leetcode").setup({
        image_support = true,
    })
end

---------------------------------------------------------------------------
-- Lualine
---------------------------------------------------------------------------
local lualine_ok = pcall(require, "lualine")
if lualine_ok then
    require("lualine").setup({
        options = {
            icons_enabled = true,
            theme = "auto",
            component_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
            disabled_filetypes = { statusline = {}, winbar = {} },
            ignore_focus = {},
            always_divide_middle = true,
            globalstatus = false,
            refresh = { statusline = 1000, tabline = 1000, winbar = 1000 },
        },
        sections = {
            lualine_a = { "mode" },
            lualine_b = { "branch", "diff", "diagnostics" },
            lualine_c = { "filename" },
            lualine_x = { "encoding", "fileformat", "filetype" },
            lualine_y = { "progress" },
            lualine_z = { "location" },
        },
        inactive_sections = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = { "filename" },
            lualine_x = { "location" },
            lualine_y = {},
            lualine_z = {},
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {},
    })
end

---------------------------------------------------------------------------
-- Render Markdown
---------------------------------------------------------------------------
local rmd_ok = pcall(require, "render-markdown")
if rmd_ok then
    require("render-markdown").setup({
        file_types = { "markdown", "leetcode" },
    })
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "leetcode" },
        callback = function()
            vim.treesitter.start()
        end,
    })
end

---------------------------------------------------------------------------
-- Image.nvim
---------------------------------------------------------------------------
local image_ok = pcall(require, "image")
if image_ok then
    require("image").setup({
        backend = "kitty",
        max_width = 100,
        max_height = 12,
        max_height_window_percentage = math.huge,
        max_width_window_percentage = math.huge,
        window_overlap_clear_enabled = true,
        window_overlap_clear_ft_ignore = {},
    })
end

---------------------------------------------------------------------------
-- Noice
---------------------------------------------------------------------------
local noice_ok = pcall(require, "noice")
if noice_ok then
    require("noice").setup({
        lsp = {
            override = {
                ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                ["vim.lsp.util.stylize_markdown"] = true,
                ["cmp.entry.get_documentation"] = true,
            },
        },
        presets = {
            bottom_search = true,
            command_palette = true,
            long_message_to_split = true,
            inc_rename = false,
            lsp_doc_border = false,
        },
    })
end

---------------------------------------------------------------------------
-- Notify
---------------------------------------------------------------------------
local notify_ok, notify = pcall(require, "notify")
if notify_ok then
    notify.setup({
        background_colour = "#000000",
    })
    vim.notify = notify
end

---------------------------------------------------------------------------
-- Which-Key
---------------------------------------------------------------------------
local wk_ok = pcall(require, "which-key")
if wk_ok then
    vim.o.timeout = true
    vim.o.timeoutlen = 300
    require("which-key").setup({})
end

---------------------------------------------------------------------------
-- NvimTree
---------------------------------------------------------------------------
local nvimtree_ok = pcall(require, "nvim-tree")
if nvimtree_ok then
    require("nvim-tree").setup({
        sort_by = "case_sensitive",
        view = {
            width = 30,
            side = "left",
        },
        renderer = {
            group_empty = true,
        },
        filters = {
            dotfiles = false,
        },
    })
end
