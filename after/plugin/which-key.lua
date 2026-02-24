local status, wk = pcall(require, "which-key")
if not status then
    return
end

wk.add({
  { "<leader>n", group = "Obsidian" },
  { "<leader>f", group = "Find (Telescope)" },
  { "<leader>?", function() wk.show() end, desc = "Show Keymaps (Which-Key)" },
})
