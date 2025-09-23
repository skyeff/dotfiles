#!/bin/bash

# CPU usage
CPU=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.1f%%", usage}')

# Memória (real usada)
MEM=$(awk '/MemTotal/ {total=$2}  {avail=$2} END {printf "%d/%dMB", (total-avail)/1024, total/1024}' /proc/meminfo)

# Interface de rede (ajusta conforme necessário)
IF="wlan0"
RX1=$(cat /sys/class/net/$IF/statistics/rx_bytes)
TX1=$(cat /sys/class/net/$IF/statistics/tx_bytes)
sleep 1
RX2=$(cat /sys/class/net/$IF/statistics/rx_bytes)
TX2=$(cat /sys/class/net/$IF/statistics/tx_bytes)
RX_RATE=$(( (RX2 - RX1) / 1024 ))
TX_RATE=$(( (TX2 - TX1) / 1024 ))
NET="↓${RX_RATE}KB/s ↑${TX_RATE}KB/s"

# Bateria
BAT=$(acpi -b 2>/dev/null | head -n1 | awk -F', ' '{print $2}')
if [ -z "$BAT" ]; then
    BAT="N/A"
fi

# Data
DATE=$(date "+%Y-%m-%d %H:%M")

# Blocos com fundo e contraste adequado
echo -n "#[fg=black,bg=yellow] CPU: $CPU #[default]"
echo -n "#[fg=black,bg=cyan] MEM: $MEM #[default]"
echo -n "#[fg=black,bg=green] BAT: $BAT #[default]"
echo -n "#[fg=white,bg=blue] $DATE #[default]"

