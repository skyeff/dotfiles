-- ============================================================
-- Cobertura para Common Lisp, linguagem primária declarada,
-- ausente por completo da suite anterior. Duas funções distintas,
-- não redundantes entre si: avaliação interactiva (Conjure) e
-- edição estrutural por s-expressão (vim-sexp) — a segunda opera
-- mesmo sem REPL activo, a primeira pressupõe-no.
-- ============================================================

return {
	-- ── REPL-driven development ──────────────────────────────────
	-- Avalia formas, buffers ou expressões seleccionadas directamente
	-- no REPL (SBCL, CCL, via swank/slynk), com resultado inline —
	-- ausência estrutural completa face ao _vimrc, que não dispunha
	-- de qualquer mecanismo de avaliação interactiva.
	{
		"Olical/conjure",
		ft = { "lisp", "scheme", "racket" },
		init = function()
			vim.g["conjure#filetype#lisp"] = "conjure.client.common-lisp.sbcl"
			vim.g["conjure#log#hud#width"] = 0.42
			vim.g["conjure#log#hud#anchor"] = "SE"
		end,
	},

	-- ── Edição estrutural por s-expressão ─────────────────────────
	-- Operadores sobre a árvore de parênteses, não sobre texto plano:
	-- desloca, envolve, desenvolve, envolve/desenvolve formas inteiras
	-- sem risco de desequilíbrio de parênteses — paridade estrutural
	-- com o paradigma Lisp, ausente de qualquer plugin de propósito
	-- textual genérico (surround incluído).
	{
		"guns/vim-sexp",
		ft = { "lisp", "scheme", "racket", "clojure" },
		dependencies = {
			{ "tpope/vim-sexp-mappings-for-regular-people", ft = { "lisp", "scheme", "racket", "clojure" } },
		},
	},
}
