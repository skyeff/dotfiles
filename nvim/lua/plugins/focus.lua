-- ============================================================
-- Atenuação periférica — folke/zen-mode + folke/twilight, mesma
-- autoria de snacks.nvim/which-key/trouble/flash/persistence já
-- presentes na árvore, congruência de manutenção não fortuita.
-- Relevância directa para sessões de composição LaTeX densa e
-- para a exigência declarada de "estética compacta e organizada".
-- ============================================================

return {
	{
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		keys = {
			{ "<leader>z", "<Cmd>ZenMode<CR>", desc = "Zen: composição isolada" },
		},
		opts = {
			window = {
				width = 0.85,
				options = { number = false, relativenumber = false, signcolumn = "no" },
			},
		},
	},

	{
		"folke/twilight.nvim",
		cmd = "Twilight",
		opts = { dimming = { alpha = 0.35 }, context = 12 },
	},
}
