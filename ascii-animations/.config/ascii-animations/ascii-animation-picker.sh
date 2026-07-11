#!/usr/bin/env bash
#
# ascii-animation-picker.sh — Sélecteur d'animations ASCII (firework-rs)
#
# Ouvre un menu rofi listant cinq effets (fountain, heart, vortex, rain,
# blackhole). Le choix lance un ghostty à fond totalement transparent
# (--background-opacity=0) couvrant l'écran, qui exécute `ascimation <effet>`,
# ne laissant voir que l'animation par-dessus le wallpaper.
#
# - `ascimation` vient du fork firework-rs
#   (~/Documents/Programmation/firework-rs, installé via `cargo install --path .`
#   dans ~/.cargo/bin, donc sur le PATH). Chaque animation est une SOUS-COMMANDE :
#   `ascimation fountain|heart|vortex|rain|blackhole` (avant : un binaire nu par effet).
# - On ne passe PAS -g/--gradient (ce flag n'existe que sur le binaire `firework`
#   et imposerait un fond noir opaque, cassant la transparence).
# - --class=com.firework.effect devient l'app_id Wayland ciblé par la règle
#   for_window (DOIT être un id GTK valide en reverse-DNS, cf. app_rules.conf).
# - Les animations bouclent à l'infini : on les quitte avec Échap (ou $mod+q).
#
set -euo pipefail

# Sway lance ce script sans sourcer ~/.bashrc : ~/.cargo/bin (où vit `ascimation`
# via `cargo install`) n'est pas forcément sur le PATH. On l'ajoute pour que
# `command -v` et ghostty retrouvent le binaire.
export PATH="$HOME/.cargo/bin:$PATH"

# Effets disponibles : label affiché  ->  sous-commande ascimation
declare -A EFFECTS=(
    ["󰈸  Fountain"]="fountain"
    ["󰋑  Heart"]="heart"
    ["󰑮  Vortex"]="vortex"
    ["󰖗  Rain"]="rain"
    ["󰖔  Blackhole"]="blackhole"
)

# Ordre stable dans le menu
LABELS=("󰈸  Fountain" "󰋑  Heart" "󰑮  Vortex" "󰖗  Rain" "󰖔  Blackhole")

notify() { command -v notify-send >/dev/null 2>&1 && notify-send "ASCII animations" "$1" || printf '%s\n' "$1" >&2; }

# --- Sélection rofi ------------------------------------------------------
choice=$(
    printf '%s\n' "${LABELS[@]}" \
        | rofi -dmenu -i \
               -p "Animation" \
        || true
)

[ -n "$choice" ] || exit 0

effect="${EFFECTS[$choice]:-}"
if [ -z "$effect" ]; then
    notify "Effet inconnu : $choice"
    exit 1
fi

# On lance `ascimation <effet>`. Résoudre le chemin absolu évite de dépendre du
# PATH hérité par ghostty et donne un message clair si le binaire manque.
ascimation_bin=$(command -v ascimation 2>/dev/null || true)
if [ -z "$ascimation_bin" ]; then
    notify "Binaire introuvable sur le PATH : ascimation
Installe-le : cd ~/Documents/Programmation/firework-rs && cargo install --path ."
    exit 1
fi

# --- Lancement ghostty transparent couvrant l'écran ----------------------
# --class    -> app_id Wayland (ciblé par for_window). DOIT être un identifiant
#               d'application GTK valide (reverse-DNS, au moins un point) sinon
#               ghostty l'ignore et retombe sur "com.mitchellh.ghostty".
# --background-opacity=0 -> fond totalement transparent (wallpaper visible)
# --window-padding-x/y=0   -> supprime les 2px de marge par défaut
# -e         -> DOIT être en dernier ; tout ce qui suit est la commande + args
exec ghostty \
    --class=com.firework.effect \
    --background-opacity=0 \
    --window-padding-x=0 \
    --window-padding-y=0 \
    -e "$ascimation_bin" "$effect"
