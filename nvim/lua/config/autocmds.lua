-- ============================================================
-- Auto-comandos — equivalente ao augroup skye_vimrc do _vimrc.
-- ============================================================

local group = vim.api.nvim_create_augroup("skye_nvimrc", { clear = true })

-- Remove espaço em fim de linha ao gravar
vim.api.nvim_create_autocmd("BufWritePre", {
	group = group,
	pattern = "*",
	command = [[%s/\s\+$//e]],
})

-- Restaura a posição do cursor da sessão anterior
vim.api.nvim_create_autocmd("BufReadPost", {
	group = group,
	pattern = "*",
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- signcolumn=no em filetypes de interface (equivalente à linha
-- "FileType nerdtree,floaterm,fzf,startify,tagbar" do vimrc)
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = { "neo-tree", "snacks_terminal", "TelescopePrompt", "dashboard", "aerial", "trouble" },
	callback = function()
		vim.opt_local.signcolumn = "no"
	end,
})

-- Realce breve do texto copiado — substitui machakann/vim-highlightedyank;
-- funcionalidade nativa desde o Neovim 0.10, dispensa dependência externa.
vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	callback = function()
		vim.highlight.on_yank({ higroup = "IncSearch", timeout = 300 })
	end,
})

-- Fecha o Neo-tree quando é a única janela editável restante.
-- Condição corrigida: fecha quando ZERO janelas normais subsistem
-- (não uma) — a versão anterior invertia o limiar, tornando este
-- autocomando inócuo por sobreposição silenciosa com
-- close_if_last_window, já declarado em explorer.lua. Mantido
-- como reforço explícito, não como duplicação redundante: cobre
-- o caso de múltiplas janelas flutuantes residuais que a opção
-- nativa do Neo-tree não discrimina.
vim.api.nvim_create_autocmd("BufEnter", {
	group = group,
	callback = function()
		local tree_wins, floating_wins = {}, {}
		local wins = vim.api.nvim_tabpage_list_wins(0)
		for _, w in ipairs(wins) do
			local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w))
			if bufname:match("neo%-tree") ~= nil then
				table.insert(tree_wins, w)
			end
			if vim.api.nvim_win_get_config(w).relative ~= "" then
				table.insert(floating_wins, w)
			end
		end
		if #tree_wins > 0 and 0 == #wins - #floating_wins - #tree_wins then
			for _, w in ipairs(tree_wins) do
				vim.api.nvim_win_close(w, true)
			end
		end
	end,
})
