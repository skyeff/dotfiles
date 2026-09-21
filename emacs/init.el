;;; init.el --- Bootstrap para configuração literária em Org -*- lexical-binding: t; -*-

;;; Commentary:
;; Este ficheiro é deliberadamente mínimo — toda a configuração real
;; vive em config.org, na mesma pasta (normalmente ~/.emacs.d/config.org).
;;; Code:

(require 'org)
(org-babel-load-file (expand-file-name "config.org" user-emacs-directory))

(provide 'init)
;;; init.el ends here
