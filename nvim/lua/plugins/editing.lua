return {

	-- ── Surround — substitui tpope/vim-surround ──────────────────
	-- Reimplementação em Lua puro; elimina a latência de despacho
	-- Vimscript por operador (cs, ds, ys idênticos ao original).
	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		opts = {},
	},

	-- ── Comentários — substitui tpope/vim-commentary ─────────────
	{
		"numToStr/Comment.nvim",
		event = "VeryLazy",
		opts = {},
	},

	-- ── Pares automáticos — substitui jiangmiao/auto-pairs ───────
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},

	-- ── Indentação PEP8 para Python — invariante face ao vimrc ───
	{ "Vimjas/vim-python-pep8-indent", ft = "python" },

	-- ── Detecção automática de indentação — invariante ───────────
	{ "tpope/vim-sleuth", event = "BufReadPre" },

	-- ── Iluminação de referências sob o cursor — invariante ──────
	{
		"RRethy/vim-illuminate",
		event = "BufReadPost",
		config = function()
			require("illuminate").configure({
				delay = 250,
				filetypes_denylist = { "neo-tree", "TelescopePrompt", "dashboard", "snacks_terminal" },
			})
		end,
	},

	-- ── Motion — substitui unblevable/quick-scope, superconjunto ──
	-- quick-scope realçava apenas os alvos de f/F/t/T. flash.nvim
	-- preserva esse comportamento (via char actions) e acrescenta
	-- salto rotulado (`s`) para qualquer ponto visível no ecrã —
	-- torna 2-3 teclas de motion (ex.: 12j, /padrão<CR>) redundantes
	-- para a maioria das travessias curtas.
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{ "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash: saltar" },
			{ "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash: nó sintáctico" },
		},
	},

	-- ── Realce de comentários TODO/FIXME/NOTE — sem equivalente ──
	{
		"folke/todo-comments.nvim",
		event = "BufReadPost",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
	},

	-- ── Fecho inteligente de buffers auxiliares — ver lua/plugins/ui.lua ──
	-- A responsabilidade migrou para o módulo `bufdelete` de snacks.nvim,
	-- consolidando-se na suite já presente em vez de subsistir como
	-- dependência satélite de propósito singular.
}
