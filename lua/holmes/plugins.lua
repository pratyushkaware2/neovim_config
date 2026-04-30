-- Plugin declarations (lazy.nvim)
-- This file only declares plugins and their dependencies.
-- All setup/config lives in setup.lua, all keymaps live in remap.lua.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- Telescope
    {
        "nvim-telescope/telescope.nvim",
        branch = "master",
        dependencies = { 
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope-live-grep-args.nvim",
        },
    },

    -- Treesitter
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    { "andymass/vim-matchup" },

    -- Navigation
    { "theprimeagen/harpoon" },
    { "christoomey/vim-tmux-navigator" },

    -- Git
    { "tpope/vim-fugitive" },
    { "lewis6991/gitsigns.nvim" },
    { "sindrets/diffview.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

    -- Undo
    { "mbbill/undotree" },

    -- Colorschemes
    { "ellisonleao/gruvbox.nvim" },
    { "xero/miasma.nvim" },
    { "folke/tokyonight.nvim" },
    { "rebelot/kanagawa.nvim" },

    -- LSP
    { "williamboman/mason.nvim" },
    { "williamboman/mason-lspconfig.nvim" },
    { "neovim/nvim-lspconfig" },
    { "linux-cultist/venv-selector.nvim" },

    -- Completion & Snippets
    { "hrsh7th/nvim-cmp" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "L3MON4D3/LuaSnip", build = "make install_jsregexp" },

    -- Editing
    { "echasnovski/mini.surround", version = "*" },
    { "tpope/vim-repeat" },
    {
        "m4xshen/hardtime.nvim",
        dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    },
    {
        "akinsho/bufferline.nvim",
        version = "*",
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },

    -- Formatting
    { "stevearc/conform.nvim" },

    -- AI
    {
        "NickvanDyke/opencode.nvim",
        dependencies = {
            {
                "folke/snacks.nvim",
                lazy = false,
                priority = 1000,
            },
        },
    },

    -- LeetCode
    {
        "kawre/leetcode.nvim",
        build = ":TSUpdate html",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "MunifTanjim/nui.nvim",
        },
    },

    -- Todo
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
    },

    -- Debugging
    { "mfussenegger/nvim-dap" },
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    },
    { "nvim-neotest/nvim-nio" },

    -- UI
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },
    { "NStefan002/screenkey.nvim", version = "*" },
    { "nvim-tree/nvim-web-devicons" },
    { "echasnovski/mini.icons", version = "*" },
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },

    {
        "folke/noice.nvim",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "rcarriga/nvim-notify",
        },
    },
    { "folke/which-key.nvim" },

    -- File explorer
    {
        "nvim-tree/nvim-tree.lua",
        version = "*",
        lazy = false,
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },
}, { rocks = { enabled = false } })
