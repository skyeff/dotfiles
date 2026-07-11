return {

	-- ── Tema — Moonfly ───────────────────────────────────────────
	{
		"bluz71/vim-moonfly-colors",
		name = "moonfly",
		lazy = false,
		priority = 1000, -- carrega antes de qualquer outro plugin de UI
		config = function()
			vim.cmd.colorscheme("moonfly")
		end,
	},

	-- ── Ícones — substitui vim-devicons ──────────────────────────
	{ "nvim-tree/nvim-web-devicons", lazy = true },

	-- ── Statusline — substitui lightline.vim ─────────────────────
	-- lualine é nativamente Lua: sem invocação de função Vimscript
	-- por redesenho, latência de actualização assimptoticamente nula.
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				theme = "moonfly",
				component_separators = "",
				section_separators = "",
				globalstatus = true,
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff" },
				lualine_c = {
					{ "filename", path = 1 },
					{
						"diagnostics",
						symbols = { error = "✖ ", warn = "⚠ ", info = "ℹ ", hint = "➤ " },
					},
				},
				lualine_x = { "filetype" },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		},
	},

	-- ── Tabline / gestão de buffers — substitui lightline-bufferline ──
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = {
			{ "<Tab>", "<Cmd>BufferLineCycleNext<CR>", desc = "Buffer seguinte" },
			{ "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Buffer anterior" },
			{
				"<leader>q",
				function()
					Snacks.bufdelete()
				end,
				desc = "Fechar buffer (preserva layout)",
			},
			{ "<leader>1", "<Cmd>BufferLineGoToBuffer 1<CR>" },
			{ "<leader>2", "<Cmd>BufferLineGoToBuffer 2<CR>" },
			{ "<leader>3", "<Cmd>BufferLineGoToBuffer 3<CR>" },
			{ "<leader>4", "<Cmd>BufferLineGoToBuffer 4<CR>" },
			{ "<leader>5", "<Cmd>BufferLineGoToBuffer 5<CR>" },
		},
		opts = {
			options = {
				diagnostics = "nvim_lsp",
				diagnostics_indicator = function(count, level)
					local icon = level:match("error") and "✖" or "⚠"
					return " " .. icon .. count
				end,
				offsets = {
					{ filetype = "neo-tree", text = "Explorador", highlight = "Directory", text_align = "left" },
				},
				show_buffer_close_icons = false,
				show_close_icon = false,
				separator_style = "thin",
			},
		},
	},

	-- ── Indentação e exclusão de buffers ──────────────────────────
	-- Módulos indent/bufdelete de snacks.nvim — o módulo dashboard
	-- migrou para dashboard-nvim (ver adiante), por robustez e
	-- completude superiores na composição de secções dinâmicas.
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			indent = { enabled = true },
			bufdelete = { enabled = true },
		},
	},

	-- ── Dashboard de arranque — esquema doom ─────────────────────
	-- Taxonomia de campos fiel à documentada em github.com/nvimdev/
	-- dashboard-nvim § Doom: cada entrada de `center` admite icon,
	-- icon_hl, desc, desc_hl, key, keymap (rótulo do atalho externo,
	-- não funcional por si — mera anotação visual), key_hl e
	-- key_format (substituição de `%s` pelo valor de `key`; a
	-- omissão do campo produz o invólucro `[%s]` por omissão do
	-- plugin, aqui suprimido por declaração explícita). `footer`
	-- permanece tabela vazia, congruente com o exemplo oficial —
	-- ausência de rodapé sintetizado, não lacuna de configuração.
	{
		"nvimdev/dashboard-nvim",
		event = "VimEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = { { "<leader>S", "<Cmd>Dashboard<CR>", desc = "Dashboard" } },
		opts = {
			theme = "doom",
			config = {
				header = {
    "                                                                              ",
    "=================     ===============     ===============   ========  ========",
    "\\\\ . . . . . . .\\\\   //. . . . . . .\\\\   //. . . . . . .\\\\  \\\\. . .\\\\// . . //",
    "||. . ._____. . .|| ||. . ._____. . .|| ||. . ._____. . .|| || . . .\\/ . . .||",
    "|| . .||   ||. . || || . .||   ||. . || || . .||   ||. . || ||. . . . . . . ||",
    "||. . ||   || . .|| ||. . ||   || . .|| ||. . ||   || . .|| || . | . . . . .||",
    "|| . .||   ||. _-|| ||-_ .||   ||. . || || . .||   ||. _-|| ||-_.|\\ . . . . ||",
    "||. . ||   ||-'  || ||  `-||   || . .|| ||. . ||   ||-'  || ||  `|\\_ . .|. .||",
    "|| . _||   ||    || ||    ||   ||_ . || || . _||   ||    || ||   |\\ `-_/| . ||",
    "||_-' ||  .|/    || ||    \\|.  || `-_|| ||_-' ||  .|/    || ||   | \\  / |-_.||",
    "||    ||_-'      || ||      `-_||    || ||    ||_-'      || ||   | \\  / |  `||",
    "||    `'         || ||         `'    || ||    `'         || ||   | \\  / |   ||",
    "||            .===' `===.         .==='.`===.         .===' /==. |  \\/  |   ||",
    "||         .=='   \\_|-_ `===. .==='   _|_   `===. .===' _-|/   `==  \\/  |   ||",
    "||      .=='    _-'    `-_  `='    _-'   `-_    `='  _-'   `-_  /|  \\/  |   ||",
    "||   .=='    _-'          `-__\\._-'         `-_./__-'         `' |. /|  |   ||",
    "||.=='    _-'                                                     `' |  /==.||",
    "=='    _-'                        N E O V I M                         \\/   `==",
    "\\   _-'                                                                `-_   /",
    " `''                                                                      ``'  ",
  },
				center = {
					{
						icon = " ",
						icon_hl = "Title",
						desc = "Ficheiros           ",
						desc_hl = "String",
						key = "f",
						keymap = "SPC f f",
						key_hl = "Number",
						key_format = " %s",
						action = "Telescope find_files",
					},
					{
						icon = " ",
						icon_hl = "Title",
						desc = "Recentes            ",
						desc_hl = "String",
						key = "r",
						keymap = "SPC f r",
						key_hl = "Number",
						key_format = " %s",
						action = "Telescope oldfiles",
					},
					{
						icon = " ",
						icon_hl = "Title",
						desc = "Pesquisar texto     ",
						desc_hl = "String",
						key = "g",
						keymap = "SPC r",
						key_hl = "Number",
						key_format = " %s",
						action = "Telescope live_grep",
					},
					{
						icon = " ",
						icon_hl = "Title",
						desc = "Restaurar sessão    ",
						desc_hl = "String",
						key = "s",
						keymap = "SPC s l",
						key_hl = "Number",
						key_format = " %s",
						action = function()
							require("persistence").load()
						end,
					},
					{
						icon = " ",
						icon_hl = "Title",
						desc = "Editar init.lua     ",
						desc_hl = "String",
						key = "v",
						keymap = "",
						key_hl = "Number",
						key_format = " %s",
						action = "edit $MYVIMRC",
					},
					{
						icon = " ",
						icon_hl = "Title",
						desc = "Sair                ",
						desc_hl = "String",
						key = "q",
						keymap = "",
						key_hl = "Number",
						key_format = " %s",
						action = "qa",
					},
				},
				footer = {},
			},
		},
	},

	-- ── Descoberta de mapeamentos — sem equivalente no vimrc ─────
	-- Popup contextual: pressiona <leader> e aguarda; lista todos os
	-- prefixos disponíveis. Substitui a necessidade de memorização
	-- integral do mapa de teclas durante a fase de transição.
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {},
	},
}
