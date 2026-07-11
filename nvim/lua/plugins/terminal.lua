-- ============================================================
-- Terminal — módulo `terminal` de snacks.nvim, substitui
-- akinsho/toggleterm.nvim.
--
-- Esta spec NÃO declara um plugin novo — estende a spec
-- "folke/snacks.nvim" já registada em lua/plugins/ui.lua.
-- lazy.nvim funde, por nome de plugin, múltiplas specs
-- distribuídas por ficheiros distintos (tabela `opts` e array
-- `keys` são concatenados/mesclados em profundidade). O padrão
-- permite dispersar responsabilidades por domínio funcional
-- (ui.lua: dashboard/indent/bufdelete; terminal.lua: terminal)
-- sem colisão nem duplicação de instalação.
-- ============================================================

return {
	{
		"folke/snacks.nvim",
		opts = {
			terminal = { enabled = true },
		},
		keys = {
			-- Toggle — equivalente a g:floaterm_keymap_toggle
			{
				"<F12>",
				function()
					Snacks.terminal.toggle()
				end,
				desc = "Terminal: toggle",
			},
			-- Novo terminal flutuante — equivalente a g:floaterm_keymap_new
			{
				"<F10>",
				function()
					Snacks.terminal.open(nil, { win = { position = "float" } })
				end,
				desc = "Terminal: novo",
			},
			-- Alternar entre terminais abertos — equivalente a g:floaterm_keymap_next
			{
				"<F11>",
				function()
					Snacks.terminal.toggle(nil, { win = { position = "float" } })
				end,
				desc = "Terminal: alternar",
			},
		},
	},
}
