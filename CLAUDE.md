# Dotfiles — Ricing sway « Crépuscule rose »

Ce repo contient mes configurations Linux. Objectif : un environnement de bureau
cohérent, versionné et reproductible, sur le thème d'un coucher de soleil synthwave
(violet profond → magenta → rose, lune crème, accents bleu-ardoise).

## Machine & environnement

- **Distro** : Fedora (Linux)
- **Matériel** : Acer Nitro AN515-58, Intel UHD + RTX 4060 (dual-GPU Optimus)
- **Session** : Wayland + **sway** (window manager tiling)
- **Terminal** : ghostty
- **Lanceur** : rofi (`rofi -show drun`, thème Crépuscule rose avec icônes Papirus)
- **Audio** : pactl (PipeWire)
- **Rétroéclairage** : brightnessctl
- **Captures** : grim (+ slurp pour la sélection)

## Conventions sway

- Touche modificatrice `$mod` = **Super** (Mod4)
- Navigation façon Vim : `h` / `j` / `k` / `l` = gauche / bas / haut / droite
- Config potentiellement éclatée en plusieurs fichiers via `include`

## Palette (thème « Crépuscule rose »)

À appliquer de manière cohérente sur tous les composants (sway, waybar, ghostty,
mako, swaylock, gtk…).

| Rôle              | Hex       |
|-------------------|-----------|
| bg (fond)         | `#150d24` |
| bg-alt            | `#1e1233` |
| surface           | `#2d2872` |
| muted (bordures)  | `#4b3a8c` |
| slate             | `#323169` |
| mauve             | `#7e4ca0` |
| magenta           | `#b35298` |
| rose (focus)      | `#e3779e` |
| peach (lune)      | `#efaaa2` |
| lilac (texte dim) | `#c9add1` |
| fg (texte)        | `#ece4f2` |

**Règle d'accent** : `rose` (#e3779e) pour le focus / la fenêtre active et les
éléments interactifs ; `peach` pour les accents chauds ponctuels (batterie pleine,
notifications positives) ; `slate`/`mauve` pour le froid.

## Gestion du repo (IMPORTANT)

- Les configs vivent dans CE repo, sous `~/Documents/dotfiles/`.
- Elles sont liées vers `~/.config/` par **symlinks via GNU Stow**.
  Structure attendue : `dotfiles/<appli>/.config/<appli>/...`
- Ne JAMAIS supprimer un fichier de config original sans avoir vérifié que le
  symlink est en place et fonctionnel.
- Stow crée des symlinks de **répertoire** (ex : `~/.config/rofi → dotfiles/rofi/.config/rofi`) :
  un `rm` dans `~/.config/<appli>/` supprime les fichiers du dotfiles lui-même.

## Règles de sécurité (à respecter strictement)

- **Ne jamais lancer `swaymsg reload` ni `swaymsg exit` sans me demander.**
- **Ne jamais déplacer/supprimer une config sans créer le symlink de remplacement
  dans la foulée**, pour ne pas casser la session en cours.
- Avant toute opération risquée sur `~/.config`, faire un `git add -A && git commit`
  pour avoir un point de retour.
- Travailler **un composant à la fois** ; me laisser valider entre chaque étape.
- Pour tester une config sway : proposer la commande, mais me laisser l'exécuter.
- Tenir compte du dual-GPU Optimus : ne pas supposer de réglages GPU génériques.

## Workflow attendu

1. Tu proposes une modification ciblée.
2. Je l'applique / je reload moi-même et je te dis ce qui cloche visuellement
   (tu ne vois pas mon écran : je suis tes yeux).
3. On itère.