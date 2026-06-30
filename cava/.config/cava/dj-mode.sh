#!/usr/bin/env bash
#
# DJ mode — lance cava en plein écran sur chaque sortie active de sway.
#
# Un terminal ghostty par écran, chacun avec une variante de config cava
# légèrement différente (dj-1..dj-N.conf) pour éviter l'effet « écran dupliqué ».
# Thème « Crépuscule rose ». Relancer la commande coupe le mode DJ (toggle).
#
set -euo pipefail

CONF_DIR="$HOME/.config/cava"
CLASS_PREFIX="cava-dj"
MATCH="cava -p ${CONF_DIR}/dj-"   # signature des process cava à cibler

# --- Toggle off : si le mode tourne déjà, on ferme tout --------------------
if pgrep -f "$MATCH" >/dev/null 2>&1; then
    swaymsg "[app_id=\"^${CLASS_PREFIX}\"] kill" >/dev/null 2>&1 || true
    pkill -f "$MATCH" 2>/dev/null || true
    exit 0
fi

# --- Sorties actives + variantes de config disponibles ---------------------
mapfile -t OUTPUTS < <(swaymsg -t get_outputs -r | jq -r '.[] | select(.active) | .name')
shopt -s nullglob
CONFIGS=("$CONF_DIR"/dj-*.conf)

if [ "${#OUTPUTS[@]}" -eq 0 ] || [ "${#CONFIGS[@]}" -eq 0 ]; then
    notify-send "DJ mode" "Aucune sortie active ou aucune config cava trouvée." 2>/dev/null || true
    exit 1
fi

# --- Un terminal cava plein écran par sortie -------------------------------
i=0
for out in "${OUTPUTS[@]}"; do
    cfg="${CONFIGS[$(( i % ${#CONFIGS[@]} ))]}"
    class="${CLASS_PREFIX}.s${i}"

    # On vise la bonne sortie pour que la fenêtre y naisse.
    swaymsg "focus output \"$out\"" >/dev/null

    # gtk-single-instance=false : chaque fenêtre a son propre app_id.
    ghostty --gtk-single-instance=false --class="$class" \
        -e cava -p "$cfg" &

    # Attente de l'apparition de la fenêtre, puis épinglage + plein écran.
    for _ in $(seq 1 50); do
        if swaymsg -t get_tree -r \
            | jq -e --arg id "$class" 'recurse | objects | select(.app_id? == $id)' \
            >/dev/null 2>&1; then
            break
        fi
        sleep 0.1
    done
    swaymsg "[app_id=\"^${class}\$\"] move to output \"$out\", fullscreen enable" \
        >/dev/null 2>&1 || true

    i=$(( i + 1 ))
done
