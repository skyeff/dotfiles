-- ============================================================
-- Refinamentos residuais — cobertura de função já parcialmente
-- presente (yank nativo, ausência de realce cromático), não
-- lacuna de função inexistente como os módulos anteriores.
-- ============================================================

return {
	-- ── Realce de códigos de cor ─────────────────────────────────
	-- Relevante face à disciplina de configuração de Hyprland/kitty:
	-- valores hexadecimais em ficheiros de configuração ganham swatch
	-- inline, sem plugin equivalente até esta adição.
	{
		"brenoprata10/nvim-highlight-colors",
		event = { "BufReadPost", "BufNewFile" },
		opts = { render = "background" },
	},

	-- ── Histórico navegável de yank ───────────────────────────────
	-- Extensão natural da substituição já operada de
	-- vim-highlightedyank pelo highlight nativo: yanky.nvim adiciona
	-- um anel de histórico navegável (não apenas o registo "" mais
	-- recente), com highlight na colagem — ausente de qualquer
	-- mecanismo nativo ou do vimrc precedente.
	{
		"gbprod/yanky.nvim",
		event = "VeryLazy",
		keys = {
			{ "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" } },
			{ "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" } },
			-- Nota: <C-p> já governa Telescope find_files (telescope.lua);
			-- o ciclo de entradas de yank migra para <A-n>/<A-p>, evitando
			-- colisão de mapeamento global.
			{ "<A-p>", "<Plug>(YankyPreviousEntry)", mode = "n", desc = "Yanky: entrada anterior" },
			{ "<A-n>", "<Plug>(YankyNextEntry)", mode = "n", desc = "Yanky: entrada seguinte" },
		},
		opts = {
			highlight = { timer = 200 },
		},
	},
}
