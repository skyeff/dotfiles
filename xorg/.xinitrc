#!/bin/sh
# ~/.xinitrc — arranque por `startx` (tty1). chmod +x ~/.xinitrc

[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources

# Teclado ABNT2 COM teclas mortas (' + e = é). O variante nodeadkeys, que
# tinhas, desliga-as e é a causa de aparecer 'e em vez de é.
# ctrl:nocaps: Caps Lock passa a Ctrl (C-z e C-x ficam ao alcance do mindinho).
# Confirma: localectl list-x11-keymap-variants br
setxkbmap -model abnt2 -layout br -option ctrl:nocaps
xset r rate 250 40      # repetição de tecla: atraso 250 ms, 40 por segundo
xset -b                 # sem beep

export GTK_THEME=Adwaita:dark
export XCURSOR_THEME=AppleCursor XCURSOR_SIZE=24
command -v qt5ct >/dev/null && export QT_QPA_PLATFORMTHEME=qt5ct
xsetroot -cursor_name left_ptr      # cursor normal sobre o fundo (e não o X)

# Passa o ambiente aos serviços D-Bus/systemd (portais, notificações...)
command -v dbus-update-activation-environment >/dev/null &&
  dbus-update-activation-environment --systemd \
    DISPLAY XAUTHORITY GTK_THEME XCURSOR_THEME XCURSOR_SIZE

# Monitores: dispõe todos os ecrãs ligados, sem depender dos nomes.
# (instalar em ~/.local/bin/monitores com chmod +x)
sh ~/.local/bin/monitores >> ~/.monitores.log 2>&1

# Inactividade: sem bloqueador de ecrã; só o ecrã desliga, aos 15 min
xset s off
xset dpms 0 0 900

# Serviços de arranque único (fora do rc, que pode ser reavaliado)
command -v picom >/dev/null && picom -b
command -v dunst >/dev/null && dunst &
command -v udiskie >/dev/null && udiskie &            # monta pendrives e discos
# command -v unclutter >/dev/null && unclutter -idle 3 &   # esconde o rato parado
# (confirma as opções do teu pacote com `unclutter --help`)
emacs --daemon=stumpwm-emacs &

exec stumpwm >> ~/.stumpwm.log 2>&1
