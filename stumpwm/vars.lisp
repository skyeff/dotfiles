;;; -*- mode: lisp; -*-
;;; vars.lisp — TODAS as variáveis que se ajustam: cores, fontes, posição e
;;; altura da barra, gaps, grupos, passos, programas. Aqui não corre lógica;
;;; os outros ficheiros só as lêem. Depois de mudar um valor: C-z q l
;;; (recarrega). A posição da barra pede ainda C-z v b duas vezes.

(in-package :stumpwm)

;;;; =====================================================================
;;;; 0. PAINEL DE PARÂMETROS — tudo o que se ajusta com frequência
;;;; =====================================================================

;;; Paleta: preto, branco e rosa; o cinza só serve a barra (^3).
;;; ^0 texto, ^1 fundo, ^2 acento, ^3 cinza
(defparameter *cfg-cor-fundo*     "#262626")   ; preto suave
(defparameter *cfg-cor-texto*     "#ebebf0")   ; branco
(defparameter *cfg-cor-acento*    "#f4a6c8")   ; rosa: uso parcimonioso
(defparameter *cfg-cor-cinza*     "#8a8a8a")   ; só ícones e rótulos da barra
(defparameter *cfg-cor-borda-msg* *cfg-cor-acento*)

;;; Cores da barra (por defeito herdam as gerais)
(defparameter *cfg-barra-fundo* *cfg-cor-fundo*)
(defparameter *cfg-barra-texto* *cfg-cor-texto*)
(defparameter *cfg-separador*     "    ")       ; entre grupos e janelas (esq.)
(defparameter *cfg-espaco-icone*  " ")          ; entre ícone/rótulo e valor
(defparameter *cfg-espaco-seg*    "  ")        ; entre wifi, bateria (dir.)
(defparameter *cfg-espaco-hora*   "  ")         ; entre bateria e data/hora
(defparameter *cfg-espaco-power*  "  ")       ; entre data/hora e o botão de energia

;;; Fonte (Hack Nerd Font via ttf-fonts; sem ela, cai na fonte core)
(defparameter *cfg-fonte-familias*             ; tenta por ordem; a Mono mete
  '("Hack Nerd Font Mono" "Hack Nerd Font"     ; cada ícone numa só célula
    "Hack Nerd Font Propo"))
(defparameter *cfg-fonte-dirs* '(".local/share/fonts/")) ; relativos a ~
(defparameter *cfg-fonte-estilo*   "Bold")     ; "Regular" ou "Bold"
(defparameter *cfg-fonte-tamanho*  13)         ; texto
(defparameter *cfg-fonte-icones*   18)         ; ícones (se cortarem: baixa isto
                                               ; ou sobe *cfg-barra-padding-y*)
(defparameter *cfg-fonte-core*     "-xos4-terminus-medium-r-normal--20-*-*-*-*-*-*-*")

;;; Barra
(defparameter *cfg-barra-posicao*  :top)       ; :top (cima) ou :bottom (baixo)
(defparameter *cfg-barra-padding-y* 1)         ; altura extra (px)
(defparameter *cfg-barra-padding-x* 8)
(defparameter *cfg-bateria*        nil)        ; nil = detecta (BAT0, BAT1...)
(defparameter *cfg-intervalo-estado* 10)       ; segundos entre leituras

;;; Menu de aplicações estilo Spotlight (C-z SPC)
(defparameter *cfg-lancador-titulo*  "Pesquisar aplicações")
(defparameter *cfg-lancador-largura* 0.5)      ; fracção da largura do ecrã
(defparameter *cfg-lancador-linhas*  9)        ; linhas de resultados (+1 de aviso)
(defparameter *cfg-dirs-apps*                  ; onde estão os .desktop
  '("/usr/share/applications/" "~/.local/share/applications/"
    "/var/lib/flatpak/exports/share/applications/"))

;;; Monitores: a barra vai para a cabeça com esta resolução
;;; (se nenhuma coincidir, para a primeira cabeça)
(defparameter *cfg-barra-largura* 1920)
(defparameter *cfg-barra-altura*  1080)

;;; Gaps
(defparameter *cfg-gap-interno* 5)
(defparameter *cfg-gap-externo* 1)

;;; Grupos (1.º renomeia o actual; 2.º em fundo; 3.º flutuante)
(defparameter *cfg-grupos* '("1-alpha" "2-beta" "3-gama"))
(defparameter *cfg-grupo-formato* "%t")        ; só o nome (%n nº, %s estado)

;;; Redimensionar por teclado
(defparameter *cfg-resize-passo* 20)           ; px por toque em molduras
(defparameter *cfg-resize-flut* 40)            ; px por toque em flutuantes (tamanho e posição)

;;; Avisos de volume e brilho (centro do ecrã, poucos segundos)
(defparameter *cfg-osd-seg*      2)            ; duração do aviso (segundos)
(defparameter *cfg-osd-largura*  24)           ; células da barra de nível
(defparameter *cfg-passo-volume* 5)            ; % por toque
(defparameter *cfg-passo-brilho* 10)           ; % por toque
(defparameter *cfg-volume-max*   100)          ; tecto do volume (%)

;;; Menus (energia, unidades, monitores): janela central com ícones e legendas
(defparameter *cfg-menu-celula*   150)         ; largura de cada opção (px)
(defparameter *cfg-cmd-suspender* "systemctl suspend")
(defparameter *cfg-cmd-desligar*  "systemctl poweroff")

;;; Unidades externas: montagem automática em /mnt/<nome>, pela ordem da lista
(defparameter *cfg-drive-base*      "/mnt/")
(defparameter *cfg-drive-nomes*     '("Alpha" "Beta" "Gama" "Delta"))
(defparameter *cfg-drive-intervalo* 2)         ; segundos entre leituras do lsblk
(defparameter *cfg-drive-helper*    "sudo -n /usr/local/bin/stump-mnt")
(defparameter *cfg-drive-fs*        '("vfat" "exfat" "ntfs" "ext2" "ext3" "ext4"
                                      "btrfs" "xfs" "f2fs" "hfsplus" "iso9660" "udf"))
(defparameter *cfg-gestor-ficheiros* "xdg-open")   ; "Abrir" no menu das unidades

;;; Monitores (utilities/monitores.lisp)
(defparameter *cfg-monitor-intervalo* 2)       ; segundos entre leituras do xrandr
(defparameter *cfg-monitor-auto*   :estender)  ; ao ligar um ecrã: :estender ou :espelhar
(defparameter *cfg-monitor-lado*   :direita)   ; :direita :esquerda :acima :abaixo
(defparameter *cfg-monitor-internos* '("eDP" "LVDS" "DSI"))   ; prefixos dos ecrãs internos

;;; Hover na barra: áudio (título/álbum/capa), bateria, calendário
(defparameter *cfg-hover-intervalo* 0.25)      ; segundos entre leituras do ponteiro
(defparameter *cfg-hover-atraso*    2)         ; leituras seguidas até mostrar
(defparameter *cfg-hover-seg*       4)         ; duração da notificação (s)
(defparameter *cfg-cache-capas*     ".cache/stumpwm-capas/")  ; relativo ao home

;;; Mensagens do StumpWM (as que aparecem a meio do ecrã)
(defparameter *cfg-msg-gravidade* :center)     ; :center :top :bottom :top-left ...
(defparameter *cfg-msg-padding*   6)

;;; Comportamento
(defparameter *cfg-prefixo*     "C-z")
(defparameter *cfg-foco-rato*   :click)        ; :click ou :sloppy
(defparameter *cfg-timeout-msg* 7)
(defparameter *cfg-borda-msg*   2)
(defparameter *cfg-borda-largura* 0)           ; borda das janelas em mosaico
                                               ; (0 = nenhuma, também em fullscreen)
(defparameter *cfg-rato-mod*    :super)        ; modificador do rato em flutuantes

;;; Programas e ficheiros
(defparameter *cfg-terminal*   "kitty")
(defparameter *cfg-navegador*  "firefox")
(defparameter *cfg-wallpaper*  "~/Atrium/Pictures/Wallpapers/Desktop/Artwork/5.png")
(defparameter *cfg-quicklisp-dir* ".local/share/quicklisp/")  ; relativo ao home
(defparameter *cfg-swank-porta* 4004)
(defparameter *cfg-capturas-dir* "~/Pictures")   ; destino de C-z s / C-z S

;;;; =====================================================================
;;;; PAINEL DE CONTROLO, REDE E BATERIA (interface.lisp, utilities/painel.lisp)
;;;; =====================================================================

;;; Ícones (códigos Nerd Font; Font Awesome, dentro do plano base)
(defparameter *cfg-icone-wifi*    #xF0928)      ; ligado
(defparameter *cfg-icone-semrede* #xF127)      ; sem rede (se a fonte for a v3: #xF05AA)
(defparameter *cfg-icone-bateria* nil)         ; nil = por nível (#xF240-#xF244); ou um código fixo
(defparameter *cfg-icone-tomada*  #xEEA1)      ; ligada à corrente (#xF0E7 = raio)
(defparameter *cfg-icone-painel*  #xEE81)      ; botão do painel de controlo
(defparameter *cfg-icone-cafe*    #xEC15)      ; modo café activo
(defparameter *cfg-icone-noturna* #xF186)      ; luz noturna activa

;;; Aviso central de bateria baixa (só a descarregar; uma vez por limiar)
(defparameter *cfg-bateria-avisos*    '(15 5)) ; % que disparam o aviso
(defparameter *cfg-bateria-aviso-seg* 12)      ; duração do aviso (s)

;;; Painel de controlo
(defparameter *cfg-cmd-wifi-gestor*      ; abre o impala num kitty (janela flutuante)
  (format nil "~a --class impala --title Impala -e impala" *cfg-terminal*))
(defparameter *cfg-cmd-bluetooth-gestor* "blueman-manager")
(defparameter *cfg-painel-celula*  190)        ; largura de cada opção do painel (px)
(defparameter *cfg-painel-padding* 22)         ; folga vertical do painel (px)
(defparameter *cfg-flutuantes-classes*   ; estas classes abrem em janela flutuante
  '("impala" "blueman-manager"))
(defparameter *cfg-dpms-desligar* 900)         ; s até o ecrã desligar (= xinitrc); o café suspende-o
(defparameter *cfg-noturna-temp*  4000)        ; temperatura da luz noturna (K)
(defparameter *cfg-noturna-ligar*    "redshift -P -O ~d")  ; ~d = temperatura
(defparameter *cfg-noturna-desligar* "redshift -x")        ; (gammastep usa as mesmas opções)
