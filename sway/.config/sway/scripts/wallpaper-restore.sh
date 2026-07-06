#!/usr/bin/env bash
#
# wallpaper-restore.sh — Rejoue les fonds d'écran par output au démarrage.
#
# Lancé depuis autostart.conf après swww-daemon. Attend que le daemon soit
# prêt, puis applique l'état sauvegardé par wallpaper-picker.sh (une ligne
# "output<TAB>chemin" par écran).
#
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/sway-wallpaper"
STATE="$STATE_DIR/state"

# Fond par défaut si aucun état sauvegardé (premier login)
DEFAULT="$HOME/Images/Backgrounds/digital-art-isolated-house.jpg"

# Attendre que le daemon swww réponde (5 s max)
for _ in $(seq 1 50); do
    swww query >/dev/null 2>&1 && break
    sleep 0.1
done

if [ ! -s "$STATE" ]; then
    # Aucun choix mémorisé : fond par défaut sur tous les outputs
    [ -f "$DEFAULT" ] && swww img --transition-type none "$DEFAULT" || true
    exit 0
fi

# Rejouer chaque ligne "output<TAB>chemin"
while IFS=$'\t' read -r out path; do
    [ -n "${out:-}" ] || continue
    [ -f "${path:-}" ] || continue
    swww img --outputs "$out" --transition-type none "$path" || true
done < "$STATE"
