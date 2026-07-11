return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		main = "nvim-treesitter.configs",
		opts = {
			ensure_installed = {
				"python", "c", "cpp", "lua", "vim", "vimdoc", "bash",
				"markdown", "markdown_inline", "json", "yaml",
				"toml", "query", "regex", "latex", "commonlisp",
			},
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<CR>",
					node_incremental = "<CR>",
					scope_incremental = "<S-CR>",
					node_decremental = "<BS>",
				},
			},
		},
	},

	-- ── Objectos de texto sintácticos — extensão sem equivalente vim ──
	-- `dif`/`daf` (function), `dic`/`dac` (class) operam sobre a árvore
	-- sintáctica real, não sobre heurística de indentação/chavetas.
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("nvim-treesitter.configs").setup({
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
						keymaps = {
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
						},
					},
				},
			})
		end,
	},

	-- ── Contexto persistente — sem equivalente no vimrc ──────────
	-- Fixa a assinatura da função/classe/ambiente envolvente no topo
	-- do viewport durante deslocação vertical extensa — aplicável
	-- tanto à navegação de código quanto a documentos LaTeX de
	-- estrutura profunda (secções, ambientes aninhados).
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = { max_lines = 3, multiline_threshold = 1 },
	},
}
