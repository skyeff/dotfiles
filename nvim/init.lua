-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.opt.spell = false
vim.cmd("syntax off")
vim.diagnostic.config({
  virtual_text = false, -- Disables inline diagnostic messages (e.g., underlines)
  signs = true, -- Keeps signs in the gutter if you want them
  update_in_insert = true,
})
