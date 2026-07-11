return {

	-- ── Instalador de servidores LSP, linters e formatadores ─────
	-- Sem equivalente no vimrc: vim-lsp requeria instalação manual
	-- de cada servidor no PATH do sistema; mason.nvim gere-os de
	-- forma isolada e declarativa em ~/.local/share/nvim/mason/.
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		opts = {},
	},

	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = { "pyright", "clangd", "lua_ls" },
			automatic_installation = true,
		},
	},

	-- ── Configuração dos servidores LSP nativos ──────────────────
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
			{ "j-hui/fidget.nvim", opts = {} }, -- indicador de progresso do LSP, canto inferior direito
		},
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			vim.diagnostic.config({
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "✖",
						[vim.diagnostic.severity.WARN] = "⚠",
						[vim.diagnostic.severity.HINT] = "➤",
						[vim.diagnostic.severity.INFO] = "ℹ",
					},
				},
				virtual_text = { spacing = 2, prefix = "●" },
				severity_sort = true,
			})

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("skye_lsp_attach", { clear = true }),
				callback = function(event)
					local map = function(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
					end
					map("n", "gd", vim.lsp.buf.definition, "LSP: definição")
					map("n", "gr", vim.lsp.buf.references, "LSP: referências")
					map("n", "gi", vim.lsp.buf.implementation, "LSP: implementação")
					map("n", "K", vim.lsp.buf.hover, "LSP: hover")
					map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: rename")
					map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "LSP: code action")
					map("n", "[d", vim.diagnostic.goto_prev, "Diagnóstico anterior")
					map("n", "]d", vim.diagnostic.goto_next, "Diagnóstico seguinte")

					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client:supports_method("textDocument/inlayHint") then
						vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
					end
				end,
			})

			local servers = {
				pyright = {},
				clangd = {},
				lua_ls = {
					settings = {
						Lua = {
							diagnostics = { globals = { "vim" } },
							workspace = { checkThirdParty = false },
						},
					},
				},
			}

			for name, cfg in pairs(servers) do
				cfg.capabilities = vim.tbl_deep_extend("force", {}, capabilities, cfg.capabilities or {})
				require("lspconfig")[name].setup(cfg)
			end
		end,
	},

	-- ── Autocompletar — substitui asyncomplete + asyncomplete-lsp ─
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					-- Tab/S-Tab/Enter replicam o comportamento exacto do
					-- bloco "Asyncomplete" do _vimrc (pumvisible ? ... : ...).
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
					["<CR>"] = cmp.mapping.confirm({ select = false }),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
				}, {
					{ name = "buffer" },
					{ name = "path" },
				}),
			})
		end,
	},

	-- ── Linting assíncrono — parte do dense-analysis/ale ─────────
	{
		"mfussenegger/nvim-lint",
		event = { "BufWritePost", "BufReadPost", "InsertLeave" },
		config = function()
			require("lint").linters_by_ft = {
				python = { "flake8" },
				javascript = { "eslint" },
				sh = { "shellcheck" },
			}
			vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
				group = vim.api.nvim_create_augroup("skye_lint", { clear = true }),
				callback = function()
					require("lint").try_lint()
				end,
			})
		end,
	},

	-- ── Formatação — parte restante do dense-analysis/ale ────────
	{
		"stevearc/conform.nvim",
		cmd = "ConformInfo",
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				desc = "Formatar buffer",
			},
		},
		opts = {
			formatters_by_ft = {
				python = { "isort", "black" },
				javascript = { "prettier" },
				lua = { "stylua" },
				["*"] = { "trim_whitespace", "trim_newlines" },
			},
		},
	},

	-- ── Lista centralizada de diagnósticos — substitui parte da UI do ALE ─
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = {
			{ "<leader>xx", "<Cmd>Trouble diagnostics toggle<CR>", desc = "Diagnósticos (projecto)" },
			{ "<leader>xd", "<Cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Diagnósticos (buffer)" },
		},
		opts = {},
	},
}
