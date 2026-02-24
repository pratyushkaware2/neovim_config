local mason_status, mason = pcall(require, 'mason')
if not mason_status then
    return
end

local mason_lspconfig = require('mason-lspconfig')
local lspconfig = require('lspconfig')
local cmp = require('cmp')
local cmp_lsp = require('cmp_nvim_lsp')

-- 1. Setup Mason (the package manager for LSPs/Linters)
mason.setup({})

-- 2. Setup Mason-LspConfig (bridges Mason and LspConfig)
mason_lspconfig.setup({
    ensure_installed = {
        'ts_ls',       -- JavaScript/TypeScript
        'eslint',      -- Linting for JS/TS
        'html',        -- HTML
        'cssls',       -- CSS
        'jsonls',      -- JSON
        'pyright',     -- Python
        'lua_ls',      -- Lua
        'clangd',      -- C/C++
    },
    handlers = {
        -- The default handler sets up every server in 'ensure_installed'
        function(server_name)
            lspconfig[server_name].setup({
                capabilities = cmp_lsp.default_capabilities(),
            })
        end,
        
        ['clangd'] = function()
            local capabilities = cmp_lsp.default_capabilities()
            capabilities.offsetEncoding = nil
            capabilities.positionEncodings = { 'utf-16' }
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

        ['lua_ls'] = function()
            lspconfig.lua_ls.setup({
                capabilities = cmp_lsp.default_capabilities(),
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { 'vim' },
                        },
                    },
                },
            })
        end,
    }
})

-- 3. Setup Completion (nvim-cmp)
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local ls = require("luasnip")

cmp.setup({
    snippet = {
        expand = function(args)
            ls.lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<C-Space>'] = cmp.mapping.complete(),
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' }, -- For luasnip users.
    }, {
        { name = 'buffer' },
    })
})

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

-- 4. Global LSP Keymaps (on LspAttach)
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        local opts = { buffer = ev.buf }
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to Definition" })
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = ev.buf, desc = "Hover Documentation" })
        vim.keymap.set('n', '<leader>vws', vim.lsp.buf.workspace_symbol, { buffer = ev.buf, desc = "Workspace Symbol" })
        vim.keymap.set('n', '<leader>vd', vim.diagnostic.open_float, { buffer = ev.buf, desc = "Open Diagnostic Float" })
        vim.keymap.set('n', '[d', vim.diagnostic.goto_next, { buffer = ev.buf, desc = "Next Diagnostic" })
        vim.keymap.set('n', ']d', vim.diagnostic.goto_prev, { buffer = ev.buf, desc = "Previous Diagnostic" })
        vim.keymap.set('n', '<leader>vca', vim.lsp.buf.code_action, { buffer = ev.buf, desc = "Code Action" })
        vim.keymap.set('n', '<leader>vrr', vim.lsp.buf.references, { buffer = ev.buf, desc = "References" })
        vim.keymap.set('n', '<leader>vrn', vim.lsp.buf.rename, { buffer = ev.buf, desc = "Rename" })
        vim.keymap.set('i', '<C-h>', vim.lsp.buf.signature_help, { buffer = ev.buf, desc = "Signature Help" })
    end,
})
