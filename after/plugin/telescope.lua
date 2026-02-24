local status, builtin = pcall(require, 'telescope.builtin')
if not status then
    return
end

vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = 'Telescope diagnostics' })
vim.keymap.set('n', '<leader>/', builtin.current_buffer_fuzzy_find, { desc = 'Telescope fuzzy find in current buffer' })
vim.keymap.set('n', '<leader>fs', function ()
	builtin.grep_string({ search = vim.fn.input("Grep > ") });
	end
	,{ desc = 'Telescope grep string input' })
