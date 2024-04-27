-- bootstrap lazy.nvim, LazyVim and your plugins
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.backspace = { "start", "eol", "indent" }
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = false
vim.opt.wrapscan = false
vim.opt.shiftround = true
vim.opt.showmatch = true
require("config.lazy")
