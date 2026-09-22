#!/usr/bin/env bash
#
# ascii-animation-picker.sh — Sélecteur d'animations ASCII (firework-rs)
#
# Ouvre un menu rofi listant les effets intégrés (fountain, heart, vortex, rain,
# blackhole) puis les GIFs de la bibliothèque (~/.local/share/ascimation/gifs,
# obtenus via `ascimation list --gifs`). Le choix lance un ghostty à fond
# totalement transparent (--background-opacity=0) couvrant l'écran, qui exécute
# `ascimation <effet>` ou `ascimation gif <nom>`, ne laissant voir que
# l'animation par-dessus le wallpaper.
#
# - `ascimation` vient du fork firework-rs
#   (~/Documents/Programmation/firework-rs, installé via `cargo install --path .`
#   dans ~/.cargo/bin, donc sur le PATH). Chaque animation est une SOUS-COMMANDE :
#   `ascimation fountain|heart|vortex|rain|blackhole` (avant : un binaire nu par effet).
# - Ajouter un GIF au menu : le déposer dans ~/.local/share/ascimation/gifs
#   (extension .gif facultative). Il est lancé via `ascimation gif <nom>` plutôt
#   que `ascimation <nom>`, pour ne jamais être masqué par un effet intégré du
#   même nom.
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

# On lance `ascimation ...`. Résoudre le chemin absolu évite de dépendre du
# PATH hérité par ghostty et donne un message clair si le binaire manque.
# Résolu avant le menu : il sert aussi à lister les GIFs de la bibliothèque.
ascimation_bin=$(command -v ascimation 2>/dev/null || true)
if [ -z "$ascimation_bin" ]; then
    notify "Binaire introuvable sur le PATH : ascimation
Installe-le : cd ~/Documents/Programmation/firework-rs && cargo install --path ."
    exit 1
fi

# GIFs de la bibliothèque : label affiché  ->  nom du GIF (`ascimation gif <nom>`).
# Label : `floating_diamond` -> "Floating diamond". Si `list` échoue (binaire
# trop ancien), le menu garde simplement les effets intégrés.
declare -A GIFS=()
while IFS= read -r name; do
    [ -n "$name" ] || continue
    pretty="${name//[_-]/ }"
    label="󰵸  ${pretty^}"
    # Deux fichiers au même label (ex. a_b et a-b) : on garde le nom brut.
    if [ -n "${EFFECTS[$label]:-}" ] || [ -n "${GIFS[$label]:-}" ]; then
        label="󰵸  $name"
    fi
    GIFS[$label]="$name"
    LABELS+=("$label")
done < <("$ascimation_bin" list --gifs 2>/dev/null || true)

# --- Sélection rofi ------------------------------------------------------
choice=$(
    printf '%s\n' "${LABELS[@]}" \
        | rofi -dmenu -i \
               -p "Animation" \
        || true
)

[ -n "$choice" ] || exit 0

if [ -n "${EFFECTS[$choice]:-}" ]; then
    args=("${EFFECTS[$choice]}")
elif [ -n "${GIFS[$choice]:-}" ]; then
    args=(gif "${GIFS[$choice]}")
else
    notify "Effet inconnu : $choice"
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
    -e "$ascimation_bin" "${args[@]}"
