return {

	-- ── Painel de símbolos — substitui majutsushi/tagbar ─────────
	-- tagbar dependia de ctags (heurística regex, léxico apenas);
	-- aerial consome directamente a árvore de símbolos do LSP —
	-- congruente com o AST real, não com uma aproximação textual.
	{
		"stevearc/aerial.nvim",
		cmd = "AerialToggle",
		keys = {
			{ "<leader>t", "<Cmd>AerialToggle<CR>", desc = "Símbolos (Aerial)" },
		},
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		opts = {
			backends = { "lsp", "treesitter", "markdown" },
			layout = { min_width = 28 },
			show_guides = true,
		},
	},

	-- ── Sessões — substitui o componente 'sessions' do vim-startify ──
	{
		"folke/persistence.nvim",
		event = "BufReadPre",
		opts = {},
		keys = {
			{
				"<leader>ss",
				function()
					require("persistence").save()
				end,
				desc = "Sessão: guardar",
			},
			{
				"<leader>sl",
				function()
					require("persistence").load()
				end,
				desc = "Sessão: carregar (directório actual)",
			},
			{
				"<leader>sL",
				function()
					require("persistence").load({ last = true })
				end,
				desc = "Sessão: carregar a última",
			},
		},
	},
}
