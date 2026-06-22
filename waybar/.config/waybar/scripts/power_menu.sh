#!/bin/bash

set -e

DISPLAY_NAMES=(Lock Logout 'Power Off' Reboot Suspend)
COMMANDS=('swaylock' 'swaymsg exit' 'poweroff' 'reboot' 'suspend')
ICON_PATHS=(
  /home/clem/Images/Icons/system-lock-screen-symbolic.svg
  /home/clem/Images/Icons/logout.svg
  /home/clem/Images/Icons/on-off-button.png
  /home/clem/Images/Icons/actions/system-reboot.svg
  /home/clem/Images/Icons/media-playback-pause-symbolic.svg
)

MENU_ITEMS=()
for i in "${!DISPLAY_NAMES[@]}"; do
  MENU_ITEMS+=("img:${ICON_PATHS[i]}:text:${DISPLAY_NAMES[i]}")
done

CHOICE=$(printf '%s\n' "${MENU_ITEMS[@]}" | wofi --conf ~/.config/wofi/power_menu.conf)

# Extract label from `text:...`
SELECTED_NAME="${CHOICE#*:text:}"

# Match selection and run command
for i in "${!DISPLAY_NAMES[@]}"; do
  if [[ "${DISPLAY_NAMES[i]}" == "$SELECTED_NAME" ]]; then
    eval "${COMMANDS[i]}"
    break
  fi
done
