-- ============================================================
-- Mapeamentos universais.
--
-- Os mapeamentos que dependem de um plugin específico (Neo-tree,
-- Telescope, Gitsigns, LSP, etc.) NÃO residem aqui — vivem na
-- tabela `keys` da respectiva spec em lua/plugins/*.lua. É o
-- padrão idiomático de lazy.nvim: a tecla só regista o plugin
-- quando pressionada pela primeira vez (lazy-loading nativo).
-- Consulta o Nvim Handbook.md, secção "Mapa de Teclas", para o
-- inventário completo e centralizado.
-- ============================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- — Buffers (comandos nativos; a navegação sequencial fica a cargo
--   do bufferline.nvim, declarada em lua/plugins/ui.lua)
map("n", "<leader>w", ":update<CR>", { desc = "Guardar buffer" })
map("n", "<leader>W", ":wa<CR>", { desc = "Guardar todos os buffers" })
map("n", "<leader>Q", ":qa<CR>", { desc = "Sair de tudo" })

-- — Janelas
map("n", "<leader>wh", "<C-w>h", { desc = "Janela: esquerda" })
map("n", "<leader>wl", "<C-w>l", { desc = "Janela: direita" })
map("n", "<leader>wj", "<C-w>j", { desc = "Janela: abaixo" })
map("n", "<leader>wk", "<C-w>k", { desc = "Janela: acima" })
map("n", "<leader>w=", "<C-w>=", { desc = "Janelas: equalizar" })

-- — Limpeza de highlight de pesquisa
map("n", "<Esc>", ":nohlsearch<CR>", { desc = "Limpar highlight de pesquisa", silent = true })

-- — Deslocação inter-linhas visuais (qualidade de vida ausente do vimrc:
--   j/k respeitam `wrap` em vez de saltar a linha lógica inteira)
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- — Manter o cursor centrado em saltos amplos (qualidade de vida)
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
