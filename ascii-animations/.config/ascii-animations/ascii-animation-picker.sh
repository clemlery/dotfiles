#!/usr/bin/env bash
#
# ascii-animation-picker.sh — Sélecteur d'animations ASCII (firework-rs)
#
# Ouvre un menu rofi listant trois effets (fountain, heart, vortex). Le choix
# lance un ghostty plein écran à fond totalement transparent (--background-opacity=0)
# qui exécute le binaire correspondant, ne laissant voir que l'animation
# par-dessus le wallpaper.
#
# - Les binaires fountain/heart/vortex viennent du fork firework-rs
#   (~/Documents/Programmation/firework-rs, installés via `cargo install --path .`
#   dans ~/.cargo/bin, donc sur le PATH).
# - Ces binaires ne prennent AUCUN argument : on ne passe pas -g/--gradient
#   (ce flag n'existe que sur le binaire `firework` et imposerait un fond noir).
# - --class=firework-effect devient l'app_id Wayland ciblé par la règle for_window.
# - Ils bouclent à l'infini : on les quitte avec Échap (ou $mod+q côté sway).
#
set -euo pipefail

# Sway lance ce script sans sourcer ~/.bashrc : ~/.cargo/bin (où vivent
# fountain/heart/vortex via `cargo install`) n'est pas sur le PATH. On l'ajoute
# pour que `command -v` et ghostty retrouvent les binaires.
export PATH="$HOME/.cargo/bin:$PATH"

# Effets disponibles : label affiché  ->  binaire à lancer
declare -A EFFECTS=(
    ["󰈸  Fountain"]="fountain"
    ["󰋑  Heart"]="heart"
    ["󰑮  Vortex"]="vortex"
)

# Ordre stable dans le menu
LABELS=("󰈸  Fountain" "󰋑  Heart" "󰑮  Vortex")

notify() { command -v notify-send >/dev/null 2>&1 && notify-send "ASCII animations" "$1" || printf '%s\n' "$1" >&2; }

# --- Sélection rofi ------------------------------------------------------
choice=$(
    printf '%s\n' "${LABELS[@]}" \
        | rofi -dmenu -i \
               -p "Animation" \
        || true
)

[ -n "$choice" ] || exit 0

bin="${EFFECTS[$choice]:-}"
if [ -z "$bin" ]; then
    notify "Effet inconnu : $choice"
    exit 1
fi

bin_path=$(command -v "$bin" 2>/dev/null || true)
if [ -z "$bin_path" ]; then
    notify "Binaire introuvable sur le PATH : $bin
Installe-le : cd ~/Documents/Programmation/firework-rs && cargo install --path ."
    exit 1
fi

# --- Lancement ghostty plein écran transparent ---------------------------
# --class    -> app_id Wayland (ciblé par for_window). DOIT être un identifiant
#               d'application GTK valide (reverse-DNS, au moins un point) sinon
#               ghostty l'ignore et retombe sur "com.mitchellh.ghostty".
# --background-opacity=0 -> fond totalement transparent (wallpaper visible)
# --window-padding-x/y=0   -> supprime les 2px de marge par défaut
# -e         -> DOIT être en dernier ; tout ce qui suit est la commande
exec ghostty \
    --class=com.firework.effect \
    --background-opacity=0 \
    --window-padding-x=0 \
    --window-padding-y=0 \
    -e "$bin_path"
