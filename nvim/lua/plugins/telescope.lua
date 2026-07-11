return {
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				-- Sorter fuzzy em C compilado — a paridade de latência com
				-- fzf binário nativo depende inteiramente desta dependência;
				-- requer `make` disponível no PATH.
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
		},
		keys = {
			{ "<C-p>", "<Cmd>Telescope find_files<CR>", desc = "Ficheiros (projecto)" },
			{
				"<leader>fa",
				function()
					require("telescope.builtin").find_files({
						hidden = true,
						no_ignore = true,
						find_command = { "fd", "--type", "f", "--hidden", "--no-ignore", "--follow" },
					})
				end,
				desc = "Ficheiros (sistema inteiro, sem filtro)",
			},
			{ "<leader>b", "<Cmd>Telescope buffers<CR>", desc = "Buffers abertos" },
			{ "<leader>r", "<Cmd>Telescope live_grep<CR>", desc = "Pesquisa de conteúdo (ripgrep)" },
			{ "<leader>l", "<Cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Linhas do buffer actual" },
			{ "<leader>/", "<Cmd>Telescope grep_string<CR>", desc = "Pesquisar palavra sob o cursor" },
			{ "<leader>:", "<Cmd>Telescope command_history<CR>", desc = "Histórico de comandos" },
			{ "<leader>m", "<Cmd>Telescope marks<CR>", desc = "Marks" },
			{ "<leader>fo", "<Cmd>Telescope oldfiles<CR>", desc = "Ficheiros recentes" },
			{ "<leader>fh", "<Cmd>Telescope help_tags<CR>", desc = "Documentação (:help)" },
		},
		opts = {
			defaults = {
				prompt_prefix = "  ",
				selection_caret = " ",
				sorting_strategy = "ascending",
				layout_config = {
					prompt_position = "top",
					width = 0.85,
					height = 0.70,
				},
				mappings = {
					i = { ["<C-j>"] = "move_selection_next", ["<C-k>"] = "move_selection_previous" },
				},
			},
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
			},
		},
		config = function(_, opts)
			local telescope = require("telescope")
			telescope.setup(opts)
			telescope.load_extension("fzf")
		end,
	},
}
