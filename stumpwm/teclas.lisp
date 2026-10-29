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
;;;   RET c  kitty     w  firefox     e  emacs     u  unidades USB     x  comandos
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
(ligar "u" "drive-menu")              ; menu das unidades externas

;;; Comandos (o M-x do Emacs)
(ligar "x" "colon")

;;; Sessão: C-z q ...  (sub-prefixo, para não haver toques acidentais)
(ligar "q" (mapa-de "q" "quit-confirm"
                    "r" "restart-hard"
                    "l" "loadrc"
                    "e" "toggle-swank"
                    "p" "power-menu"
                    "m" "monitor-menu"
                    "c" "painel-menu"          ; painel de controlo
                    "f" "cafe-alternar"        ; café (ecrã sempre aceso)
                    "n" "noturna-alternar"))   ; luz noturna
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

;;;; =====================================================================
;;;; 2. CLIQUES E MENUS — energia, unidades externas, monitores
;;;; =====================================================================

;;; Cliques: *mode-line-click-hook* entrega (barra botão x y), com x relativo
;;; à barra. Botão esquerdo sobre um ícone abre o menu respectivo.
;;; (O hover está em interface.lisp, secção 7.)
(defparameter *clique-acoes*
  '((:power . "power-menu") (:drive . "drive-menu") (:monitor . "monitor-menu")
    (:painel . "painel-menu") (:cafe . "cafe-alternar") (:noturna . "noturna-alternar")))

(defun clique-na-barra (ml botao x y)
  (declare (ignore y))
  (when (eql botao 1)
    (let ((acao (cdr (assoc (segmento-em x (xlib:drawable-width (mode-line-window ml)))
                            *clique-acoes*))))
      (when acao (run-commands acao)))))

(add-hook *mode-line-click-hook* 'clique-na-barra)

;;; Menu genérico: janela central com ícones e legendas. O StumpWM não entrega
;;; cliques a janelas de mensagem, por isso escolhe-se pelo teclado:
;;;   setas ou h l    mudam de opção        1-9   vão directo
;;;   cima/baixo      mudam de alvo (a unidade, o lado do monitor)
;;;   RET executa     ESC / q cancelam
;;; Cada menu é uma caixa-menu: título, linha de contexto, opções do alvo actual.
;;; Uma opção é (ÍCONE LEGENDA LEGENDA2 ACÇÃO); ACÇÃO: texto de shell, função ou :sair.
(defstruct (caixa-menu (:conc-name cm-))
  titulo sub opcoes (sel 0) (alvo 0) (n-alvos (lambda () 1))
  grupos)   ; função -> ((TÍTULO . OPÇÕES)...): grelha de vários grupos num só quadro

(defvar *menu* nil "A caixa-menu aberta, ou NIL.")
(defvar *mapa-menu* (make-sparse-keymap))

(defun cm-lista (m)
  "Todas as opções, por ordem (numa grelha, os grupos seguidos)."
  (if (cm-grupos m)
      (loop for g in (funcall (cm-grupos m)) append (cdr g))
      (funcall (cm-opcoes m) (cm-alvo m))))

(defun celula (str px)
  "STR centrada numa célula de PX pixels (espaços dos dois lados)."
  (let* ((esp (max 1 (largura-px " ")))
         (livre (max 0 (round (- px (largura-px str)) esp)))
         (esq (floor livre 2)))
    (format nil "~a~a~a" (make-string esq :initial-element #\Space) str
            (make-string (- livre esq) :initial-element #\Space))))

(defun fechar-menu ()
  (setf *menu* nil)
  (pop-top-map)
  (unless (ignore-errors (funcall 'unmap-all-message-windows) t)
    (let ((*timeout-wait* 0.05))
      (message " "))))

(defun desenhar-menu-linha ()
  (let* ((m *menu*)
         (n-alvos (funcall (cm-n-alvos m))))
    (if (< n-alvos 1)
        (progn (fechar-menu) (message "Nada a mostrar"))
        (let* ((px *cfg-menu-celula*)
               (ops (cm-lista m))
               (total (* px (length ops)))
               (sub (and (cm-sub m) (funcall (cm-sub m) (cm-alvo m) n-alvos)))
               (l-icones "") (l-leg1 "") (l-leg2 "")
               (tem2 (some (lambda (o) (string/= (third o) "")) ops)))
          (loop for (cod leg1 leg2) in ops
                for i from 0
                for cor = (if (= i (cm-sel m)) "^2" "^3")
                do (setf l-icones (concatenate 'string l-icones
                                               (format nil "~a~a^n" cor (celula (icone cod "*") px)))
                         l-leg1 (concatenate 'string l-leg1
                                             (format nil "~a~a^n" cor (celula leg1 px)))
                         l-leg2 (concatenate 'string l-leg2
                                             (format nil "~a~a^n" cor (celula leg2 px)))))
          (let ((*timeout-wait* 600)
                (*message-window-y-padding* 14)
                (linhas (append (list (format nil "^n~a" (celula (cm-titulo m) total)))
                                (when sub (list (format nil "^3~a^n" (celula sub total))))
                                (list "" l-icones l-leg1)
                                (when tem2 (list l-leg2))
                                (list "" (format nil "^3~a^n"
                                                 (celula (if (> n-alvos 1)
                                                             "setas   cima/baixo muda   RET ok   ESC sai"
                                                             "setas ou 1-9   RET ok   ESC sai")
                                                         total))))))
            (message "~a" (format nil "~{~a~^~%~}" linhas)))))))

;;; Grelha: vários grupos (cada um com título e uma fila de opções) no mesmo
;;; quadro. Os números 1-9 contam as opções por ordem, de grupo em grupo.
(defun desenhar-grade (m)
  (let* ((px *cfg-painel-celula*)
         (grupos (funcall (cm-grupos m)))
         (cols (reduce #'max (mapcar (lambda (g) (length (cdr g))) grupos)))
         (total (* px cols))
         (esp (max 1 (largura-px " ")))
         (indice 0)
         (linhas (list (format nil "^n~a" (celula (cm-titulo m) total)) "")))
    (dolist (g grupos)
      (let* ((ops (cdr g))
             (esq (make-string (max 0 (round (- total (* px (length ops))) (* 2 esp)))
                               :initial-element #\Space))
             (l-ic "") (l-1 "") (l-2 "")
             (tem2 (some (lambda (o) (string/= (third o) "")) ops)))
        (dolist (o ops)
          (destructuring-bind (cod leg1 leg2 &rest resto) o
            (declare (ignore resto))
            (let ((cor (if (= indice (cm-sel m)) "^2" "^3")))
              (setf l-ic (concatenate 'string l-ic (format nil "~a~a^n" cor (celula (icone cod "*") px)))
                    l-1  (concatenate 'string l-1  (format nil "~a~a^n" cor (celula leg1 px)))
                    l-2  (concatenate 'string l-2  (format nil "~a~a^n" cor (celula leg2 px))))
              (incf indice))))
        (setf linhas
              (append linhas
                      (list (format nil "^3~a^n" (celula (car g) total)) ""
                            (concatenate 'string esq l-ic)
                            (concatenate 'string esq l-1))
                      (when tem2 (list (concatenate 'string esq l-2)))
                      (list "")))))
    (let ((*timeout-wait* 600)
          (*message-window-y-padding* *cfg-painel-padding*))
      (message "~a"
               (format nil "~{~a~^~%~}"
                       (append linhas
                               (list (format nil "^3~a^n"
                                             (celula "setas ou 1-9   cima/baixo muda de grupo   RET ok   ESC sai"
                                                     total)))))))))

(defun desenhar-menu ()
  (if (cm-grupos *menu*) (desenhar-grade *menu*) (desenhar-menu-linha)))

(defun abrir-menu (caixa)
  (unless *menu*
    (setf *menu* caixa)
    (push-top-map *mapa-menu*)
    (desenhar-menu)))

(defun executar-acao (acao)
  (handler-case
      (typecase acao
        (string (run-shell-command acao))
        (function (funcall acao))
        (t (when (eq acao :sair) (run-commands "quit"))))
    (error (e) (message "Erro: ~a" e))))

(defcommand menu-ir (n) ((:number "Opção: "))
  "Selecciona a opção N (0 a 8) do menu aberto."
  (when (and *menu* (< -1 n (length (cm-lista *menu*))))
    (setf (cm-sel *menu*) n)
    (desenhar-menu)))

(defcommand menu-passo (d) ((:number "Passo: "))
  "Move a selecção do menu aberto por D opções."
  (when *menu*
    (menu-ir (mod (+ (cm-sel *menu*) d) (length (cm-lista *menu*))))))

(defun menu-grupo (d)
  "Grelha: passa ao grupo D acima/abaixo, na mesma coluna (ou na última, se o
grupo for mais curto)."
  (let* ((grupos (funcall (cm-grupos *menu*)))
         (sel (cm-sel *menu*))
         (g 0) (inicio 0))
    (loop for gr in grupos
          for i from 0
          for n = (length (cdr gr))
          do (when (< sel (+ inicio n)) (setf g i) (return))
             (incf inicio n))
    (let* ((col (- sel inicio))
           (g2 (mod (+ g d) (length grupos)))
           (ini2 (reduce #'+ (mapcar (lambda (x) (length (cdr x)))
                                     (subseq grupos 0 g2))))
           (n2 (length (cdr (nth g2 grupos)))))
      (menu-ir (+ ini2 (min col (1- n2)))))))

(defcommand menu-alvo (d) ((:number "Alvo: "))
  "Muda o alvo do menu aberto (outra unidade, outro lado do monitor, outro grupo)."
  (when (and *menu* (cm-grupos *menu*))
    (menu-grupo d)
    (return-from menu-alvo nil))
  (when *menu*
    (let ((n (funcall (cm-n-alvos *menu*))))
      (when (plusp n)
        (setf (cm-alvo *menu*) (mod (+ (cm-alvo *menu*) d) n))
        (setf (cm-sel *menu*) (min (cm-sel *menu*) (1- (length (cm-lista *menu*)))))
        (desenhar-menu)))))

(defcommand menu-executar () ()
  "Executa a opção escolhida do menu aberto."
  (when *menu*
    (let ((acao (fourth (nth (cm-sel *menu*) (cm-lista *menu*)))))
      (fechar-menu)
      (executar-acao acao))))

(defcommand menu-fechar () ()
  "Fecha o menu aberto sem fazer nada."
  (when *menu* (fechar-menu)))

(dolist (par '(("Right" "menu-passo 1")  ("l" "menu-passo 1")  ("C-f" "menu-passo 1")
               ("Left"  "menu-passo -1") ("h" "menu-passo -1") ("C-b" "menu-passo -1")
               ("Down"  "menu-alvo 1")   ("j" "menu-alvo 1")   ("C-n" "menu-alvo 1")
               ("Up"    "menu-alvo -1")  ("k" "menu-alvo -1")  ("C-p" "menu-alvo -1")
               ("RET" "menu-executar")
               ("ESC" "menu-fechar") ("q" "menu-fechar") ("C-g" "menu-fechar")))
  (define-key *mapa-menu* (kbd (first par)) (second par)))
(dotimes (i 9)
  (define-key *mapa-menu* (kbd (format nil "~d" (1+ i))) (format nil "menu-ir ~d" i)))

;;; --- energia ---------------------------------------------------------------
(defcommand power-menu () ()
  "Abre o menu de energia (suspender, desligar, sair)."
  (abrir-menu
   (make-caixa-menu
    :titulo "Energia"
    :opcoes (lambda (alvo)
              (declare (ignore alvo))
              (list (list #xF186 "Suspender" "" *cfg-cmd-suspender*)
                    (list #xF011 "Desligar"  "" *cfg-cmd-desligar*)
                    (list #xF08B "Sair"      "" :sair))))))

;;; --- unidades externas (utilities/discos.lisp) -----------------------------
(defun disco-do-alvo (alvo)
  (nth (min alvo (max 0 (1- (length *discos*)))) *discos*))

(defcommand drive-menu () ()
  "Abre o menu das unidades externas montadas (abrir, info, desmontar, remover)."
  (cond (*menu* nil)
        ((null *discos*) (message "Nenhuma unidade externa montada"))
        (t (abrir-menu
            (make-caixa-menu
             :titulo "Unidades externas"
             :n-alvos (lambda () (length *discos*))
             :sub (lambda (alvo n)
                    (format nil "~a~:[~;  (~d/~d)~]"
                            (descricao-disco (disco-do-alvo alvo)) (> n 1) (1+ alvo) n))
             :opcoes (lambda (alvo)
                       (let ((d (disco-do-alvo alvo)))
                         (list (list #xF07C "Abrir" ""
                                     (format nil "~a ~a" *cfg-gestor-ficheiros*
                                             (sh-quote (or (getf d :ponto) "/mnt"))))
                               (list #xF05A "Informação" ""
                                     (lambda () (info-disco d)))
                               (list #xF127 "Desmontar" ""
                                     (lambda () (desmontar-disco d)))
                               (list #xF052 "Remover" "com segurança"
                                     (lambda () (remover-disco d)))))))))))

;;; --- monitores (utilities/monitores.lisp) ----------------------------------
(defparameter *lados-monitor* '(:direita :esquerda :acima :abaixo))

(defcommand monitor-menu () ()
  "Abre o menu dos monitores (estender, espelhar, só interno, só externo)."
  (abrir-menu
   (make-caixa-menu
    :titulo "Monitores"
    :alvo (or (position *cfg-monitor-lado* *lados-monitor*) 0)
    :n-alvos (lambda () (length *lados-monitor*))
    :sub (lambda (alvo n)
           (declare (ignore n))
           (format nil "estender para a ~(~a~)" (nth alvo *lados-monitor*)))
    :opcoes (lambda (alvo)
              (let ((lado (nth alvo *lados-monitor*)))
                (list (list #xF0DB "Estender" "" (lambda () (monitores-estender lado)))
                      (list #xF24D "Espelhar" "" #'monitores-espelhar)
                      (list #xF109 "Só interno" "" #'monitores-so-interno)
                      (list #xF26C "Só externo" "" #'monitores-so-externo)))))))

;;; --- painel de controlo (utilities/painel.lisp) ----------------------------
;;; Uma só grelha com dois grupos (rede e Bluetooth; energia e ecrã); cima/baixo
;;; passa de grupo. As opções que alternam um estado voltam a abrir o painel,
;;; já com o estado novo.
(defun painel-reabrir ()
  "Volta a abrir o painel pouco depois, para o estado novo já estar assente."
  (run-with-timer 0.7 nil (lambda () (ignore-errors (run-commands "painel-menu")))))

(defun texto-rf (tipo)
  (case (rfkill-estado tipo)
    (:activo "ligado") (:bloqueado "desligado") (t "indisponível")))

(defun painel-opcoes (pagina)
  (case pagina
    (0 (list (list #xF1EB "Wi-Fi" (texto-rf "wlan")
                   (lambda () (wifi-alternar) (painel-reabrir)))
             (list #xF293 "Bluetooth" (texto-rf "bluetooth")
                   (lambda () (bluetooth-alternar) (painel-reabrir)))
             (list #xF013 "Configurar" "Wi-Fi" *cfg-cmd-wifi-gestor*)
             (list #xF294 "Gerir" "Bluetooth" *cfg-cmd-bluetooth-gestor*)))
    (t (let ((disp (perfis-disponiveis)))
         (append
          (loop for (id cod nome) in *perfis-energia*
                for p = (assoc id disp :test #'string=)
                when p
                  collect (let ((id id))
                            (list cod nome (if (cdr p) "activo" "")
                                  (lambda () (perfil-definir id) (painel-reabrir)))))
          (list (list #xF0F4 "Café" (if *cafe-activo* "activo" "inactivo")
                      (lambda () (if *cafe-activo* (cafe-desligar) (cafe-ligar))
                        (painel-reabrir)))
                (list #xF186 "Luz noturna" (if *noturna-activa* "activa" "inactiva")
                      (lambda () (if *noturna-activa* (noturna-desligar) (noturna-ligar))
                        (painel-reabrir)))))))))

(defcommand painel-menu () ()
  "Abre o painel de controlo: Wi-Fi, Bluetooth, perfis de energia, café, luz noturna."
  (abrir-menu
   (make-caixa-menu
    :titulo "Painel de controlo"
    :grupos (lambda ()
              (list (cons "Rede e Bluetooth" (painel-opcoes 0))
                    (cons "Energia e ecrã"   (painel-opcoes 1)))))))
