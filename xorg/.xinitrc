#!/bin/sh
# ~/.xinitrc — arranque por `startx` (tty1). chmod +x ~/.xinitrc

[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources

# Teclado. Confirma: localectl list-x11-keymap-variants br
setxkbmap -model abnt2 -layout br -variant nodeadkeys

export GTK_THEME=Adwaita:dark
export XCURSOR_THEME=AppleCursor XCURSOR_SIZE=24

# Monitores. Confirma os nomes com `xrandr --listmonitors`.
# O init.lisp escolhe a cabeça da barra pela resolução (1920x1080),
# não pelo nome; aqui só se define disposição.
PRIMARIO=eDP-1
SECUNDARIO=HDMI-A-1
if xrandr | grep -q "^$SECUNDARIO connected"; then
  xrandr --output "$PRIMARIO" --auto --primary \
         --output "$SECUNDARIO" --auto --right-of "$PRIMARIO"
else
  xrandr --output "$PRIMARIO" --auto --primary
fi

# Serviços de arranque único (fora do rc, que pode ser reavaliado)
command -v picom >/dev/null && picom -b
command -v dunst >/dev/null && dunst &
xss-lock -- slock &
emacs --daemon=stumpwm-emacs &

exec stumpwm >> ~/.stumpwm.log 2>&1
