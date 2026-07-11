return {
	{
		"MagicDuck/grug-far.nvim",
		cmd = "GrugFar",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			-- Abre o painel de substituição, âmbito: directório do projecto
			{
				"<leader>sr",
				function()
					require("grug-far").open({ transient = true })
				end,
				desc = "Substituir (projecto)",
			},
			-- Pré-popula a busca com a palavra sob o cursor
			{
				"<leader>sw",
				function()
					require("grug-far").open({
						transient = true,
						prefills = { search = vim.fn.expand("<cword>") },
					})
				end,
				desc = "Substituir palavra sob o cursor",
			},
			-- Âmbito restrito ao buffer corrente, não ao projecto inteiro
			{
				"<leader>sb",
				function()
					require("grug-far").open({
						transient = true,
						prefills = { paths = vim.fn.expand("%") },
					})
				end,
				desc = "Substituir (buffer actual)",
			},
		},
		opts = {
			-- engine "ripgrep" é a omissão; explicitada por legibilidade
			engine = "ripgrep",
			windowCreationCommand = "vsplit",
		},
	},
}
