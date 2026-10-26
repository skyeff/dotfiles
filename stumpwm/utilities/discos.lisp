;;; -*- mode: lisp; -*-
;;; utilities/discos.lisp — pendrives e HDs externos.
;;;   · deteta-os (lsblk) de *cfg-drive-intervalo* em *cfg-drive-intervalo* s;
;;;   · monta-os em /mnt/Alpha, Beta, Gama, Delta, por esta ordem, com
;;;     `sudo -n stump-mnt` (o udisks não deixa escolher o ponto; ver
;;;     sistema/stump-mnt e a linha de sudoers);
;;;   · expõe *discos* e *estado-drive* (o ícone da barra, só com unidade montada);
;;;   · fornece as acções do menu: desmontar, remover com segurança, informação.
;;; Menu e cliques: teclas.lisp. Variáveis: vars.lisp.

(in-package :stumpwm)

(defvar *discos* nil
  "Unidades externas montadas em /mnt/<Nome>: lista de plists
(:dev :slot :ponto :fs :size :pk :etiqueta).")
(defvar *discos-tratados* nil
  "Dispositivos em que já se tentou montar, ou que o utilizador desmontou.
Só saem daqui quando o dispositivo desaparece: evita voltar a montar à força.")
(defvar *discos-reservas* nil "Alist (SLOT . INSTANTE) de montagens em curso.")
(defvar *discos-etiquetas* (make-hash-table :test 'equal))
(defvar *discos-ultimo-erro* nil)
(defvar *timer-discos* nil)

;;; --- lsblk -----------------------------------------------------------------

(defun parse-par-lsblk (linha)
  "Alist (CHAVE . VALOR) de uma linha de `lsblk -P' (CHAVE=\"valor\" ...)."
  (let ((i 0) (n (length linha)) (res '()))
    (loop
      (let ((eq (position #\= linha :start i)))
        (when (or (null eq) (>= (+ eq 2) n)) (return))
        (let ((fim (position #\" linha :start (+ eq 2))))
          (unless fim (return))
          (push (cons (string-trim " " (subseq linha i eq))
                      (subseq linha (+ eq 2) fim))
                res)
          (setf i (1+ fim)))))
    (nreverse res)))

(defun lsblk-campo (registo chave)
  (or (cdr (assoc chave registo :test #'string=)) ""))

(defun lsblk-registos ()
  (let ((res '()))
    (dolist (linha (split-string
                    (saida "lsblk -P -o NAME,PATH,PKNAME,TYPE,RM,HOTPLUG,TRAN,FSTYPE,SIZE,MOUNTPOINT")
                    (string #\Newline)))
      (let ((r (parse-par-lsblk linha)))
        (when r (push r res))))
    (nreverse res)))

(defun discos-externos (registos)
  "Partições (ou discos sem tabela) externos, com sistema de ficheiros montável."
  (let ((externos (loop for r in registos
                        when (and (string= (lsblk-campo r "TYPE") "disk")
                                  (or (string= (lsblk-campo r "RM") "1")
                                      (string= (lsblk-campo r "HOTPLUG") "1")
                                      (string= (lsblk-campo r "TRAN") "usb")))
                          collect (lsblk-campo r "NAME"))))
    (loop for r in registos
          for tipo = (lsblk-campo r "TYPE")
          when (and (member (lsblk-campo r "FSTYPE") *cfg-drive-fs* :test #'string=)
                    (or (and (string= tipo "part")
                             (member (lsblk-campo r "PKNAME") externos :test #'string=))
                        (and (string= tipo "disk")
                             (member (lsblk-campo r "NAME") externos :test #'string=))))
            collect r)))

;;; --- pontos de montagem ----------------------------------------------------

(defun slot-do-ponto (ponto)
  "Alpha, Beta... se PONTO for /mnt/<Nome>; senão NIL."
  (find-if (lambda (n) (string= ponto (concatenate 'string *cfg-drive-base* n)))
           *cfg-drive-nomes*))

(defun montagens-nossas ()
  "Alist (SLOT . DISPOSITIVO) dos pontos nossos montados, de /proc/mounts."
  (let ((res '()))
    (with-open-file (s "/proc/mounts" :if-does-not-exist nil)
      (when s
        (loop for linha = (read-line s nil nil)
              while linha
              do (let* ((campos (palavras linha))
                        (slot (and (second campos) (slot-do-ponto (second campos)))))
                   (when slot (push (cons slot (first campos)) res))))))
    (nreverse res)))

(defun reservas-ativas ()
  (let ((agora (get-universal-time)))
    (setf *discos-reservas*
          (remove-if (lambda (r) (> (- agora (cdr r)) 20)) *discos-reservas*))
    (mapcar #'car *discos-reservas*)))

(defun slot-livre (ocupados)
  (find-if-not (lambda (n) (member n ocupados :test #'string=)) *cfg-drive-nomes*))

;;; --- nomes -----------------------------------------------------------------

(defun propriedade-udev (texto chave)
  (let ((pref (concatenate 'string chave "=")))
    (dolist (l (split-string texto (string #\Newline)))
      (when (eql 0 (search pref l))
        (return (subseq l (length pref)))))))

(defun etiqueta-disco (dev)
  "Rótulo do sistema de ficheiros (ou modelo, ou \"sem nome\"), em cache."
  (or (gethash dev *discos-etiquetas*)
      (setf (gethash dev *discos-etiquetas*)
            (let* ((out (saida (format nil "udevadm info -q property -n ~a" (sh-quote dev))))
                   (rotulo (propriedade-udev out "ID_FS_LABEL"))
                   (modelo (propriedade-udev out "ID_MODEL")))
              (cond ((and rotulo (string/= rotulo "")) rotulo)
                    ((and modelo (string/= modelo "")) (substitute #\Space #\_ modelo))
                    (t "sem nome"))))))

(defun descricao-disco (d)
  (if d
      (format nil "~a  ~a  ~a ~a" (getf d :slot) (getf d :etiqueta)
              (getf d :size) (getf d :fs))
      ""))

;;; --- montagem automática ---------------------------------------------------

(defun montar-disco (dev slot fs size)
  "Monta DEV em /mnt/SLOT sem bloquear o StumpWM; notifica o resultado."
  (push dev *discos-tratados*)
  (push (cons slot (get-universal-time)) *discos-reservas*)
  (run-shell-command
   (format nil "~a mount ~a ~a && ~a || ~a"
           *cfg-drive-helper* (sh-quote dev) slot
           (cmd-notificar "drive" (format nil "~a montado" slot)
                          (format nil "~a~%~a  ~a" (etiqueta-disco dev) size fs)
                          :icone "drive-removable-media")
           (cmd-notificar "drive" "Falha ao montar"
                          (format nil "~a em ~a~a" dev *cfg-drive-base* slot)
                          :icone "dialog-error"))))

(defun atualizar-discos ()
  (let* ((regs (lsblk-registos))
         (todos (mapcar (lambda (r) (lsblk-campo r "PATH")) regs))
         (ext (discos-externos regs))
         (presentes (mapcar (lambda (r) (lsblk-campo r "PATH")) ext))
         (montagens (montagens-nossas))
         (ocupados (append (mapcar #'car montagens) (reservas-ativas))))
    ;; 1. esquecer o que desapareceu
    (setf *discos-tratados*
          (remove-if-not (lambda (d) (member d presentes :test #'string=))
                         *discos-tratados*))
    ;; 2. pontos nossos cujo dispositivo já não existe: desmonta (lazy)
    (dolist (m montagens)
      (unless (member (cdr m) todos :test #'string=)
        (run-shell-command (format nil "~a umount ~a lazy" *cfg-drive-helper* (car m)))))
    ;; 3. monta o que está por montar
    (dolist (r ext)
      (let ((dev (lsblk-campo r "PATH")))
        (when (and (string= (lsblk-campo r "MOUNTPOINT") "")
                   (not (member dev *discos-tratados* :test #'string=)))
          (let ((slot (slot-livre ocupados)))
            (if slot
                (progn (push slot ocupados)
                       (montar-disco dev slot (lsblk-campo r "FSTYPE")
                                     (lsblk-campo r "SIZE")))
                (progn (push dev *discos-tratados*)
                       (notificar "drive" "Sem ponto livre"
                                  "Alpha, Beta, Gama e Delta estão ocupados"
                                  :icone "dialog-warning")))))))
    ;; 4. estado exposto (só o que está montado num ponto nosso)
    (setf *discos*
          (loop for r in ext
                for slot = (slot-do-ponto (lsblk-campo r "MOUNTPOINT"))
                when slot
                  collect (let ((dev (lsblk-campo r "PATH"))
                                (pk (lsblk-campo r "PKNAME")))
                            (list :dev dev :slot slot
                                  :ponto (lsblk-campo r "MOUNTPOINT")
                                  :fs (lsblk-campo r "FSTYPE")
                                  :size (lsblk-campo r "SIZE")
                                  :pk (if (string= pk "") (lsblk-campo r "NAME") pk)
                                  :etiqueta (etiqueta-disco dev)))))
    (setf *estado-drive*
          (if *discos* (format nil "^3~a^n" (icone #xF0A0 "HD")) ""))))

(defun tick-discos ()
  (handler-case (atualizar-discos)
    (error (e)
      (let ((m (princ-to-string e)))
        (unless (equal m *discos-ultimo-erro*)
          (setf *discos-ultimo-erro* m)
          (rc-log "discos: ~a" m))))))

(when *timer-discos* (ignore-errors (cancel-timer *timer-discos*)))
(setf *timer-discos*
      (run-with-timer 1 *cfg-drive-intervalo* #'tick-discos))

;;; --- acções do menu --------------------------------------------------------

(defun desmontar-disco (d)
  (when d
    (pushnew (getf d :dev) *discos-tratados* :test #'string=)
    (run-shell-command
     (format nil "sync; ~a umount ~a && ~a || ~a"
             *cfg-drive-helper* (getf d :slot)
             (cmd-notificar "drive" (format nil "~a desmontado" (getf d :slot))
                            "Ainda ligado: usa «Remover» antes de o retirares"
                            :icone "drive-removable-media")
             (cmd-notificar "drive" "Não foi possível desmontar"
                            "Algum programa está a usar a unidade"
                            :icone "dialog-error")))))

(defun remover-disco (d)
  "Desmonta todas as partições do mesmo disco e desliga-o (udisksctl power-off)."
  (when d
    (let* ((pk (getf d :pk))
           (irmaos (remove-if-not (lambda (x) (string= (getf x :pk) pk)) *discos*)))
      (dolist (x irmaos)
        (pushnew (getf x :dev) *discos-tratados* :test #'string=))
      (run-shell-command
       (format nil "sync; ~{~a~^ && ~} && udisksctl power-off -b ~a && ~a || ~a"
               (mapcar (lambda (x) (format nil "~a umount ~a" *cfg-drive-helper*
                                           (getf x :slot)))
                       irmaos)
               (sh-quote (concatenate 'string "/dev/" pk))
               (cmd-notificar "drive" "Pode remover"
                              (format nil "~a já pode ser retirado" (getf d :etiqueta))
                              :icone "drive-removable-media")
               (cmd-notificar "drive" "Não foi possível remover"
                              "Fecha o que usa a unidade e tenta de novo"
                              :icone "dialog-error"))))))

(defun valor-udisks (texto chave)
  (dolist (l (split-string texto (string #\Newline)))
    (let ((l (string-trim '(#\Space #\Tab) l)))
      (when (eql 0 (search chave l))
        (return (string-trim '(#\Space #\Tab) (subseq l (length chave))))))))

(defun info-disco (d)
  "Ficha da unidade (udisksctl info), numa janela de mensagem."
  (when d
    (let* ((info (saida (format nil "udisksctl info -b ~a" (sh-quote (getf d :dev)))))
           (linhas (list (format nil "^2~a^n" (descricao-disco d))
                         ""
                         (format nil "^3~12a^n~a" "Dispositivo" (getf d :dev))
                         (format nil "^3~12a^n~a" "Montada em" (getf d :ponto))
                         (format nil "^3~12a^n~a" "Etiqueta" (getf d :etiqueta))
                         (format nil "^3~12a^n~a" "Sistema" (getf d :fs))
                         (format nil "^3~12a^n~a" "Tamanho" (getf d :size))
                         (format nil "^3~12a^n~a" "UUID" (or (valor-udisks info "IdUUID:") "?"))
                         (format nil "^3~12a^n~a" "Só leitura"
                                 (or (valor-udisks info "ReadOnly:") "?")))))
      (let ((*timeout-wait* 8))
        (message "~a" (format nil "~{~a~^~%~}" linhas))))))

(defcommand discos-remontar () ()
  "Esquece as unidades desmontadas à mão: voltam a ser montadas automaticamente."
  (setf *discos-tratados* nil)
  (message "As unidades externas voltam a ser montadas"))
