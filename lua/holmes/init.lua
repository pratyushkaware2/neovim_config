require("holmes.set")
require("holmes.plugins")
require("holmes.setup")
require("holmes.remap")
-- Last: wraps whatever vim.paste ends up being after plugins have loaded.
require("holmes.paste").setup()
