;;; -*- mode: lisp; -*-
;;; teclas.lisp — atalhos sob o prefixo C-z e os comandos que eles chamam
;;; (segundo monitor, flutuantes, capturas). Lido no fim de config.
;;; O lançador e os avisos de volume/brilho vivem em interface.lisp.

(in-package :stumpwm)

;;;; =====================================================================
;;;; 1. TECLAS — mnemónicas do Emacs sob o prefixo C-z
;;;; =====================================================================

;;; Filosofia: C-z faz de C-x do Emacs. Uma tecla, uma função; só o que é
;;; raro ou destrutivo vive num sub-prefixo (q sessão, t grupos, v visual).
;;;   SPC              menu de aplicações
;;;   RET c  kitty     w  firefox     e  emacs     l  bloquear     x  comandos
;;;   0 1 2 3 + o      molduras (como no Emacs)
;;;   C-f C-b C-n C-p  foco por direcção;  M-f M-b M-n M-p  troca de lugar
;;;   b k K TAB < >    janelas (os "buffers");  F ecrã inteiro
;;;   f  r             flutuante: alterna / ajusta tamanho e posição
;;;   M-1 M-2 M-3      ir para o grupo;  t  gerir grupos
;;;   q sessão   v visual   s S capturas
;;; Os restantes atalhos de fábrica do StumpWM continuam activos (C-z ? lista).

(defun ligar (tecla comando &optional (mapa *root-map*))
  "Liga TECLA a COMANDO em MAPA e liberta a tecla nos mapas por-grupo
(que, no StumpWM, têm precedência sobre *root-map*)."
  (let ((k (kbd tecla)))
    (dolist (nome '("*TILE-GROUP-ROOT-MAP*" "*FLOAT-GROUP-ROOT-MAP*"))
      (let ((v (sym "STUMPWM" nome)))
        (when (and v (boundp v))
          (ignore-errors (undefine-key (symbol-value v) k)))))
    (define-key mapa k comando)))

(defun mapa-de (&rest pares)
  "Novo keymap a partir de pares TECLA COMANDO."
  (let ((m (make-sparse-keymap)))
    (loop for (tecla cmd) on pares by #'cddr
          do (define-key m (kbd tecla) cmd))
    m))

;;; Aplicações
(defcommand firefox () ()
  "Start Firefox or switch to it, if it is already running"
  (run-or-raise *cfg-navegador* '(:class "firefox")))

(let ((term (format nil "exec ~a" *cfg-terminal*)))
  (ligar "RET" term)
  (ligar "c" term))
(ligar "w" "firefox")
(ligar "e" "swm-emacs")
(ligar "SPC" "lancador")              ; menu de aplicações (definido mais abaixo)
(ligar "l" "exec slock")

;;; Comandos (o M-x do Emacs)
(ligar "x" "colon")

;;; Sessão: C-z q ...  (sub-prefixo, para não haver toques acidentais)
(ligar "q" (mapa-de "q" "quit-confirm"
                    "r" "restart-hard"
                    "l" "loadrc"
                    "e" "toggle-swank"))
(ligar "C-g" "abort")
(ligar "C-z" "send-escape")

;;; Molduras (os "windows" do Emacs)
(ligar "0" "remove")
(ligar "1" "only")
(ligar "2" "hsplit")
(ligar "3" "vsplit")
(ligar "+" "balance-frames")
(ligar "o" "fnext")
(ligar "C-f" "move-focus right")
(ligar "C-b" "move-focus left")
(ligar "C-n" "move-focus down")
(ligar "C-p" "move-focus up")
(ligar "M-f" "exchange-direction right")
(ligar "M-b" "exchange-direction left")
(ligar "M-n" "exchange-direction down")
(ligar "M-p" "exchange-direction up")

;;; Janelas (os "buffers")
(ligar "b" "pull-from-windowlist")    ; como C-x b: mostra AQUI a janela escolhida
(ligar "k" "delete-window")
(ligar "K" "kill-window")
(ligar "Right" "next")
(ligar "Left" "prev")
(ligar "TAB" "other")
(ligar "F" "fullscreen")

;;; Segundo monitor: envia a janela actual para a moldura da cabeça seguinte
;;; (circular) e segue-a. Complementa o foco (C-z o) e a troca (C-z M-f).
(defcommand janela-outro-monitor () ()
  "Move a janela actual para a primeira moldura da cabeça seguinte."
  (let* ((win (current-window))
         (cabecas (screen-heads (current-screen)))
         (atual (current-head))
         (prox (or (second (member atual cabecas)) (first cabecas)))
         (alvo (first (stumpwm::head-frames (current-group) prox))))
    (if (and win alvo (not (eq prox atual)))
        (stumpwm::pull-window win alvo)
        (message "Sem outra cabeça ou sem janela"))))

(ligar "M-o" "janela-outro-monitor")

;;; Flutuantes: C-z f alterna. Em mosaico, a janela flutua onde está; no
;;; grupo flutuante (3.º), devolve-a ao 1.º grupo, em mosaico.
(defun janela-flutuante-p (&optional (win (current-window)))
  "Verdadeiro se WIN é uma float-window (grupo flutuante ou float-this)."
  (and win (typep win 'float-window)))

(defcommand alternar-flutuante () ()
  "Alterna a janela actual entre mosaico e flutuante."
  (cond ((null (current-window)) (message "Sem janela"))
        ((typep (current-group) 'float-group)
         (run-commands (format nil "gmove-and-follow ~a" (first *cfg-grupos*))))
        ((janela-flutuante-p) (unfloat-this))
        (t (float-this))))

(ligar "f" "alternar-flutuante")

;;; Grupos: C-z M-1/2/3 vai ao grupo; C-z t ... gere-os
;;;   t m N  manda a janela para o grupo N     t M N  manda e segue
;;;   t o/O  seguinte/anterior   t TAB  último   t n  novo   t r  renomear
;;;   t k  matar   t l  lista
(let ((tg (make-sparse-keymap))
      (mov (make-sparse-keymap))
      (seg (make-sparse-keymap)))
  (loop for g in *cfg-grupos*
        for n from 1
        for k = (format nil "~d" n)
        do (define-key mov (kbd k) (format nil "gmove ~a" g))
           (define-key seg (kbd k) (format nil "gmove-and-follow ~a" g))
           (ligar (format nil "M-~d" n) (format nil "gselect ~a" g)))
  (define-key tg (kbd "m") mov)
  (define-key tg (kbd "M") seg)
  (define-key tg (kbd "o") "gnext")
  (define-key tg (kbd "O") "gprev")
  (define-key tg (kbd "TAB") "gother")
  (define-key tg (kbd "n") "gnew")
  (define-key tg (kbd "k") "gkill")
  (define-key tg (kbd "r") "grename")
  (define-key tg (kbd "l") "groups")
  (ligar "t" tg))

;;; Ajustar janela: C-z r
;;;   mosaico    iresize (setas ou h j k l; RET/ESC sai)
;;;   flutuante  modo próprio:  h j k l / setas  tamanho
;;;                             H J K L / S-setas  posição
;;;                             c  centrar   RET ESC q  sair
;;;   Rato (flutuantes): Mod+botão 1 move, Mod+botão 3 redimensiona
(ligar "r" "modo-resize")

(rc-try "resize-teclas"
  (loop for (k c) in '(("h" "left") ("j" "down") ("k" "up") ("l" "right")
                       ("C-b" "left") ("C-n" "down") ("C-p" "up") ("C-f" "right"))
        do (define-key *resize-map* (kbd k) (format nil "resize-direction ~a" c))))

(defvar *mapa-flut* (make-sparse-keymap)
  "Modo de ajuste (tamanho e posição) das janelas flutuantes.")

(defun redimensionar-flutuante (dw dh)
  (let ((win (current-window)))
    (if (janela-flutuante-p win)
        (float-window-move-resize win
                                  :width  (max 50 (+ (window-width win) dw))
                                  :height (max 50 (+ (window-height win) dh)))
        (message "Só em janelas flutuantes (C-z f)"))))

(defun mover-flutuante (dx dy)
  (let ((win (current-window)))
    (if (janela-flutuante-p win)
        (let ((p (window-parent win)))
          (float-window-move-resize win
                                    :x (+ (xlib:drawable-x p) dx)
                                    :y (+ (xlib:drawable-y p) dy)))
        (message "Só em janelas flutuantes (C-z f)"))))

(defcommand resize-float (dw dh) ((:number "Δ largura: ") (:number "Δ altura: "))
  "Redimensiona a janela flutuante actual por DW x DH pixels."
  (redimensionar-flutuante dw dh))

(defcommand move-float (dx dy) ((:number "Δx: ") (:number "Δy: "))
  "Move a janela flutuante actual por DX x DY pixels."
  (mover-flutuante dx dy))

(defcommand centrar-flutuante () ()
  "Centra a janela flutuante actual na cabeça actual."
  (let ((win (current-window)))
    (if (janela-flutuante-p win)
        (let ((h (current-head)))
          (float-window-move-resize
           win
           :x (+ (head-x h) (max 0 (round (- (head-width h) (window-width win)) 2)))
           :y (+ (head-y h) (max 0 (round (- (head-height h) (window-height win)) 2)))))
        (message "Só em janelas flutuantes (C-z f)"))))

(defcommand sair-modo () ()
  "Sai do modo de ajuste de janelas flutuantes."
  (pop-top-map)
  (message "modo de ajuste: fim"))

(defcommand modo-resize () ()
  "Ajustar janela: iresize em mosaico; modo próprio em janelas flutuantes."
  (if (janela-flutuante-p)
      (progn
        (push-top-map *mapa-flut*)
        (message "^2ajustar^n  h j k l tamanho   H J K L posição   c centrar   RET sai"))
      (run-commands "iresize")))

(let ((p *cfg-resize-flut*))
  (loop for (tecla dw dh) in `(("h" ,(- p) 0) ("Left"  ,(- p) 0)
                               ("l" ,p 0)     ("Right" ,p 0)
                               ("j" 0 ,p)     ("Down"  0 ,p)
                               ("k" 0 ,(- p)) ("Up"    0 ,(- p)))
        do (define-key *mapa-flut* (kbd tecla)
             (format nil "resize-float ~d ~d" dw dh)))
  (loop for (tecla dx dy) in `(("H" ,(- p) 0) ("S-Left"  ,(- p) 0)
                               ("L" ,p 0)     ("S-Right" ,p 0)
                               ("J" 0 ,p)     ("S-Down"  0 ,p)
                               ("K" 0 ,(- p)) ("S-Up"    0 ,(- p)))
        do (define-key *mapa-flut* (kbd tecla)
             (format nil "move-float ~d ~d" dx dy))))
(define-key *mapa-flut* (kbd "c") "centrar-flutuante")
(dolist (k '("ESC" "RET" "C-g" "q"))
  (define-key *mapa-flut* (kbd k) "sair-modo"))

;;; Visual: C-z v ...  (barra, gaps, mensagens, notificações, info)
(ligar "v" (mapa-de "g" "toggle-gaps"
                    "b" "mode-line"
                    "m" "lastmsg"
                    "i" "info"
                    "n" "exec dunstctl history-pop"
                    "N" "exec dunstctl set-paused toggle"))

;;; Capturas
(defcommand stump-screenshot () ()
  (run-shell-command (format nil "exec maim ~a/captura-$(date +%F-%H%M%S).png"
                              *cfg-capturas-dir*))
  (message "Captura gravada"))

(defcommand stump-screenshot-regiao () ()
  (run-shell-command (format nil "exec maim -s ~a/captura-$(date +%F-%H%M%S).png"
                              *cfg-capturas-dir*))
  (message "Selecciona a região"))

(ligar "s" "stump-screenshot")
(ligar "S" "stump-screenshot-regiao")
(define-key *top-map* (kbd "Print") "stump-screenshot")

;;; Som e brilho (sem prefixo): comandos e avisos em interface.lisp
(define-key *top-map* (kbd "XF86AudioRaiseVolume")  "volume-mais")
(define-key *top-map* (kbd "XF86AudioLowerVolume")  "volume-menos")
(define-key *top-map* (kbd "XF86AudioMute")         "volume-mudo")
(define-key *top-map* (kbd "XF86MonBrightnessUp")   "brilho-mais")
(define-key *top-map* (kbd "XF86MonBrightnessDown") "brilho-menos")
