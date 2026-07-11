-- ============================================================
-- Bootstrap do lazy.nvim — equivalente funcional a plug#begin/end,
-- porém com lazy-loading nativo (plugins carregam sob evento,
-- comando, ft ou tecla — não no arranque), lockfile determinístico
-- (lazy-lock.json) e perfilagem de arranque integrada (:Lazy profile).
-- ============================================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
	install = { colorscheme = { "everforest" } },
	checker = { enabled = true, notify = false }, -- verifica actualizações em fundo, sem notificação intrusiva
	change_detection = { notify = false },
	performance = {
		rtp = {
			-- Desactiva plugins nativos irrelevantes ao fluxo de trabalho —
			-- reduz o tempo de arranque de forma mensurável.
			disabled_plugins = {
				"gzip",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
				"netrwPlugin",
			},
		},
	},
})
