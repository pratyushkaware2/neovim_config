require("obsidian").setup({
  workspaces = {
    {
      name = "personal",
      path = "~/Documents/Obsidian Vault",
    },
  },

  -- Optional, if you keep notes in a specific subdirectory in your vault.
  notes_subdir = "notes",

  -- Optional, customize how daily notes are created.
  daily_notes = {
    folder = "notes/dailies",
    date_format = "%Y-%m-%d",
    alias_format = "%B %-d, %Y",
    default_tags = { "daily-notes" },
    template = nil
  },

  -- Optional, completion configuration.
  completion = {
    nvim_cmp = true,
    min_chars = 2,
  },

  -- Optional, configure key mappings. These are the default ones from the README.
  mappings = {
    -- Overrides the 'gf' mapping to work with obsidian.nvim for opening links.
    ["gf"] = {
      action = function()
        return require("obsidian").util.gf_passthrough()
      end,
      opts = { noremap = false, expr = true, buffer = true },
    },
    -- Toggle check-boxes.
    ["<leader>ch"] = {
      action = function()
        return require("obsidian").util.toggle_checkbox()
      end,
      opts = { buffer = true },
    },
    -- Smart action depending on context, e.g. follow link, URL, or toggle checkbox.
    ["<cr>"] = {
      action = function()
        return require("obsidian").util.smart_action()
      end,
      opts = { buffer = true, expr = true },
    }
  },

  -- Optional, customize how names/links for new notes are created.
  preferred_link_style = "wiki",

  -- Optional, customize the appearance of UI elements.
  ui = {
    enable = true,
    update_debounce = 200,
  },
})
