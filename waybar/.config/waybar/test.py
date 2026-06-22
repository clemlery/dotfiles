from pathlib import Path

wofi_conf_path = str(Path.home() / ".config/wofi/power_menu.conf")
print(f"wofi_conf_path : ", wofi_conf_path)