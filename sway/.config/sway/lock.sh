#!/bin/bash
TMPIMG=$(mktemp /tmp/lock-XXXXXX.png)
grim "$TMPIMG"
convert "$TMPIMG" -blur 0x12 "$TMPIMG"
swaylock -f \
    --image "$TMPIMG" \
    --color 150d24 \
    --inside-color 1e1233ee \
    --inside-clear-color 1e1233ee \
    --inside-ver-color 2d2872ee \
    --inside-wrong-color 150d24ee \
    --ring-color 7e4ca0ff \
    --ring-clear-color 4b3a8cff \
    --ring-ver-color b35298ff \
    --ring-wrong-color e3779eff \
    --key-hl-color e3779eff \
    --bs-hl-color b35298ff \
    --text-color ece4f2ff \
    --text-clear-color c9add1ff \
    --text-ver-color c9add1ff \
    --text-wrong-color efaaa2ff \
    --line-color 00000000 \
    --separator-color 00000000 \
    --indicator-radius 80 \
    --indicator-thickness 8
rm -f "$TMPIMG"
