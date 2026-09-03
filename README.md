# Dotfiles — Ricing sway « Crépuscule rose »

Configurations Linux versionnées pour un environnement de bureau cohérent et
reproductible, sur le thème d'un coucher de soleil synthwave : **violet profond →
magenta → rose**, lune crème, accents bleu-ardoise.

| | |
|---|---|
| **Distro** | Fedora 43 |
| **Matériel** | Acer Nitro AN515-58 · Intel UHD + RTX 4060 (dual-GPU Optimus) |
| **Session** | Wayland + **sway** (tiling WM) |
| **Terminal** | ghostty |
| **Lanceur** | rofi (`rofi -show drun`) |
| **Barre** | waybar |
| **Notifications** | mako |
| **Fond d'écran** | swww (sélecteur par écran) |
| **Verrouillage** | swaylock |
| **Audio** | PipeWire (pactl / wireplumber) · visualizer cava |

---

## Installation

Les configs vivent dans ce repo et sont liées vers `~/.config/` par **symlinks
GNU Stow**. Structure attendue : `dotfiles/<appli>/.config/<appli>/…`.

```bash
git clone <repo> ~/Documents/dotfiles
cd ~/Documents/dotfiles
./install.sh              # paquets (dnf + COPR + Nerd Fonts) + symlinks stow
```

Options du script :

| Commande | Effet |
|----------|-------|
| `./install.sh` | Installation complète (paquets + stow) |
| `./install.sh --packages` | Uniquement les paquets |
| `./install.sh --stow` | Uniquement les symlinks stow |
| `./install.sh --no-fonts` | Saute l'installation des Nerd Fonts |

Le script est **idempotent** et sauvegarde toute config existante dans
`~/.config-backup/<horodatage>/` avant de poser les symlinks.

> ⚠️ Stow crée des symlinks de **répertoire** (ex. `~/.config/rofi →
> dotfiles/rofi/.config/rofi`). Un `rm` dans `~/.config/<appli>/` supprime donc
> les fichiers **du repo lui-même**. Ne jamais supprimer une config sans avoir
> vérifié le symlink de remplacement.

---

## Structure du repo

```
dotfiles/
├── install.sh                 # déploiement (paquets + stow), idempotent
├── CLAUDE.md                  # instructions projet (conventions, palette, règles)
│
├── sway/.config/sway/         # window manager
│   ├── config                 # point d'entrée (include des conf.d/*)
│   ├── lock.sh                # verrouillage : screenshot flouté + swaylock thémé
│   ├── waybar.sh
│   ├── conf.d/
│   │   ├── theme/theme.conf       # palette + bordures fenêtres + gaps + police
│   │   ├── autostart/autostart.conf  # mako, waybar, swww-daemon, restore wallpaper
│   │   ├── input/input.conf       # clavier (layout fr)
│   │   ├── keybinds/keybinds.conf # TOUS les raccourcis (voir plus bas)
│   │   └── app_rules/app_rules.conf  # règles for_window (floating, fullscreen…)
│   └── scripts/
│       ├── wallpaper-picker.sh    # sélecteur de fond par écran (rofi + swww)
│       └── wallpaper-restore.sh   # rejoue les fonds au démarrage de session
│
├── waybar/.config/waybar/     # barre de statut
│   ├── config.jsonc           # layout global + positions des modules
│   ├── modules.jsonc          # modules généraux (spotify, workspaces, réseau…)
│   ├── hardware.jsonc         # groupe cpu + température + batterie
│   ├── style.css              # thème Crépuscule rose
│   └── scripts/               # spotify.sh, power_menu.py, ram_graph.sh…
│
├── rofi/.config/rofi/         # lanceur & menus
│   ├── config.rasi            # config drun
│   ├── theme.rasi             # thème Crépuscule rose
│   ├── wallpaper.rasi         # grille de vignettes du sélecteur de fond
│   └── power_menu.rasi
│
├── cava/.config/cava/         # visualizer audio
│   ├── dj-1..4.conf           # variantes de config (mode DJ multi-écrans)
│   └── dj-mode.sh             # lance cava plein écran sur chaque sortie (toggle)
│
├── ascii-animations/.config/ascii-animations/
│   └── ascii-animation-picker.sh  # menu d'animations ASCII (firework-rs)
│
├── ghostty/.config/ghostty/   # terminal (+ thème crepuscule-rose)
├── mako/.config/mako/         # notifications
├── wofi/.config/wofi/         # lanceur alternatif
├── git/.config/git/           # config git globale
└── kanshi/config              # profils d'écrans (hors structure stow, cf. install.sh)
```

> `kanshi` est volontairement **exclu de stow** : son fichier n'est pas dans
> l'arborescence `kanshi/.config/kanshi/…` attendue.

### Hors-repo (non versionné)

- `waybar/.config/waybar/spotify_credentials` — secrets OAuth Spotify (ignoré par
  `.gitignore` via le motif `*credentials*`).
- `~/.local/state/sway-wallpaper/state` — état des fonds par écran (spécifique à
  la machine).
- Fonds d'écran dans `~/Images/Backgrounds`.

---

## Palette « Crépuscule rose »

| Rôle | Hex | | Rôle | Hex |
|------|-----|-|------|-----|
| bg (fond) | `#150d24` | | mauve | `#7e4ca0` |
| bg-alt | `#1e1233` | | magenta | `#b35298` |
| surface | `#2d2872` | | **rose (focus)** | `#e3779e` |
| muted (bordures) | `#4b3a8c` | | peach (lune) | `#efaaa2` |
| slate | `#323169` | | lilac (texte dim) | `#c9add1` |
| | | | fg (texte) | `#ece4f2` |

**Accent** : `rose` pour le focus / la fenêtre active et les éléments interactifs ;
`peach` pour les accents chauds ponctuels ; `slate`/`mauve` pour le froid.

---

## Raccourcis clavier (sway)

Modificateur `$mod` = **Super** (Mod4). Navigation façon Vim :
`h`/`j`/`k`/`l` = gauche / bas / haut / droite.

### Applications & session

| Raccourci | Action |
|-----------|--------|
| `$mod + Entrée` | Ouvrir un terminal (ghostty) |
| `$mod + d` | Lanceur d'applications (`rofi -show drun`) |
| `$mod + q` | Fermer la fenêtre active |
| `$mod + Ctrl + l` | Verrouiller l'écran (screenshot flouté + swaylock) |
| `$mod + Shift + r` | Recharger sway |
| `$mod + Shift + e` | Quitter sway (confirmation swaynag) |

### Focus (navigation entre fenêtres)

| Raccourci | Action |
|-----------|--------|
| `$mod + h / j / k / l` | Déplacer le focus gauche / bas / haut / droite |
| `$mod + ← / ↓ / ↑ / →` | Idem avec les flèches |
| `$mod + a` | Focus sur le conteneur parent |

### Déplacer les fenêtres

| Raccourci | Action |
|-----------|--------|
| `$mod + Shift + h / j / k / l` | Déplacer la fenêtre gauche / bas / haut / droite |
| `$mod + Shift + ← / ↓ / ↑ / →` | Idem avec les flèches |

### Workspaces

| Raccourci | Action |
|-----------|--------|
| `$mod + 1…0` | Aller au workspace 1 à 10 |
| `$mod + Shift + 1…0` | Envoyer la fenêtre vers le workspace 1 à 10 |

### Disposition (layout)

| Raccourci | Action |
|-----------|--------|
| `$mod + b` | Split horizontal |
| `$mod + v` | Split vertical |
| `$mod + s` | Layout empilé (stacking) |
| `$mod + w` | Layout à onglets (tabbed) |
| `$mod + e` | Basculer split (toggle split) |
| `$mod + f` | Plein écran |
| `$mod + Espace` | Basculer focus tiling ↔ flottant |
| `$mod + Shift + Espace` | Rendre la fenêtre flottante / retiler |

### Redimensionnement & scratchpad

| Raccourci | Action |
|-----------|--------|
| `$mod + r` | Entrer en **mode resize** (voir ci-dessous) |
| `$mod + minus` | Afficher le scratchpad |
| `$mod + Shift + minus` | Envoyer la fenêtre au scratchpad |

En **mode resize** : `h/j/k/l` ou les flèches redimensionnent par pas de 10px ;
`Entrée` ou `Échap` reviennent au mode normal.

### Média & matériel

| Raccourci | Action |
|-----------|--------|
| `XF86AudioRaiseVolume` / `LowerVolume` | Volume +5 % / −5 % (pactl) |
| `XF86AudioMute` | Couper / rétablir le son |
| `XF86AudioMicMute` | Couper / rétablir le micro |
| `XF86MonBrightnessUp` / `Down` | Luminosité +5 % / −5 % (brightnessctl) |
| `Impr. écran` (`Print`) | Capture d'écran (grim) |

> Les touches média sont `--locked` : elles fonctionnent même écran verrouillé.

### Ricing & extras

| Raccourci | Action |
|-----------|--------|
| `$mod + Shift + w` | **Sélecteur de fond d'écran** sur l'écran focus (rofi + swww) |
| `$mod + g` | **Animations ASCII** : menu fountain / heart / vortex / rain / blackhole (Échap pour quitter) |
| `$mod + c` | **Mode DJ** : cava plein écran sur chaque sortie (toggle) |

---

## Composants notables

### Fond d'écran — sélecteur par écran (swww)

`$mod+Shift+w` ouvre une grille de vignettes de `~/Images/Backgrounds` (rofi).
Le picker détecte l'écran focus, applique le fond uniquement sur cet écran via
`swww img --outputs <name>`, puis persiste l'état dans
`~/.local/state/sway-wallpaper/state` (une ligne `output<TAB>chemin` par écran).
Au démarrage, `wallpaper-restore.sh` rejoue cet état.

> swaybg a été retiré (`output * bg …`) pour ne pas doubler swww sur le layer
> background. Les `exec swww-daemon` / restore ne tournent qu'au **démarrage** de
> sway, pas sur `reload`.

### waybar

Barre en 3 fichiers (`config.jsonc` layout · `modules.jsonc` généraux ·
`hardware.jsonc` cpu+temp+batterie). Rechargée par
`exec_always pkill -x waybar; sleep 0.3; waybar` dans l'autostart, donc un
`swaymsg reload` redémarre waybar avec la nouvelle config.

Modules : power menu · titre fenêtre · lecteur Spotify (cover art + visualizer
ASCII, nécessite `spotify_credentials`) · workspaces · groupe hardware · réseau ·
volume · horloge.

### Mode DJ & animations ASCII

- **Mode DJ** (`$mod+c`) : un ghostty cava plein écran par sortie, chacun avec
  une variante `dj-N.conf` pour éviter l'effet « écran dupliqué ». Re-presser
  coupe le mode.
- **Animations ASCII** (`$mod+g`) : lance `ascimation <effet>` (fork
  [firework-rs](https://github.com/) installé via `cargo install --path .`) dans
  un ghostty totalement transparent couvrant l'écran, ne laissant voir que
  l'animation par-dessus le wallpaper.

---

## Conventions & règles

- Un composant à la fois ; commit avant toute opération risquée sur `~/.config`.
- Ne jamais lancer `swaymsg reload` / `exit` sans validation.
- Ne jamais déplacer/supprimer une config sans poser le symlink de remplacement
  dans la foulée.
- Tenir compte du dual-GPU Optimus (pas de réglages GPU génériques).

Voir [`CLAUDE.md`](CLAUDE.md) pour le détail complet des conventions.
