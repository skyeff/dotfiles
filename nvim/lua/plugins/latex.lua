-- ============================================================
-- vimtex — cobertura estrutural para o domínio de maior
-- densidade documental na tua actividade: compilação assíncrona,
-- realce semântico de ambientes/citações, dobramento por secção,
-- pesquisa bidireccional (forward/inverse search) com o visor PDF.
-- ============================================================

return {
	{
		"lervag/vimtex",
		ft = "tex",
		init = function()
			vim.g.vimtex_view_method = "zathura" -- ajusta ao visor instalado em Artemis
			vim.g.vimtex_compiler_method = "latexmk"
			vim.g.vimtex_compiler_latexmk = {
				build_dir = "build",
				options = {
					"-pdf",
					"-interaction=nonstopmode",
					"-synctex=1",
				},
			}
			vim.g.vimtex_quickfix_mode = 0 -- suprime abertura automática do quickfix por aviso menor
			vim.g.vimtex_fold_enabled = true
			-- cmp: fonte de citações/referências cruzadas, via nvim-cmp
			vim.g.vimtex_complete_enabled = true
		end,
	},

	-- Fonte de autocompletar para \cite{} e \ref{}, integrada em nvim-cmp
	{
		"micangl/cmp-vimtex",
		ft = "tex",
		dependencies = { "hrsh7th/nvim-cmp" },
		config = function()
			require("cmp").setup.filetype("tex", {
				sources = require("cmp").config.sources({
					{ name = "vimtex" },
					{ name = "luasnip" },
				}, {
					{ name = "buffer" },
					{ name = "path" },
				}),
			})
		end,
	},
}
