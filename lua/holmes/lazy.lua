local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.8',
        dependencies = { { 'nvim-lua/plenary.nvim' } }
    },

    { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },
    { 'theprimeagen/harpoon' },
    { 'mbbill/undotree' },
    { 'tpope/vim-fugitive' },
    { 'xero/miasma.nvim' },
    { 'folke/tokyonight.nvim' },
    { 'rebelot/kanagawa.nvim' },
    { 'ellisonleao/gruvbox.nvim' },

    {
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        'neovim/nvim-lspconfig',
    },

    {
        'hrsh7th/nvim-cmp',
        'hrsh7th/cmp-nvim-lsp',
        'L3MON4D3/LuaSnip',
    },

    {
        'stevearc/conform.nvim',
        config = function()
            require("conform").setup()
        end,
    },

    {
        'lewis6991/gitsigns.nvim',
        config = function()
            require('gitsigns').setup()
        end
    },

    {
        "NickvanDyke/opencode.nvim",
        dependencies = {
            { "folke/snacks.nvim" }
        }
    },

    {
        "kawre/leetcode.nvim",
        build = ":TSUpdate html",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "MunifTanjim/nui.nvim",
        }
    },

    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' }
    },

    { 'nvim-tree/nvim-web-devicons' },

    {
        'MeanderingProgrammer/render-markdown.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require('render-markdown').setup({
                file_types = { "markdown", "leetcode" },
            })
        end,
    },

    {
        "3rd/image.nvim",
        config = function()
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
    },

    {
        "folke/noice.nvim",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "rcarriga/nvim-notify",
        }
    },

    {
        "folke/which-key.nvim",
        config = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
            require("which-key").setup {}
        end
    },

    {
        "epwalsh/obsidian.nvim",
        version = "*", -- recommended, use latest release instead of latest commit
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
    },

    { 'christoomey/vim-tmux-navigator' },

    {
        "nvim-tree/nvim-tree.lua",
        version = "*",
        lazy = false,
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
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
        end,
    }
})
