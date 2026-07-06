#!/usr/bin/env bash
#
# install.sh — Déploiement des dotfiles « Crépuscule rose » sur Fedora 43
#
# Ce script :
#   1. installe les paquets nécessaires (dnf + COPR + Nerd Fonts)
#   2. lie les configs vers ~/.config via GNU Stow
#
# Usage :
#   ./install.sh              # installation complète (paquets + stow)
#   ./install.sh --packages   # uniquement les paquets
#   ./install.sh --stow       # uniquement les symlinks stow
#   ./install.sh --no-fonts   # saute l'installation des Nerd Fonts
#
# Idempotent : peut être relancé sans casse.

set -euo pipefail

# ── Réglages ────────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup/$(date +%Y%m%d-%H%M%S)"
NERD_FONTS_VERSION="v3.2.1"
FONT_DIR="$HOME/.local/share/fonts"

# Paquets stow à lier (dossiers du repo respectant dotfiles/<app>/.config/<app>/…)
# NB : kanshi est volontairement exclu — son fichier `kanshi/config` n'est pas
# dans la structure stow attendue (`kanshi/.config/kanshi/config`).
STOW_PACKAGES=(cava ghostty git mako rofi sway waybar wofi)

# Paquets dnf officiels
DNF_PACKAGES=(
  # Session Wayland / WM
  sway swaybg swayidle swaylock waybar mako
  # Terminal & lanceurs
  wofi rofi-wayland wmenu
  # Captures & sélection
  grim slurp
  # Audio (PipeWire) & médias
  wireplumber pipewire pipewire-pulseaudio playerctl cava
  # Matériel / système
  brightnessctl lm_sensors upower NetworkManager-tui alsa-utils
  # Images (swaylock blur) & thème d'icônes
  ImageMagick papirus-icon-theme
  # Outils & runtime
  git stow jq curl python3 unzip
)

# ── Utilitaires d'affichage ─────────────────────────────────────────────────
c_reset=$'\e[0m'; c_rose=$'\e[38;5;211m'; c_mauve=$'\e[38;5;140m'
c_ok=$'\e[38;5;114m'; c_warn=$'\e[38;5;179m'; c_err=$'\e[38;5;203m'

info()  { printf '%s»%s %s\n' "$c_rose" "$c_reset" "$*"; }
step()  { printf '\n%s══ %s ══%s\n' "$c_mauve" "$*" "$c_reset"; }
ok()    { printf '%s✓%s %s\n' "$c_ok" "$c_reset" "$*"; }
warn()  { printf '%s⚠%s %s\n' "$c_warn" "$c_reset" "$*"; }
err()   { printf '%s✗%s %s\n' "$c_err" "$c_reset" "$*" >&2; }
die()   { err "$*"; exit 1; }

# ── Vérifications préalables ─────────────────────────────────────────────────
check_prereqs() {
  step "Vérifications"

  [[ $EUID -ne 0 ]] || die "Ne pas lancer ce script en root (il utilise sudo au besoin)."

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "${ID:-}" == "fedora" ]] || warn "Distro détectée : ${ID:-inconnue} (prévu pour Fedora)."
    [[ "${VERSION_ID:-}" == "43" ]] || warn "Version Fedora : ${VERSION_ID:-inconnue} (prévu pour 43)."
    ok "Système : ${PRETTY_NAME:-inconnu}"
  else
    warn "/etc/os-release illisible — impossible de vérifier la distro."
  fi

  command -v dnf >/dev/null 2>&1 || die "dnf introuvable."
}

# ── Installation des paquets dnf ─────────────────────────────────────────────
install_dnf_packages() {
  step "Paquets dnf"
  info "Installation de ${#DNF_PACKAGES[@]} paquets…"
  sudo dnf install -y "${DNF_PACKAGES[@]}"
  ok "Paquets dnf installés."
}

# ── ghostty (dépôts Fedora sinon COPR) ───────────────────────────────────────
install_ghostty() {
  step "Terminal ghostty"
  if command -v ghostty >/dev/null 2>&1; then
    ok "ghostty déjà présent."
    return
  fi
  if sudo dnf install -y ghostty 2>/dev/null && command -v ghostty >/dev/null 2>&1; then
    ok "ghostty installé depuis les dépôts."
    return
  fi
  warn "ghostty absent des dépôts — activation du COPR scottames/ghostty."
  sudo dnf copr enable -y scottames/ghostty || { warn "COPR ghostty indisponible — installe ghostty manuellement."; return; }
  sudo dnf install -y ghostty && ok "ghostty installé (COPR)." || warn "Échec ghostty — à installer manuellement."
}

# ── swww (dépôts → COPR → cargo) ─────────────────────────────────────────────
install_swww() {
  step "Fond d'écran swww"
  if command -v swww >/dev/null 2>&1; then
    ok "swww déjà présent."
    return
  fi
  if sudo dnf install -y swww 2>/dev/null && command -v swww >/dev/null 2>&1; then
    ok "swww installé depuis les dépôts."
    return
  fi
  warn "swww absent des dépôts. Installe-le au choix :"
  warn "  • COPR   : sudo dnf copr enable <copr>/swww && sudo dnf install swww"
  warn "  • cargo  : sudo dnf install cargo lz4-devel && cargo install swww"
  warn "swww est nécessaire au sélecteur de fond (\$mod+Shift+w)."
}

# ── Nerd Fonts (Monaspace + Inconsolata) ─────────────────────────────────────
install_fonts() {
  step "Nerd Fonts (Monaspace, Inconsolata)"
  local fonts=(Monaspace Inconsolata)
  local base="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}"
  mkdir -p "$FONT_DIR"

  # Détection : au moins un glyphe Monaspace déjà installé ?
  if fc-list 2>/dev/null | grep -qiE 'monaspice.*nerd' && \
     fc-list 2>/dev/null | grep -qiE 'inconsolata.*nerd'; then
    ok "Nerd Fonts déjà installées."
    return
  fi

  local tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  for font in "${fonts[@]}"; do
    info "Téléchargement de ${font} Nerd Font…"
    if curl -fsSL -o "$tmp/$font.zip" "$base/$font.zip"; then
      unzip -oq "$tmp/$font.zip" -d "$FONT_DIR/$font" -x '*.md' 'LICENSE*'
      ok "$font installé."
    else
      warn "Échec du téléchargement de $font — à installer manuellement."
    fi
  done
  fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
  ok "Cache des polices rafraîchi."
}

# ── Sauvegarde des configs existantes (non-symlink) ──────────────────────────
backup_existing() {
  local pkg="$1"
  # Cibles = sous-dossiers de <pkg>/.config/*
  local src="$DOTFILES_DIR/$pkg/.config"
  [[ -d "$src" ]] || return 0
  local sub
  for sub in "$src"/*; do
    [[ -e "$sub" ]] || continue
    local name; name="$(basename "$sub")"
    local target="$HOME/.config/$name"
    # On ne sauvegarde que si la cible existe ET n'est pas déjà un symlink
    if [[ -e "$target" && ! -L "$target" ]]; then
      mkdir -p "$BACKUP_DIR/.config"
      warn "Sauvegarde de ~/.config/$name → $BACKUP_DIR/.config/$name"
      mv "$target" "$BACKUP_DIR/.config/$name"
    fi
  done
}

# ── Stow ─────────────────────────────────────────────────────────────────────
run_stow() {
  step "Symlinks GNU Stow"
  command -v stow >/dev/null 2>&1 || die "stow introuvable (installe le paquet 'stow')."
  mkdir -p "$HOME/.config"

  local pkg
  for pkg in "${STOW_PACKAGES[@]}"; do
    if [[ ! -d "$DOTFILES_DIR/$pkg" ]]; then
      warn "Paquet '$pkg' absent du repo — ignoré."
      continue
    fi
    backup_existing "$pkg"
    info "stow $pkg"
    if stow --restow --target="$HOME" --dir="$DOTFILES_DIR" "$pkg"; then
      ok "$pkg lié."
    else
      err "Conflit stow sur '$pkg' — résous-le puis relance ./install.sh --stow."
    fi
  done

  warn "kanshi non lié : 'kanshi/config' n'est pas dans la structure stow"
  warn "  (attendu : kanshi/.config/kanshi/config). À corriger avant de le stower."
}

# ── Notes finales ────────────────────────────────────────────────────────────
final_notes() {
  step "Terminé"
  ok "Dotfiles « Crépuscule rose » déployés."
  echo
  info "À faire ensuite (manuel) :"
  echo "  • Capteurs température   : sudo sensors-detect   (waybar.sh utilise 'sensors')"
  echo "  • Spotify (waybar)       : renseigner ~/.config/waybar/spotify_credentials"
  echo "                             (SPOTIFY_CLIENT_ID / _SECRET / _REFRESH_TOKEN)"
  echo "                             puis lancer scripts/spotify_auth.sh"
  if [[ -d "$BACKUP_DIR" ]]; then
    echo "  • Anciennes configs sauvegardées dans : $BACKUP_DIR"
  fi
  echo
  warn "Session sway : reconnecte-toi (ou lance 'sway'). Ne recharge PAS via ce script."
}

# ── Orchestration ────────────────────────────────────────────────────────────
main() {
  local do_packages=1 do_stow=1 do_fonts=1

  for arg in "$@"; do
    case "$arg" in
      --packages) do_stow=0 ;;
      --stow)     do_packages=0 ;;
      --no-fonts) do_fonts=0 ;;
      -h|--help)
        # Affiche uniquement l'en-tête (jusqu'à la première ligne non commentée)
        awk 'NR>1 && /^#/ { sub(/^# ?/,""); print; next } NR>1 { exit }' "${BASH_SOURCE[0]}"
        exit 0 ;;
      *) die "Argument inconnu : $arg (voir --help)." ;;
    esac
  done

  printf '%s╭─ Dotfiles « Crépuscule rose » ─────────────╮%s\n' "$c_rose" "$c_reset"
  printf '%s│  Installation Fedora 43 · sway + waybar    │%s\n' "$c_rose" "$c_reset"
  printf '%s╰────────────────────────────────────────────╯%s\n' "$c_rose" "$c_reset"

  check_prereqs

  if [[ $do_packages -eq 1 ]]; then
    install_dnf_packages
    install_ghostty
    install_swww
    [[ $do_fonts -eq 1 ]] && install_fonts || warn "Nerd Fonts sautées (--no-fonts)."
  fi

  [[ $do_stow -eq 1 ]] && run_stow

  final_notes
}

main "$@"
