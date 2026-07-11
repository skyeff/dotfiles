-- ============================================================
-- Depuração interactiva — complemento transitivo, não redundante,
-- ao tripé LSP/lint/format já instalado. Diagnóstico estático
-- (nvim-lint, LSP) expõe erro antes da execução; DAP expõe estado
-- durante a execução suspensa — funções ortogonais, ambas
-- necessárias, nunca intercambiáveis.
-- ============================================================

return {
	{
		"mfussenegger/nvim-dap",
		keys = {
			{ "<F5>", function() require("dap").continue() end, desc = "DAP: continuar/iniciar" },
			{ "<F9>", function() require("dap").toggle_breakpoint() end, desc = "DAP: breakpoint" },
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Condição do breakpoint: "))
				end,
				desc = "DAP: breakpoint condicional",
			},
			-- Nota: <F10>-<F12> já governam o terminal (snacks.nvim,
			-- ver terminal.lua) — step over/into/out migram para o
			-- prefixo <leader>d, evitando colisão de mapeamento global.
			{ "<leader>do", function() require("dap").step_over() end, desc = "DAP: step over" },
			{ "<leader>di", function() require("dap").step_into() end, desc = "DAP: step into" },
			{ "<leader>dO", function() require("dap").step_out() end, desc = "DAP: step out" },
			{ "<leader>dr", function() require("dap").repl.toggle() end, desc = "DAP: REPL" },
			{ "<leader>dt", function() require("dap").terminate() end, desc = "DAP: terminar sessão" },
		},
	},

	-- ── Painel visual — pilha, escopos, variáveis, breakpoints ────
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		keys = {
			{ "<leader>du", function() require("dapui").toggle() end, desc = "DAP: painel UI" },
		},
		config = function()
			local dapui = require("dapui")
			dapui.setup()
			local dap = require("dap")
			dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
			dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
			dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
		end,
	},

	-- ── Valores inline durante a suspensão — qualidade de vida ───
	{
		"theHamsta/nvim-dap-virtual-text",
		dependencies = { "mfussenegger/nvim-dap" },
		opts = {},
	},

	-- ── Adaptador Python ──────────────────────────────────────────
	{
		"mfussenegger/nvim-dap-python",
		ft = "python",
		dependencies = { "mfussenegger/nvim-dap" },
		config = function()
			-- Aponta para o interpretador do venv activo; ajusta se
			-- Artemis mantiver um venv fixo fora do padrão.
			require("dap-python").setup(vim.fn.exepath("python3"))
		end,
	},
}
