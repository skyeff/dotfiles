;;; -*- mode: lisp; -*-
;;; utilities/monitores.lisp — conversão de ~/.local/bin/monitores para Lisp.
;;;
;;; O script original dispunha os ecrãs lado a lado: interno (eDP/LVDS/DSI) à
;;; esquerda e primário, os restantes à direita, sem depender dos nomes.
;;; Aqui a mesma regra é uma função (monitores-estender) e ganha irmãs:
;;; espelhar, só interno, só externo. Um temporizador vigia as ligações: ao
;;; ligar ou desligar um ecrã, aplica-se *cfg-monitor-auto* e a barra refaz-se.
;;; Estado exposto à barra: *estado-monitor* (ícone, só com ecrã extra).
;;; Menu e cliques: teclas.lisp. Variáveis: vars.lisp.

(in-package :stumpwm)

(defvar *monitores-ligados* :inicio
  "Nomes das saídas ligadas na última leitura (:inicio antes da primeira).")
(defvar *timer-monitores* nil)
(defvar *monitores-ultimo-erro* nil)

;;; --- leitura de `xrandr --query' ------------------------------------------

(defun modo-xrandr-p (str)
  "Verdadeiro para \"1920x1080\"; falso para \"1920x1080i\" e outros."
  (let ((x (position #\x str)))
    (and x (plusp x) (< (1+ x) (length str))
         (every #'digit-char-p (subseq str 0 x))
         (every #'digit-char-p (subseq str (1+ x))))))

(defun xrandr-saidas ()
  "Lista de (NOME LIGADA-P MODOS) de todas as saídas."
  (let ((res '()))
    (dolist (linha (split-string (saida "xrandr --query") (string #\Newline)))
      (cond ((zerop (length linha)) nil)
            ((not (member (char linha 0) '(#\Space #\Tab)))
             (let ((p (palavras linha)))
               (when (and (second p) (not (string= (first p) "Screen")))
                 (push (list (first p) (string= (second p) "connected") '()) res))))
            (res
             (let ((modo (first (palavras linha))))
               (when (and modo (modo-xrandr-p modo))
                 (push modo (third (first res))))))))
    (nreverse res)))

(defun monitores-ligados ()
  (loop for (nome ligada) in (xrandr-saidas)
        when ligada collect nome))

(defun monitor-interno-p (nome)
  (some (lambda (p) (eql 0 (search p nome))) *cfg-monitor-internos*))

(defun monitores-ordenados (nomes)
  "Internos primeiro, depois os restantes, por ordem."
  (append (remove-if-not #'monitor-interno-p nomes)
          (remove-if #'monitor-interno-p nomes)))

;;; --- aplicação -------------------------------------------------------------

(defun xrandr-aplicar (&rest clausulas)
  "Corre um único xrandr com todas as cláusulas (sem estados intermédios)."
  (let ((cmd (format nil "xrandr~{ ~a~}" clausulas)))
    (rc-log "~a" cmd)
    (saida (format nil "~a 2>&1" cmd))))

(defun atualizar-estado-monitor ()
  (setf *estado-monitor*
        (if (and (listp *monitores-ligados*) (rest *monitores-ligados*))
            (format nil "^3~a^n" (icone #xF108 "MON"))
            "")))

(defun monitores-recarregar ()
  "Faz o StumpWM reler as cabeças; depois da poeira dos eventos RandR assentar,
recria a barra e repõe o fundo."
  (ignore-errors (run-commands "refresh-heads"))
  (setf *monitores-ligados* (monitores-ligados))
  (atualizar-estado-monitor)
  (run-with-timer 0.8 nil
                  (lambda ()
                    (ignore-errors (recriar-barra))
                    (run-shell-command (format nil "feh --bg-fill ~a" *cfg-wallpaper*)))))

;;; --- disposições -----------------------------------------------------------

(defun monitores-estender (&optional (lado *cfg-monitor-lado*))
  "O script original: interno primário em 0x0, os outros ao LADO dele
(:direita :esquerda :acima :abaixo), encadeados por ordem."
  (setf *cfg-monitor-lado* lado)
  (let ((ord (monitores-ordenados (monitores-ligados))))
    (if (null ord)
        (message "Nenhum ecrã ligado")
        (let* ((interno (first ord))
               (externos (rest ord))
               (seq (if (member lado '(:direita :abaixo))
                        (cons interno externos)
                        (append (reverse externos) (list interno))))
               (rel (if (member lado '(:direita :esquerda)) "--right-of" "--below"))
               (anterior nil)
               (clausulas '()))
          (dolist (s seq)
            (push (format nil "--output ~a --auto ~a~a"
                          (sh-quote s)
                          (if anterior
                              (format nil "~a ~a" rel (sh-quote anterior))
                              "--pos 0x0")
                          (if (string= s interno) " --primary" ""))
                  clausulas)
            (setf anterior s))
          (apply #'xrandr-aplicar (nreverse clausulas))
          (monitores-recarregar)))))

(defun modos-comuns (nomes tabela)
  (let ((comuns (third (assoc (first nomes) tabela :test #'string=))))
    (dolist (n (rest nomes) comuns)
      (setf comuns (intersection comuns
                                 (third (assoc n tabela :test #'string=))
                                 :test #'string=)))))

(defun area-modo (modo)
  (let ((x (position #\x modo)))
    (* (parse-integer modo :end x) (parse-integer modo :start (1+ x)))))

(defun monitores-espelhar ()
  "Todos os ecrãs na maior resolução que partilham, sobrepostos."
  (let* ((tabela (xrandr-saidas))
         (ord (monitores-ordenados
               (loop for (n ligada) in tabela when ligada collect n)))
         (comuns (and (rest ord) (modos-comuns ord tabela))))
    (cond ((null (rest ord)) (message "Só há um ecrã ligado"))
          ((null comuns) (message "Os ecrãs não partilham nenhuma resolução"))
          (t (let ((modo (first (sort (copy-list comuns) #'> :key #'area-modo)))
                   (interno (first ord)))
               (apply #'xrandr-aplicar
                      (cons (format nil "--output ~a --mode ~a --primary --pos 0x0"
                                    (sh-quote interno) modo)
                            (mapcar (lambda (s)
                                      (format nil "--output ~a --mode ~a --same-as ~a"
                                              (sh-quote s) modo (sh-quote interno)))
                                    (rest ord))))
               (monitores-recarregar))))))

(defun monitores-so-interno ()
  (let ((ord (monitores-ordenados (monitores-ligados))))
    (if (null (rest ord))
        (message "Só há um ecrã ligado")
        (progn
          (apply #'xrandr-aplicar
                 (cons (format nil "--output ~a --auto --primary --pos 0x0"
                               (sh-quote (first ord)))
                       (mapcar (lambda (s) (format nil "--output ~a --off" (sh-quote s)))
                               (rest ord))))
          (monitores-recarregar)))))

(defun monitores-so-externo ()
  (let* ((ord (monitores-ordenados (monitores-ligados)))
         (externos (remove-if #'monitor-interno-p ord))
         (internos (remove-if-not #'monitor-interno-p ord))
         (anterior nil)
         (clausulas '()))
    (if (null externos)
        (message "Nenhum ecrã externo ligado")
        (progn
          (dolist (s externos)
            (push (format nil "--output ~a --auto ~a~a"
                          (sh-quote s)
                          (if anterior (format nil "--right-of ~a" (sh-quote anterior))
                              "--pos 0x0")
                          (if anterior "" " --primary"))
                  clausulas)
            (setf anterior s))
          (dolist (s internos)
            (push (format nil "--output ~a --off" (sh-quote s)) clausulas))
          (apply #'xrandr-aplicar (nreverse clausulas))
          (monitores-recarregar)))))

(defun monitores-auto ()
  "Disposição por omissão, ao arrancar e sempre que se liga/desliga um ecrã."
  (if (rest (monitores-ligados))
      (ecase *cfg-monitor-auto*
        (:estender (monitores-estender *cfg-monitor-lado*))
        (:espelhar (monitores-espelhar)))
      (monitores-estender)))              ; um só ecrã: primário em 0x0

;;; --- vigilância ------------------------------------------------------------

(defun tick-monitores ()
  (handler-case
      (let ((ligados (monitores-ligados)))
        (unless (equal ligados *monitores-ligados*)
          (setf *monitores-ligados* ligados)
          (rc-log "ecrãs ligados: ~{~a~^ ~}" ligados)
          (monitores-auto)))
    (error (e)
      (let ((m (princ-to-string e)))
        (unless (equal m *monitores-ultimo-erro*)
          (setf *monitores-ultimo-erro* m)
          (rc-log "monitores: ~a" m))))))

(when *timer-monitores* (ignore-errors (cancel-timer *timer-monitores*)))
(setf *timer-monitores*
      (run-with-timer 1 *cfg-monitor-intervalo* #'tick-monitores))
