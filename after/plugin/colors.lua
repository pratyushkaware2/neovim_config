function ColorMyPencils(color)
    color = color or "gruvbox"
    vim.opt.background = "dark"
    pcall(vim.cmd.colorscheme, color)

    vim.api.nvim_set_hl(0, "NotifyBackground", { link = "Normal" })
end

ColorMyPencils()
