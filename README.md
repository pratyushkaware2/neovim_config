# Neovim Configuration

A personal Neovim configuration built with Lua, featuring a modern development environment with LSP, Treesitter, and Telescope.

## Prerequisites

Ensure you have the following installed on your system:

- **Neovim** (v0.8.0 or higher)
- **Git**
- **Ripgrep** (required for Telescope `live_grep`)
- **fd** (recommended for Telescope `find_files`)
- **C Compiler** (gcc/clang) for Treesitter parsers
- **Node.js & npm** (required for many LSPs via Mason)
- **Python 3** (required for some LSPs)
- **pngpaste** (required for `:ObsidianPasteImg` on macOS)

## Installation

### 1. Clone the Configuration

Clone this repository into your Neovim configuration directory:

```bash
git clone https://github.com/<username>2/neovim_config.git ~/.config/nvim
```

### 2. Launch Neovim

This configuration uses [lazy.nvim](https://github.com/folke/lazy.nvim) as the plugin manager. It will automatically bootstrap itself and install all plugins on the first launch.

```bash
nvim
```

## Key Features

- **Plugin Manager**: [lazy.nvim](https://github.com/folke/lazy.nvim)
- **File Explorer**: [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) for a VS Code-like sidebar.
- **Tmux Integration**: Seamless navigation between Neovim panes and Tmux panes using [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator).
- **LSP Support**: Managed via [mason.nvim](https://github.com/williamboman/mason.nvim) and `nvim-lspconfig`.
- **Fuzzy Finding**: [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- **Syntax Highlighting**: [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- **Completion**: [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) with snippets support.
- **Git Integration**: [vim-fugitive](https://github.com/tpope/vim-fugitive) and [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim).
- **UI Enhancements**: Lualine, Noice, Which-key, and Web-devicons.
- **Productivity**: Harpoon, Undotree, [Obsidian.nvim](https://github.com/epwalsh/obsidian.nvim), [image.nvim](https://github.com/3rd/image.nvim), [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim), and [leetcode.nvim](https://github.com/kawre/leetcode.nvim).

## Custom Keymaps

Notable keybindings:

- `<leader>e`: Toggle **nvim-tree** sidebar
- `<leader>fv`: Toggle **Netrw** sidebar (Lexplore)
- `<C-h/j/k/l>`: Navigate between **Neovim/Tmux** panes
- `<leader>ff`: Find files (Telescope)
- `<leader>fg`: Live grep (Telescope)
- `<leader>u`: Toggle Undotree
- `gd`: Go to definition
- `K`: Hover documentation

Check `lua/holmes/remap.lua` for a complete list of custom keybindings.
