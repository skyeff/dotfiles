;;; -*- mode: lisp; -*-
;;; interface.lisp — o que se vê: fonte, cores, aparência geral, barra,
;;; lançador de aplicações e avisos de volume/brilho. Valores em vars.lisp.
;;; Lido por config, depois dos módulos (swm-gaps) e do Quicklisp.

(in-package :stumpwm)

;;;; =====================================================================
;;;; 1. FONTE — Hack Nerd Font via ttf-fonts
;;;; =====================================================================
;; Fonte TTF. *ttf-ok* decide se a barra usa glifos Nerd Font.
(defvar *ttf-ok* nil)
(defvar *fontes-barra* nil
  "Fontes (texto, ícones) da barra; servem também para medir larguras.")

(defun registar-dirs-fontes ()
  "O clx-truetype só varre /usr/share/fonts e ~/.fonts; acrescenta os teus."
  (let ((v (sym "XFT" "*FONT-DIRS*")))
    (dolist (d *cfg-fonte-dirs*)
      (pushnew (namestring (merge-pathnames d (user-homedir-pathname)))
               (symbol-value v) :test #'string=))))

(defun escolher-fonte ()
  "Primeira (família . estilo) existente no cache; regista as famílias Hack."
  (let* ((familias (funcall (sym "XFT" "GET-FONT-FAMILIES")))
         (hack (remove-if-not (lambda (f) (search "hack" f :test #'char-equal))
                              familias)))
    (rc-log "famílias Hack no cache: ~s" hack)
    (dolist (f *cfg-fonte-familias*)
      (let ((fam (find f familias :test #'string-equal)))
        (when fam
          (let ((subs (funcall (sym "XFT" "GET-FONT-SUBFAMILIES") fam)))
            (return (cons fam (or (find *cfg-fonte-estilo* subs :test #'string-equal)
                                  (find "Regular" subs :test #'string-equal)
                                  (first subs))))))))))

(defun criar-fontes ()
  (let ((esc (escolher-fonte)))
    (unless esc
      (error "nenhuma de ~s no cache (ver linha 'famílias Hack')"
             *cfg-fonte-familias*))
    (rc-log "fonte escolhida: ~a / ~a" (car esc) (cdr esc))
    (flet ((fonte (tam)
             (make-instance (sym "XFT" "FONT")
                            :family (car esc) :subfamily (cdr esc) :size tam)))
      ;; Mesma família (Mono: cada ícone cabe na sua célula), dois tamanhos:
      ;; ^f0 texto, ^f1 ícones.
      (setf *fontes-barra* (list (fonte *cfg-fonte-tamanho*)
                                 (fonte *cfg-fonte-icones*)))
      (set-font *fontes-barra*))))

;; Cada etapa é registada à parte: o log diz exactamente onde falhou.
(setf *ttf-ok*
      (and (rc-try "ttf 1/4 quickload clx-truetype" (ql-carregar "clx-truetype") t)
           (rc-try "ttf 2/4 load-module ttf-fonts"  (load-module "ttf-fonts") t)
           (rc-try "ttf 3/4 xft:cache-fonts"
             (registar-dirs-fontes)
             (funcall (sym "XFT" "CACHE-FONTS"))
             t)
           (rc-try "ttf 4/4 set-font (família/estilo?)" (criar-fontes) t)))

(unless *ttf-ok*
  (rc-try "fonte-core" (set-font *cfg-fonte-core*)))

(defun icone (codigo &optional (texto ""))
  "Glifo Nerd Font CODIGO na fonte de ícones (^f1); sem TTF, devolve TEXTO."
  (if *ttf-ok* (format nil "^f1~c^f0" (code-char codigo)) texto))

;;;; =====================================================================
;;;; 2. CORES
;;;; =====================================================================

;; ^0 texto, ^1 fundo, ^2 acento, ^3 cinza; ^4..^9 repetem o texto
(setf *colors* (append (list *cfg-cor-texto* *cfg-cor-fundo*
                             *cfg-cor-acento* *cfg-cor-cinza*)
                       (make-list 6 :initial-element *cfg-cor-texto*)))

(defparameter *mode-line-bg-color* *cfg-barra-fundo*)
(defparameter *mode-line-fg-color* *cfg-barra-texto*)
(defparameter *msg-bg-color*       *cfg-cor-fundo*)
(defparameter *msg-fg-color*       *cfg-cor-texto*)
(defparameter *msg-border-color*   *cfg-cor-borda-msg*)

;;;; =====================================================================
;;;; 3. GERAL — mensagens, rato, gaps, bordas
;;;; =====================================================================

(setf *timeout-wait* *cfg-timeout-msg*)
(setf *ignore-wm-inc-hints* t)
(setf *window-format* "%m%n%s%20t")          ; trunca o nome a 20 letras
(setf *mouse-focus-policy* *cfg-foco-rato*)
(setf *group-format* *cfg-grupo-formato*)
(setf *resize-increment* *cfg-resize-passo*)
(setf *message-window-gravity* *cfg-msg-gravidade*)
(setf *input-window-gravity* :center)

(set-bg-color *msg-bg-color*)
(set-fg-color *msg-fg-color*)
(set-border-color *msg-border-color*)
(set-msg-border-width *cfg-borda-msg*)
(setf *message-window-padding* *cfg-msg-padding*)

;; Gaps (swm-gaps é carregado em 3; pacote ligado tardiamente)
(rc-try "gaps"
  (setf (symbol-value (sym "SWM-GAPS" "*INNER-GAPS-SIZE*")) *cfg-gap-interno*)
  (setf (symbol-value (sym "SWM-GAPS" "*OUTER-GAPS-SIZE*")) *cfg-gap-externo*))

(setf *startup-message* "^2StumpWM^n pronto   —   ^2C-z SPC^n aplicações   ^2C-z ?^n ajuda   ^2C-z x^n comandos")

;; Bordas: nenhuma em mosaico (nem em fullscreen); flutuantes pretas.
;; Com largura 0 o fullscreen não tem onde mostrar borda; com largura > 0
;; a janela focada ganha borda rosa, fullscreen incluído.
(rc-try "bordas"
  (setf *window-border-style* :tight
        *normal-border-width*    *cfg-borda-largura*
        *maxsize-border-width*   *cfg-borda-largura*
        *transient-border-width* *cfg-borda-largura*)
  (set-focus-color *cfg-cor-acento*)
  (set-unfocus-color *cfg-cor-fundo*)
  (set-float-focus-color *cfg-cor-fundo*)
  (set-float-unfocus-color *cfg-cor-fundo*)
  (set-win-bg-color *cfg-cor-fundo*))

;; Rato em janelas flutuantes: Mod+botão 1 move, Mod+botão 3 redimensiona
(rc-try "rato-flutuantes"
  (setf *float-window-modifier* *cfg-rato-mod*))

;;;; =====================================================================
;;;; 4. BARRA — só no monitor *cfg-barra-largura* x *-altura*
;;;; =====================================================================

(setf *mode-line-timeout* 1)
(setf *mode-line-border-width* 0)
(setf *mode-line-pad-y* *cfg-barra-padding-y*)
(setf *mode-line-pad-x* *cfg-barra-padding-x*)
(setf *mode-line-position* *cfg-barra-posicao*)   ; :top ou :bottom (vars.lisp)

(setf *mode-line-background-color* *mode-line-bg-color*)
(setf *mode-line-border-color*     *mode-line-bg-color*)
(setf *mode-line-foreground-color* *mode-line-fg-color*)

;;; Lado direito: monitor  HD  fone  wifi  BAT  data/hora  power (monitor e HD só quando existem). Leitura de /sys, /proc, pactl.
;;; Cores: ^3 cinza (ícones e rótulos), branco (valores), ^2 rosa (alerta).
(defvar *estado-bateria* "")
(defvar *estado-rede* "")
(defvar *estado-audio* "")
(defvar *estado-drive* "")      ; ícone do HD: só com unidade montada (utilities/discos.lisp)
(defvar *estado-monitor* "")    ; ícone do monitor: só com ecrã extra (utilities/monitores.lisp)

(defun ler-linha (caminho)
  (with-open-file (s caminho :if-does-not-exist nil)
    (and s (read-line s nil nil))))

(defun palavras (str)
  "Separa STR em palavras por espaços/tabs."
  (let ((out '()) (ini nil))
    (loop for i from 0 to (length str)
          for c = (and (< i (length str)) (char str i))
          do (if (and c (not (member c '(#\Space #\Tab))))
                 (unless ini (setf ini i))
                 (when ini (push (subseq str ini i) out) (setf ini nil))))
    (nreverse out)))

(defun achar-bateria ()
  "Nome da bateria em /sys/class/power_supply: a configurada ou a detectada."
  (find-if (lambda (n)
             (and n (probe-file
                     (format nil "/sys/class/power_supply/~a/capacity" n))))
           (cons *cfg-bateria* '("BAT0" "BAT1" "BATT" "CMB0" "CMB1"))))

(defun fmt-bateria ()
  "BAT 88%: rótulo cinza, valor branco. Rosa: rótulo a carregar, valor <= 15%."
  (let ((nome (achar-bateria)))
    (if (null nome)
        ""
        (let* ((dir (format nil "/sys/class/power_supply/~a/" nome))
               (cap (parse-integer
                     (or (ler-linha (concatenate 'string dir "capacity")) "")
                     :junk-allowed t))
               (st (or (ler-linha (concatenate 'string dir "status")) "")))
          (if (null cap)
              ""
              (format nil "~aBAT^n~a~a~d%^n"
                      (if (string= st "Charging") "^2" "^3")
                      *cfg-espaco-icone*
                      (if (<= cap 15) "^2" "")
                      cap))))))

(defun fmt-rede ()
  "Ícone cinza e qualidade do Wi-Fi em branco (/proc/net/wireless, escala 0-70)."
  (with-open-file (s "/proc/net/wireless" :if-does-not-exist nil)
    (if (null s)
        ""
        (progn
          (read-line s nil nil) (read-line s nil nil)
          (let ((l (read-line s nil nil)))
            (if (null l)
                ""
                (let ((q (parse-integer (or (third (palavras l)) "")
                                        :junk-allowed t)))
                  (if (and q (plusp q))
                      (format nil "^3~a^n~a~d%" (icone #xF1EB "WiFi")
                              *cfg-espaco-icone* (min 100 (round (* q 100) 70)))
                      (format nil "^2~a^n" (icone #xF1EB "WiFi"))))))))))

(defparameter *dias-pt*                ; "Sáb" sem depender da codificação do rc
  (vector "Seg" "Ter" "Qua" "Qui" "Sex"
          (coerce (list #\S (code-char 225) #\b) 'string) "Dom"))
(defparameter *meses-pt*
  #("Jan" "Fev" "Mar" "Abr" "Mai" "Jun" "Jul" "Ago" "Set" "Out" "Nov" "Dez"))

(defun fmt-hora ()
  "Ícone de calendário cinza, depois 22:06, Qui 27 Jul (hora local)."
  (multiple-value-bind (seg min hora dia mes ano dow)
      (decode-universal-time (get-universal-time))
    (declare (ignore seg ano))
    (format nil "^3~a^n~a~2,'0d:~2,'0d, ~a ~d ~a"
            (icone #xF073 "") *cfg-espaco-icone* hora min
            (aref *dias-pt* dow) dia (aref *meses-pt* (1- mes)))))

(defun texto-audio (pct mudo)
  "Fone cinza e volume em branco; mudo: tudo rosa. Vazio sem leitura."
  (cond ((null pct) "")
        (mudo (format nil "^2~a^n~amudo" (icone #xF025 "FONE") *cfg-espaco-icone*))
        (t (format nil "^3~a^n~a~d%" (icone #xF025 "FONE") *cfg-espaco-icone* pct))))

(defun fmt-audio ()
  (multiple-value-bind (pct mudo) (estado-volume)
    (texto-audio pct mudo)))

(defun fmt-power ()
  "Botão de energia: ícone cinza (o clique está em teclas.lisp)."
  (format nil "^3~a^n" (icone #xF011 "OFF")))

(defun atualizar-estado ()
  (flet ((seguro (f) (handler-case (funcall f) (error () ""))))
    (setf *estado-bateria* (seguro #'fmt-bateria)
          *estado-rede*    (seguro #'fmt-rede)
          *estado-audio*   (seguro #'fmt-audio))))

(rc-log "bateria detectada: ~a" (achar-bateria))

(defvar *timer-estado* nil)
(when *timer-estado* (ignore-errors (cancel-timer *timer-estado*)))
(setf *timer-estado*
      (run-with-timer 0 *cfg-intervalo-estado* #'atualizar-estado))

(defun juntar-com (itens)
  "ITENS: lista de (TEXTO . ESPAÇO-ANTES). Salta vazios; o 1.º não leva espaço."
  (with-output-to-string (o)
    (let ((primeiro t))
      (dolist (i itens)
        (unless (string= (car i) "")
          (unless primeiro (write-string (cdr i) o))
          (write-string (car i) o)
          (setf primeiro nil))))))

(defun segmentos-direita ()
  "Segmentos do lado direito, da esquerda para a direita, sem os vazios:
lista de (ID TEXTO ESPAÇO-ANTES). Serve a barra e o teste de cliques."
  (remove-if (lambda (s) (string= (second s) ""))
             (list (list :swank   (seg-swank) "")
                   (list :monitor *estado-monitor*  *cfg-espaco-seg*)
                   (list :drive   *estado-drive*    *cfg-espaco-seg*)
                   (list :audio   *estado-audio*    *cfg-espaco-seg*)
                   (list :rede    *estado-rede*     *cfg-espaco-seg*)
                   (list :bateria *estado-bateria*  *cfg-espaco-seg*)
                   (list :hora    (handler-case (fmt-hora) (error () ""))
                         *cfg-espaco-hora*)
                   (list :power   (fmt-power)       *cfg-espaco-power*))))

(add-screen-mode-line-formatter
 #\Z (lambda (ml)
       (declare (ignore ml))
       (juntar-com (mapcar (lambda (s) (cons (second s) (third s)))
                           (segmentos-direita)))))

;;; Geometria: em que pixels cai cada segmento. O bloco direito é alinhado
;;; por ^>, por isso mede-se da margem direita para trás, com a largura real
;;; do texto nas fontes da barra (^f0 texto, ^f1 ícones).
(defun largura-px (str)
  "Largura em pixels de STR (com códigos ^) nas fontes da barra."
  (let ((fontes (or *fontes-barra* (list (screen-font (current-screen)))))
        (fi 0) (total 0) (i 0) (n (length str))
        (run (make-string-output-stream)))
    (flet ((fechar ()
             (let ((s (get-output-stream-string run)))
               (when (plusp (length s))
                 (incf total (text-line-width (or (nth fi fontes) (first fontes))
                                              s))))))
      (loop while (< i n)
            do (let ((c (char str i)))
                 (if (and (char= c #\^) (< (1+ i) n))
                     (let ((d (char str (1+ i))))
                       (cond ((char= d #\^) (write-char #\^ run) (incf i 2))
                             ((and (char= d #\f) (< (+ i 2) n)
                                   (digit-char-p (char str (+ i 2))))
                              (fechar)
                              (setf fi (digit-char-p (char str (+ i 2))))
                              (incf i 3))
                             (t (incf i 2))))
                     (progn (write-char c run) (incf i)))))
      (fechar))
    total))

(defun zonas-direita (largura)
  "Lista de (ID X0 X1), em pixels, numa barra de LARGURA px."
  (let* ((medidas (loop for s in (segmentos-direita)
                        for primeiro = t then nil
                        collect (list (first s)
                                      (if primeiro 0 (largura-px (third s)))
                                      (largura-px (second s)))))
         (total (reduce #'+ medidas :key (lambda (m) (+ (second m) (third m)))))
         (x (- largura *mode-line-pad-x* total))
         (zonas '()))
    (dolist (m medidas (nreverse zonas))
      (destructuring-bind (id sep w) m
        (incf x sep)
        (push (list id (- x (floor sep 2)) (+ x w (floor sep 2))) zonas)
        (incf x w)))))

(defun segmento-em (x largura)
  "ID do segmento do lado direito sob a coordenada X da barra, ou NIL."
  (loop for (id x0 x1) in (zonas-direita largura)
        when (<= x0 x x1) return id))

;;; ---------------------------------------------------------------------
;;; Janelas de TODAS as cabeças na barra: primeiro as desta, depois as das
;;; outras (cinzentas, antecedidas de um ícone de monitor).
;;;
;;; Cliques: o StumpWM só entrega um clique a uma região que o texto da barra
;;; declare com ^(:on-click ID args)...^(:on-click-end). O %W de origem faz-o
;;; para cada janela; este formatador próprio tem de o fazer também, senão a
;;; barra mostra as janelas mas não reage ao rato.
(defun clicar-janela (code id &rest resto)
  "Clique numa janela da barra: o botão esquerdo foca-a (também noutra cabeça).
O %W de origem ainda renumera com a roda, flutua com o do meio e FECHA a
janela com o direito; aqui só o esquerdo actua, para não fechar nada por
engano."
  (declare (ignore resto))
  (when (eq (decode-button-code code) :left-button)
    (let ((w (window-by-id id)))
      (when w
        (focus-all w)
        (update-mode-lines (current-screen))))))

(when (fboundp 'register-ml-on-click-id)
  (register-ml-on-click-id :janela-clique #'clicar-janela))

(defun clicavel (texto w)
  "TEXTO como região clicável da barra, ligada à janela W. Sem suporte a
:on-click nesta versão do StumpWM, devolve TEXTO tal como veio."
  (if (fboundp 'format-with-on-click-id)
      (format-with-on-click-id texto :janela-clique (window-id w))
      texto))

(defun fmt-janelas-todas (ml)
  (handler-case
      (let* ((grupo (current-group (mode-line-screen ml)))
             (aqui  (sort1 (copy-list (head-windows grupo (mode-line-head ml)))
                           #'< :key #'window-number))
             (fora  (sort1 (set-difference (group-windows grupo) aqui)
                           #'< :key #'window-number)))
        (flet ((item (w)
                 (let ((s (format-expand *window-formatters* *window-format* w)))
                   (clicavel (if (eq w (current-window)) (fmt-highlight s) s)
                             w))))
          (format nil "~{~a~^ ~}~@[~a~]"
                  (mapcar #'item aqui)
                  (when fora
                    (format nil "~:[~; ~]^3~a ~{~a~^ ~}^n"
                            aqui (icone #xF108 "ext") (mapcar #'item fora))))))
    (error () "")))

(add-screen-mode-line-formatter #\V 'fmt-janelas-todas)

(setf *screen-mode-line-format*
      (list "^2[^n%g^2]^n"    ; grupos (rosa só nos parênteses)
            *cfg-separador*
            "%V"             ; janelas de todas as cabeças
            "^>"             ; alinhar à direita
            "%Z"))           ; wifi  BAT  data/hora

(defun cabeca-da-barra (screen)
  "A cabeça com a resolução do painel; na falta dela, a primeira."
  (let ((cabs (screen-heads screen)))
    (or (find-if (lambda (h)
                   (and (= (head-width h) *cfg-barra-largura*)
                        (= (head-height h) *cfg-barra-altura*)))
                 cabs)
        (first cabs))))

(defun garantir-barra ()
  "Cria a barra na cabeça certa, se ainda não existir."
  (let* ((scr (current-screen))
         (cab (cabeca-da-barra scr)))
    (dolist (h (screen-heads scr))
      (rc-log "cabeça ~d: ~dx~d~a" (head-number h) (head-width h) (head-height h)
              (if (eq h cab) "  [barra]" "")))
    (unless (head-mode-line cab)
      (toggle-mode-line scr cab))))

(defun recriar-barra ()
  "Destrói e recria a barra (depois de as cabeças mudarem)."
  (ignore-errors (destroy-all-mode-lines))
  (garantir-barra))

(rc-try "barra" (garantir-barra))

;;;; =====================================================================
;;;; 5. LANÇADOR — menu de aplicações (C-z SPC)
;;;; =====================================================================
;;; ---------------------------------------------------------------------
;;; Lançador estilo Spotlight: barra larga, a escrever logo, resultados
;;; filtrados em directo (todas as palavras, sem distinguir maiúsculas).
;;; Enter lança o PRIMEIRO resultado; sem resultados, corre o texto como comando.
;;; Fonte: ficheiros .desktop (Name + Exec).

(defun expandir-til (caminho)
  (if (and (> (length caminho) 1) (string= "~/" caminho :end2 2))
      (concatenate 'string (namestring (user-homedir-pathname)) (subseq caminho 2))
      caminho))

(defun limpar-exec (exec)
  "Remove os códigos de campo do .desktop (%f %U ...); %% passa a %."
  (with-output-to-string (o)
    (loop with i = 0
          while (< i (length exec))
          do (let ((c (char exec i)))
               (cond ((and (char= c #\%) (< (1+ i) (length exec)))
                      (when (char= (char exec (1+ i)) #\%) (write-char #\% o))
                      (incf i 2))
                     (t (write-char c o) (incf i)))))))

(defun ler-desktop (caminho)
  "(NOME . COMANDO) de um .desktop de aplicação visível; NIL caso contrário."
  (let ((nome nil) (exec nil) (terminal nil) (esconder nil) (tipo nil) (dentro nil))
    (handler-case
        (with-open-file (s caminho :external-format '(:utf-8 :replacement #\?)
                                   :if-does-not-exist nil)
          (when s
            (loop for linha = (read-line s nil nil)
                  while linha
                  do (let ((l (string-trim '(#\Space #\Tab #\Return) linha)))
                       (cond ((string= l "[Desktop Entry]") (setf dentro t))
                             ((and (plusp (length l)) (char= (char l 0) #\[))
                              (when dentro (return)))
                             (dentro
                              (let ((p (position #\= l)))
                                (when p
                                  (let ((k (subseq l 0 p)) (v (subseq l (1+ p))))
                                    (cond ((string= k "Name") (unless nome (setf nome v)))
                                          ((string= k "Exec") (unless exec (setf exec v)))
                                          ((string= k "Type") (setf tipo v))
                                          ((string= k "Terminal")
                                           (setf terminal (string-equal v "true")))
                                          ((or (string= k "NoDisplay") (string= k "Hidden"))
                                           (when (string-equal v "true")
                                             (setf esconder t)))))))))))))
      (error () (return-from ler-desktop nil)))
    (when (and nome exec (not esconder) (or (null tipo) (string= tipo "Application")))
      (let ((cmd (string-trim " " (limpar-exec exec))))
        (cons nome (if terminal (format nil "~a -e ~a" *cfg-terminal* cmd) cmd))))))

(defun lista-aplicacoes ()
  "Alist (NOME . COMANDO), sem repetidos, por ordem alfabética."
  (let ((vistos (make-hash-table :test 'equalp)) (res '()))
    (dolist (d *cfg-dirs-apps*)
      (dolist (f (ignore-errors
                  (directory (concatenate 'string (expandir-til d) "*.desktop")
                             :resolve-symlinks nil)))
        (let ((e (ler-desktop f)))
          (when (and e (not (gethash (car e) vistos)))
            (setf (gethash (car e) vistos) t)
            (push e res)))))
    (sort res #'string-lessp :key #'car)))

(defun refinar-apps (str candidatos)
  "Filtro do lançador: todas as palavras de STR contidas no nome (sem
distinguir maiúsculas); os que começam por STR vêm primeiro."
  (let* ((q (string-downcase (string-trim " " str)))
         (ps (palavras q))
         (nome (lambda (c) (string-downcase (if (listp c) (car c) c))))
         (acertos (remove-if-not
                   (lambda (c) (let ((n (funcall nome c)))
                                 (every (lambda (p) (search p n)) ps)))
                   candidatos)))
    (flet ((inicio (c) (let ((n (funcall nome c)))
                         (and (<= (length q) (length n))
                              (string= q n :end2 (length q))))))
      (stable-sort (copy-list acertos)
                   (lambda (a b) (and (inicio a) (not (inicio b))))))))

(defun lancar-entrada (entrada apps)
  (let* ((q (string-trim " " entrada))
         (nomes (mapcar #'car apps))
         (nome (or (find q nomes :test #'string-equal)
                   (first (refinar-apps q nomes))))
         (cmd (if nome (cdr (assoc nome apps :test #'string=)) q)))
    (message "Lançar: ~a" (or nome q))
    (run-shell-command (concatenate 'string "exec " cmd))))

(defun prompt-lancador ()
  "Duas linhas: o título, preenchido até à largura pretendida (é ele que alarga
a janela de entrada), e a linha onde se escreve."
  (let* ((font (screen-font (current-screen)))
         (larg (round (* *cfg-lancador-largura* (head-width (current-head)))))
         (um (max 1 (text-line-width font "M" :translate #'translate-id)))
         (cols (max 20 (ceiling larg um)))
         (lupa (if *ttf-ok* (string (code-char #xF002)) ">")))
    (format nil "~va~%  ~a  " cols (format nil "  ~a" *cfg-lancador-titulo*) lupa)))

(defcommand lancador () ()
  "Pesquisa de aplicações estilo Spotlight (barra larga, filtro em directo)."
  (let* ((apps (lista-aplicacoes))
         (entrada
           (let ((*input-refine-candidates-fn* #'refinar-apps)
                 (*input-completion-show-empty* t)
                 (*maximum-completions* *cfg-lancador-linhas*)
                 (*input-window-gravity* :center)
                 (*message-window-y-padding* 10))
             (read-one-line (current-screen) (prompt-lancador)
                            :completions (mapcar #'car apps)))))
    (when (and entrada (string/= (string-trim " " entrada) ""))
      (lancar-entrada entrada apps))))

;;;; =====================================================================
;;;; 6. AVISOS DE VOLUME E BRILHO — centro do ecrã, poucos segundos
;;;; =====================================================================

;;; Cada toque corre o comando, lê o estado real (pactl / brightnessctl) e
;;; mostra: ícone, barra de nível, percentagem. Parâmetros em vars.lisp.
;;; As teclas XF86 que os chamam estão em teclas.lisp.

(defun primeiro-percentual (str)
  "O inteiro colado antes do primeiro % de STR, ou NIL."
  (let ((p (position #\% str)))
    (when (and p (> p 0))
      (let ((i p))
        (loop while (and (> i 0) (digit-char-p (char str (1- i)))) do (decf i))
        (when (< i p) (parse-integer str :start i :end p))))))

(defun osd (texto)
  "Mostra TEXTO a meio do ecrã durante *cfg-osd-seg* segundos."
  (let ((*timeout-wait* *cfg-osd-seg*))
    (message "~a" texto)))

(defun barra-osd (pct)
  "Barra de *cfg-osd-largura* células: rosa até PCT, cinza no resto."
  (let* ((larg *cfg-osd-largura*)
         (cheios (round (* larg (min 100 (max 0 pct))) 100)))
    (format nil "^2~a^3~a^n"
            (make-string cheios :initial-element (code-char #x2588))
            (make-string (- larg cheios) :initial-element (code-char #x2591)))))

;;; Volume
(defun estado-volume ()
  "(values PERCENTAGEM MUDO-P) do sink por defeito."
  (values (primeiro-percentual (saida "LC_ALL=C pactl get-sink-volume @DEFAULT_SINK@"))
          (and (search "yes" (saida "LC_ALL=C pactl get-sink-mute @DEFAULT_SINK@")) t)))

(defun mostrar-volume ()
  (multiple-value-bind (pct mudo) (estado-volume)
    (setf *estado-audio* (texto-audio pct mudo))   ; a barra acompanha já
    (osd (if (null pct)
             "volume: sem leitura"
             (format nil "~a  ~a  ~d%~a"
                     (icone (cond (mudo #xF026) ((< pct 40) #xF027) (t #xF028)) "VOL")
                     (barra-osd (if mudo 0 pct))
                     pct
                     (if mudo "  ^3mudo^n" ""))))))

(defun ajustar-volume (delta)
  (when (plusp delta)                         ; subir tira do mudo
    (saida "pactl set-sink-mute @DEFAULT_SINK@ 0"))
  (saida (format nil "pactl set-sink-volume @DEFAULT_SINK@ ~@d%" delta))
  (let ((pct (estado-volume)))
    (when (and pct (> pct *cfg-volume-max*))
      (saida (format nil "pactl set-sink-volume @DEFAULT_SINK@ ~d%" *cfg-volume-max*))))
  (mostrar-volume))

;;; Brilho
(defun mostrar-brilho ()
  (let ((pct (primeiro-percentual (saida "brightnessctl -m"))))
    (osd (if pct
             (format nil "~a  ~a  ~d%" (icone #xF185 "BRI") (barra-osd pct) pct)
             "brilho: sem leitura"))))

(defun ajustar-brilho (delta)
  (saida (format nil "brightnessctl set ~d%~a" (abs delta) (if (minusp delta) "-" "+")))
  (mostrar-brilho))

(defcommand volume-mais () ()
  "Sobe o volume e mostra o aviso."
  (ajustar-volume *cfg-passo-volume*))

(defcommand volume-menos () ()
  "Baixa o volume e mostra o aviso."
  (ajustar-volume (- *cfg-passo-volume*)))

(defcommand volume-mudo () ()
  "Alterna o mudo e mostra o aviso."
  (saida "pactl set-sink-mute @DEFAULT_SINK@ toggle")
  (mostrar-volume))

(defcommand brilho-mais () ()
  "Sobe o brilho e mostra o aviso."
  (ajustar-brilho *cfg-passo-brilho*))

(defcommand brilho-menos () ()
  "Baixa o brilho e mostra o aviso."
  (ajustar-brilho (- *cfg-passo-brilho*)))

;;;; =====================================================================
;;;; 7. NOTIFICAÇÕES E HOVER — áudio, bateria, calendário
;;;; =====================================================================

;;; A barra do StumpWM não recebe eventos de movimento. Em vez deles, um
;;; temporizador consulta o ponteiro e vê sobre que segmento está; ao fim de
;;; *cfg-hover-atraso* leituras seguidas, corre a acção desse segmento.
;;; A janela da notificação é do dunst (origin/offset em dunstrc; para o
;;; calendário alinhar, a fonte do dunst tem de ser monoespaçada, como a Hack).

(defun cmd-notificar (tag titulo corpo &key icone (seg *cfg-hover-seg*))
  "Comando de shell que mostra uma notificação; TAG faz as novas substituírem as velhas."
  (format nil "notify-send -a ~a -u low -t ~d -h string:x-dunst-stack-tag:~a ~@[-i ~a ~]~a ~a"
          tag (round (* 1000 seg)) tag
          (and icone (sh-quote icone))
          (sh-quote titulo) (sh-quote corpo)))

(defun notificar (tag titulo corpo &rest chaves)
  (run-shell-command (apply #'cmd-notificar tag titulo corpo chaves)))

(defun glifo (codigo)
  "O glifo Nerd Font CODIGO como texto, para o corpo das notificações."
  (string (code-char codigo)))

;;; --- áudio: título, álbum e capa --------------------------------------------

(defun mostrar-capa ()
  "Notificação com título, álbum/artista e capa da faixa actual (playerctl)."
  (let* ((titulo (saida "playerctl metadata title 2>/dev/null"))
         (album  (saida "playerctl metadata album 2>/dev/null"))
         (artista (saida "playerctl metadata artist 2>/dev/null"))
         (url    (saida "playerctl metadata mpris:artUrl 2>/dev/null"))
         (cache  (namestring (merge-pathnames *cfg-cache-capas*
                                              (user-homedir-pathname))))
         (local  (when (eql 0 (search "http" url))
                   (format nil "~acapa-~36r.img" cache (abs (sxhash url)))))
         (imagem (cond (local local)
                       ((eql 0 (search "file://" url)) url)))
         (cmds '()))
    (when local
      (ensure-directories-exist cache)
      (push (format nil "[ -s ~a ] || curl -sfL --max-time 4 -o ~a ~a"
                    (sh-quote local) (sh-quote local) (sh-quote url))
            cmds))
    (push (cmd-notificar "audio"
                         (if (string= titulo "") "Nenhum áudio a tocar" titulo)
                         (string-trim '(#\Newline) (format nil "~a~%~a" album artista))
                         :icone imagem)
          cmds)
    (run-shell-command (format nil "~{~a~^; ~}" (nreverse cmds)))))

;;; --- bateria: estado, tempo, consumo, saúde ---------------------------------

(defun sys-num (dir nome)
  (let ((l (ler-linha (concatenate 'string dir nome))))
    (and l (parse-integer l :junk-allowed t))))

(defun fmt-duracao (horas)
  (let* ((min (round (* horas 60)))
         (h (floor min 60))
         (m (mod min 60)))
    (if (plusp h) (format nil "~dh ~2,'0dmin" h m) (format nil "~dmin" m))))

(defun mostrar-bateria ()
  (let ((nome (achar-bateria)))
    (if (null nome)
        (notificar "bateria" "Sem bateria" "Nenhuma bateria detectada" :icone "dialog-information")
        (let* ((dir (format nil "/sys/class/power_supply/~a/" nome))
               (cap (sys-num dir "capacity"))
               (st (or (ler-linha (concatenate 'string dir "status")) ""))
               (e-now (or (sys-num dir "energy_now") (sys-num dir "charge_now")))
               (e-full (or (sys-num dir "energy_full") (sys-num dir "charge_full")))
               (e-proj (or (sys-num dir "energy_full_design")
                           (sys-num dir "charge_full_design")))
               (p-now (sys-num dir "power_now"))
               (i-now (sys-num dir "current_now"))
               (taxa (or p-now i-now))            ; µW ou µA, par de e-now (µWh ou µAh)
               (volt (sys-num dir "voltage_now"))
               (ciclos (sys-num dir "cycle_count"))
               (watts (cond (p-now (/ p-now 1e6))
                            ((and i-now volt) (/ (* i-now volt) 1e12))))
               (descarga (string= st "Discharging"))
               (horas (and e-now taxa (plusp taxa)
                           (cond (descarga (/ e-now taxa))
                                 ((and (string= st "Charging") e-full)
                                  (/ (- e-full e-now) taxa)))))
               (estado (cond ((string= st "Charging")     (cons #xF0E7 "A carregar"))
                             (descarga                    (cons #xF242 "A descarregar"))
                             ((string= st "Full")         (cons #xF240 "Carga completa"))
                             ((string= st "Not charging") (cons #xF1E6 "Ligada à corrente"))
                             (t                           (cons #xF240 st)))))
          (notificar "bateria"
                     (format nil "~a  Bateria ~@[~d%~]" (glifo #xF240) cap)
                     (format nil "~{~a~^~%~}"
                             (remove nil
                                     (list
                                      (format nil "~a  ~a" (glifo (car estado)) (cdr estado))
                                      (and horas
                                           (format nil "~a  ~a ~a" (glifo #xF017)
                                                   (fmt-duracao horas)
                                                   (if descarga "restantes" "para carregar")))
                                      (and watts (format nil "~a  ~,1f W" (glifo #xF0E4) watts))
                                      (and e-full e-proj (plusp e-proj)
                                           (format nil "~a  Saúde ~d%" (glifo #xF004)
                                                   (round (* 100 e-full) e-proj)))
                                      (and ciclos (plusp ciclos)
                                           (format nil "~a  ~d ciclos" (glifo #xF021) ciclos))
                                      (and volt (format nil "~a  ~,2f V" (glifo #xF0E7)
                                                        (/ volt 1e6))))))
                     :icone "battery")))))

;;; --- data: calendário do mês ------------------------------------------------

(defparameter *meses-longos-pt*
  (vector "Janeiro" "Fevereiro"
          (coerce (list #\M #\a #\r (code-char 231) #\o) 'string)   ; "Março"
          "Abril" "Maio" "Junho" "Julho" "Agosto" "Setembro" "Outubro"
          "Novembro" "Dezembro"))

(defun dias-no-mes (ano mes)
  (case mes
    ((4 6 9 11) 30)
    (2 (if (and (zerop (mod ano 4)) (or (plusp (mod ano 100)) (zerop (mod ano 400))))
           29 28))
    (t 31)))

(defun linhas-calendario (ano mes hoje)
  "Linhas do mês (segunda a domingo), com o dia HOJE a negrito e sublinhado."
  (let* ((inicio (nth-value 6 (decode-universal-time
                               (encode-universal-time 0 0 0 1 mes ano 0) 0)))
         (n (dias-no-mes ano mes))
         (linhas (list (format nil "~{~a~^ ~}" (coerce *dias-pt* 'list))))
         (atual '()))
    (dotimes (c (* 7 (ceiling (+ inicio n) 7)))
      (let ((d (+ (- c inicio) 1)))
        (push (cond ((or (< d 1) (> d n)) "   ")
                    ((eql d hoje) (format nil "~a<u><b>~d</b></u>" (if (< d 10) "  " " ") d))
                    (t (format nil "~3d" d)))
              atual)
        (when (= (length atual) 7)
          (push (format nil "~{~a~^ ~}" (reverse atual)) linhas)
          (setf atual '()))))
    (nreverse linhas)))

(defun mostrar-calendario ()
  (multiple-value-bind (seg min hora dia mes ano) (get-decoded-time)
    (declare (ignore seg min hora))
    (notificar "calendario"
               (format nil "~a ~d" (aref *meses-longos-pt* (1- mes)) ano)
               (format nil "~{~a~^~%~}" (linhas-calendario ano mes dia))
               :icone "x-office-calendar" :seg (* 1.5 *cfg-hover-seg*))))

;;; --- ponteiro sobre a barra -------------------------------------------------

(defparameter *hover-acoes*
  (list (cons :audio 'mostrar-capa)
        (cons :bateria 'mostrar-bateria)
        (cons :hora 'mostrar-calendario))
  "Segmento -> função chamada ao pairar sobre ele.")

(defvar *hover-ultimo* nil)
(defvar *hover-contagem* 0)
(defvar *timer-hover* nil)

(defun ponteiro-na-barra ()
  "(values X LARGURA) do ponteiro sobre a barra principal, ou NIL."
  (let* ((scr (current-screen))
         (ml (head-mode-line (cabeca-da-barra scr))))
    (when ml
      (let ((win (mode-line-window ml)))
        (multiple-value-bind (rx ry mesmo-ecra filho)
            (xlib:query-pointer (screen-root scr))
          (declare (ignore ry))
          (when (and mesmo-ecra filho (xlib:window-equal filho win))
            (values (- rx (xlib:drawable-x win))
                    (xlib:drawable-width win))))))))

(defun verificar-hover ()
  (ignore-errors
   (multiple-value-bind (x largura) (ponteiro-na-barra)
     (let* ((seg (and x (segmento-em x largura)))
            (acao (and seg (cdr (assoc seg *hover-acoes*)))))
       (cond ((null acao)
              (setf *hover-ultimo* nil *hover-contagem* 0))
             ((eq seg *hover-ultimo*)
              (when (= (incf *hover-contagem*) *cfg-hover-atraso*)
                (funcall acao)))
             (t (setf *hover-ultimo* seg *hover-contagem* 1)))))))

(when *timer-hover* (ignore-errors (cancel-timer *timer-hover*)))
(setf *timer-hover*
      (run-with-timer 0.5 *cfg-hover-intervalo* #'verificar-hover))
