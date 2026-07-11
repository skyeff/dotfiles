return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		cmd = "Neotree",
		keys = {
			{ "<leader>e", "<Cmd>Neotree toggle reveal<CR>", desc = "Explorador: toggle cirúrgico" },
			{ "<leader>E", "<Cmd>Neotree show reveal=true<CR>", desc = "Explorador: manter visível sem tomar foco" },
			{ "<leader>ge", "<Cmd>Neotree focus<CR>", desc = "Explorador: saltar foco para a árvore" },
		},
		opts = {
			close_if_last_window = true, -- substitui o augroup nerdtree_autoclose manual
			window = { width = 28, mapping_options = { noremap = true } },
			filesystem = {
				filtered_items = {
					visible = true, -- mostra ocultos por omissão (equivalente a NERDTreeShowHidden)
					hide_dotfiles = false,
					hide_gitignored = false,
					never_show = { ".git", "__pycache__", "*.pyc", ".DS_Store" },
				},
				follow_current_file = { enabled = true },
				use_libuv_file_watcher = true, -- refresco por evento do SO, não por polling
			},
			default_component_configs = {
				indent = { with_expanders = true, expander_collapsed = "▸", expander_expanded = "▾" },
				git_status = {
					symbols = {
						added = "✚",
						modified = "●",
						deleted = "✖",
						renamed = "➜",
						untracked = "?",
						ignored = "",
						unstaged = "○",
						staged = "✓",
						conflict = "!",
					},
				},
			},
		},
	},
}
