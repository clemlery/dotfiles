#!/bin/bash

HISTORY_FILE="/tmp/waybar_ram_history"
MAX_SAMPLES=10
BLOCKS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

# Usage RAM en %
USED=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2*100}')

# Historique
if [ -f "$HISTORY_FILE" ]; then
    HISTORY=$(cat "$HISTORY_FILE")
else
    HISTORY=""
fi

HISTORY=$(echo "$HISTORY $USED" | tr ' ' '\n' | grep -v '^$' | tail -n "$MAX_SAMPLES" | tr '\n' ' ')
echo "$HISTORY" > "$HISTORY_FILE"

# Normalisation : on mappe le range [min, max] sur 8 niveaux
# Si le range est trop faible (< 8), on force un range de 8 autour de la valeur courante
MIN_VAL=100
MAX_VAL=0
for val in $HISTORY; do
    [ "$val" -lt "$MIN_VAL" ] && MIN_VAL=$val
    [ "$val" -gt "$MAX_VAL" ] && MAX_VAL=$val
done

RANGE=$(( MAX_VAL - MIN_VAL ))
if [ "$RANGE" -lt 8 ]; then
    MIN_VAL=$(( USED - 4 ))
    MAX_VAL=$(( USED + 4 ))
    [ "$MIN_VAL" -lt 0 ] && MIN_VAL=0
    RANGE=8
fi

# Sparkline normalisé
GRAPH=""
for val in $HISTORY; do
    idx=$(( (val - MIN_VAL) * 7 / RANGE ))
    [ "$idx" -lt 0 ] && idx=0
    [ "$idx" -gt 7 ] && idx=7
    GRAPH="${GRAPH}${BLOCKS[$idx]}"
done

echo " ${GRAPH} ${USED}%"
echo "RAM: ${USED}% (${MIN_VAL}-${MAX_VAL}% sur 10 dernières valeurs)"
