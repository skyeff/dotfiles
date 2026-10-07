#!/bin/sh
# ~/.xinitrc — arranque por `startx` (tty1). chmod +x ~/.xinitrc

[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources

# Teclado. Confirma: localectl list-x11-keymap-variants br
setxkbmap -model abnt2 -layout br -variant nodeadkeys

export GTK_THEME=Adwaita:dark
export XCURSOR_THEME=AppleCursor XCURSOR_SIZE=24

# Monitores: dispõe todos os ecrãs ligados, sem depender dos nomes.
# (instalar em ~/.local/bin/monitores com chmod +x)
sh ~/.local/bin/monitores >> ~/.monitores.log 2>&1

# Serviços de arranque único (fora do rc, que pode ser reavaliado)
command -v picom >/dev/null && picom -b
command -v dunst >/dev/null && dunst &
xss-lock -- slock &
emacs --daemon=stumpwm-emacs &

exec stumpwm >> ~/.stumpwm.log 2>&1
