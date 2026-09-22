#!/usr/bin/env bash
# Ouvre un panneau de réglages GUI (écrans / bluetooth).
# Prévient via mako plutôt que d'échouer en silence si l'outil manque.
#
#   settings-panel.sh displays    → nwg-displays    (paquet : nwg-displays)
#   settings-panel.sh bluetooth   → blueman-manager (paquet : blueman)
set -euo pipefail

case "${1:-}" in
    displays)
        bin="nwg-displays"
        pkg="nwg-displays"
        label="Réglage des écrans"
        ;;
    bluetooth)
        bin="blueman-manager"
        pkg="blueman"
        label="Réglage du Bluetooth"
        ;;
    *)
        echo "usage: $(basename "$0") <displays|bluetooth>" >&2
        exit 2
        ;;
esac

if ! command -v "$bin" >/dev/null 2>&1; then
    notify-send -u critical "$label indisponible" \
        "« $bin » est introuvable. Installe-le avec :
sudo dnf install $pkg"
    exit 1
fi

# blueman-manager reste inerte si bluetoothd ne tourne pas : autant le dire.
if [ "$bin" = "blueman-manager" ] && ! systemctl is-active --quiet bluetooth; then
    notify-send -u critical "Bluetooth inactif" \
        "Le service bluetooth n'est pas démarré :
sudo systemctl enable --now bluetooth"
    exit 1
fi

exec "$bin"
