#!/usr/bin/env python3

import subprocess
import sys
from pathlib import Path

POWER_ACTIONS = {
    "Lock": ("system-lock-screen", "swaylock"),
    "Logout": ("system-log-out", "swaymsg exit"),
    "Suspend": ("system-suspend", "systemctl suspend"),
    "Reboot": ("system-reboot", "reboot"),
    "Power Off": ("system-shutdown", "poweroff"),
}

menu_entries = [
    f"{name}\0icon\x1f{icon}"
    for name, (icon, _) in POWER_ACTIONS.items()
]

try:
    choice = subprocess.run(
        [
            "rofi",
            "-dmenu",
            "-show-icons",
            "-theme", str(Path.home() / ".config/rofi/power_menu.rasi"),
            "-p", "Power"
        ],
        input="\n".join(menu_entries),
        text=True,
        capture_output=True,
        check=True
    ).stdout.strip()
except subprocess.CalledProcessError:
    sys.exit(0)

if not choice:
    sys.exit(0)

if choice in POWER_ACTIONS:
    subprocess.run(POWER_ACTIONS[choice][1], shell=True)
