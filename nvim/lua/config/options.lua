-- ── Definições base ──────────────────────────────────────────
-- Equivalente directo do bloco "Definições base" do _vimrc.
-- nocompatible, encoding=utf-8 e fileencoding=utf-8 são omissão
-- em Neovim — não requerem declaração.

local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.wrap = true
opt.linebreak = true
opt.wrapmargin = 0
opt.textwidth = 0

opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

opt.laststatus = 3          -- statusline global única (substitui a por-janela; lualine assume o papel)
opt.showtabline = 2          -- tabline sempre visível (bufferline.nvim)
opt.showmode = false
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 4
opt.cursorline = true
opt.colorcolumn = "100"
opt.showcmd = true
opt.wildmenu = true
opt.wildmode = "longest:full,full"
opt.splitright = true
opt.splitbelow = true
opt.hidden = true
opt.updatetime = 300
opt.timeoutlen = 400        -- latência de which-key; ausente do vimrc original
opt.shortmess:append("c")
opt.shortmess:remove("S")
opt.backspace = { "indent", "eol", "start" }
opt.pumheight = 12
opt.mouse = "a"

opt.list = true
opt.listchars = {
	tab = "→ ",
	trail = "·",
	nbsp = "⎵",
	extends = "›",
	precedes = "‹",
}

opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.fn.stdpath("state") .. "/undodir"

opt.termguicolors = true

opt.completeopt = { "menu", "menuone", "noselect" } -- requerido por nvim-cmp

-- ── Tema Moonfly ─────────────────────────────────────────────
vim.g.moonflyItalics = true
vim.g.moonflyTransparent = true
vim.g.moonflyUndercurls = true
vim.g.moonflyVirtualTextColor = true
opt.background = "dark"

-- Directórios persistentes (equivalente às chamadas mkdir do vimrc)
local undodir = vim.fn.stdpath("state") .. "/undodir"
if vim.fn.isdirectory(undodir) == 0 then
	vim.fn.mkdir(undodir, "p", "0700")
end
