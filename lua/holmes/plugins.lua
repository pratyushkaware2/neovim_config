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
        tag = "0.1.8",
        dependencies = { "nvim-lua/plenary.nvim" },
    },

    -- Treesitter
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

    -- Navigation
    { "theprimeagen/harpoon" },
    { "christoomey/vim-tmux-navigator" },

    -- Git
    { "tpope/vim-fugitive" },
    { "lewis6991/gitsigns.nvim" },

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

    -- Completion & Snippets
    { "hrsh7th/nvim-cmp" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "L3MON4D3/LuaSnip" },

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

    -- UI
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },
    { "nvim-tree/nvim-web-devicons" },
    { "echasnovski/mini.icons", version = "*" },
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },
    {
        "3rd/image.nvim",
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
})
