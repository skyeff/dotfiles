;;; -*- mode: lisp; -*-
;;; utilities/painel.lisp — painel de controlo: Wi-Fi, Bluetooth, perfis de
;;; energia, café (o ecrã não desliga) e luz noturna.
;;;
;;; Aqui vive a lógica e o estado. O menu (C-z q c, ou clique no ícone do
;;; painel) está em teclas.lisp; os ícones da barra, em interface.lisp.
;;; Variáveis: vars.lisp (secção «Painel de controlo»).
;;;
;;; DEPENDÊNCIAS DE SISTEMA (Arch):
;;;   rfkill            util-linux (já vem)        Wi-Fi e Bluetooth ligados/desligados
;;;   impala + iwd      pacman -S impala iwd       configurar o Wi-Fi (impala só fala com iwd!)
;;;   bluez, bluez-utils  + systemctl enable --now bluetooth      bluetoothctl
;;;   blueman           pacman -S blueman          gerir dispositivos Bluetooth
;;;   power-profiles-daemon  + systemctl enable --now power-profiles-daemon
;;;   redshift          pacman -S redshift         luz noturna (gammastep serve também)
;;;   xorg-xset         (já vem)                   café
;;;   kitty             (já vem)                   janela do impala

(in-package :stumpwm)

;;; --- rádios: estado lido de /sys/class/rfkill (sem subprocessos) -----------
(defparameter *rfkill-dir* "/sys/class/rfkill/")

(defun rfkill-estado (tipo)
  "ACTIVO, BLOQUEADO, ou NIL se não há rádio do TIPO (\"wlan\" ou \"bluetooth\")."
  (let ((achou nil) (activo nil))
    (dotimes (i 16)
      (let ((dir (format nil "~arfkill~d/" *rfkill-dir* i)))
        (when (equal (ler-linha (concatenate 'string dir "type")) tipo)
          (setf achou t)
          (when (and (equal (ler-linha (concatenate 'string dir "soft")) "0")
                     (equal (ler-linha (concatenate 'string dir "hard")) "0"))
            (setf activo t)))))
    (cond ((not achou) nil) (activo :activo) (t :bloqueado))))

(defun wifi-alternar ()
  (run-shell-command
   (if (eq (rfkill-estado "wlan") :activo) "rfkill block wifi" "rfkill unblock wifi")))

(defun bluetooth-alternar ()
  (run-shell-command
   (if (eq (rfkill-estado "bluetooth") :activo)
       "bluetoothctl power off; rfkill block bluetooth"
       "rfkill unblock bluetooth; sleep 1; bluetoothctl power on")))

;;; --- perfis de energia (power-profiles-daemon) ------------------------------
(defparameter *perfis-energia*
  '(("power-saver" #xF06C "Poupança")
    ("balanced"    #xF24E "Equilibrado")
    ("performance" #xF0E4 "Desempenho"))
  "(ID ÍCONE NOME) por ordem de apresentação.")

(defun perfis-lista (texto)
  "De `powerprofilesctl list': lista de (ID . ACTIVO-P). Os perfis são as linhas
sem indentação funda, ' nome:' ou '* nome:' (o * marca o activo)."
  (let ((res '()))
    (dolist (l (split-string texto (string #\Newline)))
      (let ((n (length l)))
        (when (and (> n 3)
                   (member (char l 0) '(#\Space #\*))
                   (char= (char l 1) #\Space)
                   (not (member (char l 2) '(#\Space #\Tab)))
                   (char= (char l (1- n)) #\:))
          (push (cons (subseq l 2 (1- n)) (char= (char l 0) #\*)) res))))
    (nreverse res)))

(defun perfis-disponiveis ()
  (perfis-lista (saida "LC_ALL=C powerprofilesctl list 2>/dev/null")))

(defun perfil-definir (id)
  (run-shell-command (format nil "powerprofilesctl set ~a" id)))

;;; --- café e luz noturna: estado que a barra mostra --------------------------
(defun dpms-activo-p ()
  "O DPMS está ligado no servidor X?"
  (not (search "DPMS is Disabled" (saida "LC_ALL=C xset q 2>/dev/null"))))

(defvar *cafe-activo* (not (dpms-activo-p))
  "Café activo = ecrã sempre aceso (DPMS desligado). Lido do servidor X ao arrancar.")

(defparameter *noturna-flag*
  (concatenate 'string (or (sb-ext:posix-getenv "XDG_RUNTIME_DIR") "/tmp")
               "/stumpwm-noturna")
  "Ficheiro que lembra a luz noturna entre reinícios do StumpWM (some ao sair da sessão).")

(defvar *noturna-activa* (and (probe-file *noturna-flag*) t))

(defun atualizar-estado-modos ()
  (setf *estado-cafe*
        (if *cafe-activo* (format nil "^2~a^n" (icone *cfg-icone-cafe* "CAFE")) "")
        *estado-noturna*
        (if *noturna-activa* (format nil "^2~a^n" (icone *cfg-icone-noturna* "NOITE")) ""))
  (ignore-errors (update-mode-lines (current-screen))))

(atualizar-estado-modos)

(defun cafe-ligar ()
  (run-shell-command "xset s off; xset -dpms")
  (setf *cafe-activo* t)
  (atualizar-estado-modos))

(defun cafe-desligar ()
  (run-shell-command
   (format nil "xset s off; xset +dpms; xset dpms 0 0 ~d" *cfg-dpms-desligar*))
  (setf *cafe-activo* nil)
  (atualizar-estado-modos))

(defun noturna-ligar ()
  (run-shell-command (format nil *cfg-noturna-ligar* *cfg-noturna-temp*))
  (with-open-file (s *noturna-flag* :direction :output
                                    :if-exists :supersede :if-does-not-exist :create)
    (write-line "1" s))
  (setf *noturna-activa* t)
  (atualizar-estado-modos))

(defun noturna-desligar ()
  (run-shell-command *cfg-noturna-desligar*)
  (ignore-errors (delete-file *noturna-flag*))
  (setf *noturna-activa* nil)
  (atualizar-estado-modos))

(defcommand cafe-alternar () ()
  "Alterna o modo café: activo, o ecrã não desliga."
  (if *cafe-activo* (cafe-desligar) (cafe-ligar))
  (osd (format nil "^2~a^n  Café ~:[desligado~;ligado: o ecrã não desliga~]"
               (icone *cfg-icone-cafe* "CAFE") *cafe-activo*)))

(defcommand noturna-alternar () ()
  "Alterna a luz noturna (redshift em modo manual)."
  (if *noturna-activa* (noturna-desligar) (noturna-ligar))
  (osd (format nil "^2~a^n  Luz noturna ~:[desligada~;ligada (~dK)~]"
               (icone *cfg-icone-noturna* "NOITE") *noturna-activa* *cfg-noturna-temp*)))

;;; --- janelas dos gestores: abrem flutuantes ---------------------------------
(defun flutuar-janela-nova (w)
  (when (and (typep w 'tile-window)
             (member (window-class w) *cfg-flutuantes-classes* :test #'string-equal))
    (ignore-errors (float-window w (window-group w)))))

(add-hook *new-window-hook* 'flutuar-janela-nova)
