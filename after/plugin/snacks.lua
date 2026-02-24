local status, snacks = pcall(require, "snacks")
if not status then
    return
end

snacks.setup({
    input = {},
    picker = {},
    terminal = {}
})