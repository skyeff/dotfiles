;;; init.el --- Bootstrap para configuração literária em Org -*- lexical-binding: t; -*-

;;; Commentary:
;; Este ficheiro é deliberadamente mínimo — toda a configuração real
;; vive em config.org, na mesma pasta (normalmente ~/.emacs.d/config.org).
;;
;; CORRECÇÃO: o ficheiro literário chamava-se antes `init.org' — mas
;; `org-babel-load-file' faz o tangle (extrai o código) para um `.el'
;; com o MESMO NOME BASE, na mesma pasta. `init.org' tangla para
;; `init.el', sobrescrevendo este próprio ficheiro na primeira
;; execução; da segunda vez em diante, o Emacs carrega directamente o
;; resultado achatado (tangled), e deixa de olhar para o `.org` de
;; todo — editar o ficheiro literário deixava de ter qualquer efeito.
;; Chamando-lhe `config.org', o tangle produz `config.el' — um
;; ficheiro diferente deste — e este `init.el' permanece intacto,
;; sessão após sessão.

;;; Code:

(require 'org)
(org-babel-load-file (expand-file-name "config.org" user-emacs-directory))

(provide 'init)
;;; init.el ends here
