#!/usr/bin/env bash
#
# wallpaper-picker.sh — Sélecteur de fond d'écran par output (Crépuscule rose)
#
# Détecte l'output focus, ouvre rofi avec des vignettes des images de
# ~/Images/Backgrounds, applique le choix via swww sur ce seul output et
# persiste l'état pour le rejouer au démarrage (wallpaper-restore.sh).
#
set -euo pipefail

DIR="$HOME/Images/Backgrounds"
THEME="$HOME/.config/rofi/wallpaper.rasi"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/sway-wallpaper"
STATE="$STATE_DIR/state"

# Transition swww (légère, adaptée au dual-GPU Optimus)
TRANSITION_TYPE="${WP_TRANSITION_TYPE:-outer}"
TRANSITION_DURATION="${WP_TRANSITION_DURATION:-1}"
TRANSITION_POS="0.854,0.700"

notify() { command -v notify-send >/dev/null 2>&1 && notify-send "Wallpaper" "$1" || printf '%s\n' "$1" >&2; }

# --- S'assurer que le daemon swww tourne ---------------------------------
if ! swww query >/dev/null 2>&1; then
    swww-daemon >/dev/null 2>&1 &
    disown || true
    for _ in $(seq 1 50); do
        swww query >/dev/null 2>&1 && break
        sleep 0.1
    done
fi

# --- Output focus --------------------------------------------------------
output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | .name' | head -n1)
if [ -z "$output" ]; then
    notify "Aucun output focus détecté."
    exit 1
fi

if [ ! -d "$DIR" ]; then
    notify "Dossier introuvable : $DIR"
    exit 1
fi

# --- Sélection rofi avec vignettes ---------------------------------------
# Protocole icône de rofi : "<label>\0icon\x1f<chemin>" — l'image elle-même
# sert de vignette.
choice=$(
    find "$DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
           -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \) \
        | sort \
        | while IFS= read -r f; do
            printf '%s\0icon\x1f%s\n' "$(basename "$f")" "$f"
          done \
        | rofi -dmenu -i -show-icons \
               -p "Fond ▸ $output" \
               -theme "$THEME" \
        || true
)

[ -n "$choice" ] || exit 0

path="$DIR/$choice"
if [ ! -f "$path" ]; then
    notify "Image introuvable : $choice"
    exit 1
fi

# --- Application live sur le seul output focus ---------------------------
swww img \
    --outputs "$output" \
    --transition-type "$TRANSITION_TYPE" \
    --transition-duration "$TRANSITION_DURATION" \
    --transition-pos "$TRANSITION_POS" \
    "$path"

# --- Persistance : une ligne "output<TAB>chemin" par écran ---------------
# On remplace la ligne de l'output courant en préservant celles des autres.
mkdir -p "$STATE_DIR"
tmp=$(mktemp)
if [ -f "$STATE" ]; then
    grep -v -P "^$(printf '%s' "$output" | sed 's/[.[\*^$/]/\\&/g')\t" "$STATE" > "$tmp" || true
fi
printf '%s\t%s\n' "$output" "$path" >> "$tmp"
mv "$tmp" "$STATE"
