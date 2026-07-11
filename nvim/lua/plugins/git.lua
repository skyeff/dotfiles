return {

	-- ── Neogit — substitui vim-fugitive ──────────────────────────
	-- fugitive despachava comandos Git como texto (:Git commit,
	-- :Git push), transacção isolada a cada invocação, sem estado
	-- próprio. Neogit mantém um buffer de status persistente e
	-- interactivo — staging por hunk ou por ficheiro, rebase
	-- interactivo, popups de commit/push/pull com a totalidade das
	-- flags do Git expostas —, congruente com a completude de um
	-- cliente nativo (linhagem directa de magit), não com um mero
	-- invólucro de despacho.
	{
		"NeogitOrg/neogit",
		cmd = "Neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		keys = {
			{ "<leader>gs", function() require("neogit").open() end, desc = "Git: status (Neogit)" },
			{ "<leader>gc", function() require("neogit.popups.commit").create() end, desc = "Git: commit" },
			{ "<leader>gp", function() require("neogit.popups.push").create() end, desc = "Git: push" },
			{ "<leader>gl", function() require("neogit").open({ "log" }) end, desc = "Git: log" },
		},
		opts = {},
	},

	-- ── Diffview — visualizador de diferenças dedicado ───────────
	-- Gdiffsplit expunha uma comparação binária de duas colunas;
	-- diffview.nvim compõe um painel lateral de ficheiros alterados,
	-- navegável, com histórico por ficheiro via
	-- :DiffviewFileHistory — substitui simultaneamente Gdiffsplit
	-- e a função de :Git blame por uma camada de cobertura superior.
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewFileHistory" },
		keys = {
			{ "<leader>gd", "<Cmd>DiffviewOpen<CR>", desc = "Git: diff (painel completo)" },
			{ "<leader>gb", "<Cmd>DiffviewFileHistory %<CR>", desc = "Git: histórico do ficheiro" },
		},
		opts = {},
	},

	-- ── Gitsigns — substitui vim-gitgutter ───────────────────────
	-- Sinais actualizados via libuv (assíncrono nativo); gitgutter
	-- dependia de invocações shell síncronas por hunk.
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "▁" },
				topdelete = { text = "▔" },
				changedelete = { text = "▎" },
			},
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns
				local function map(mode, l, r, desc)
					vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
				end
				map("n", "]h", gs.next_hunk, "Hunk seguinte")
				map("n", "[h", gs.prev_hunk, "Hunk anterior")
				map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
				map("n", "<leader>hu", gs.reset_hunk, "Undo hunk")
				map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
			end,
		},
	},
}
