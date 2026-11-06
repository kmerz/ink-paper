#!/bin/bash
# Undo everything apply.sh changed. Run as yourself, not with sudo:
#   bash ~/Pictures/wallpapers/ink-paper/revert.sh
# The wallpaper images and these scripts stay; delete the folder if you want them gone.
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
STATE="$DIR/backup"
[ "$(id -u)" -eq 0 ] && { echo "Run as your normal user, not with sudo." >&2; exit 1; }
[ -f "$STATE/date" ] || { echo "Nothing to revert: $STATE/date not found." >&2; exit 1; }
DATE=$(cat "$STATE/date")

echo "== Restoring GNOME settings"
if [ -f "$STATE/gsettings.bak-$DATE.txt" ]; then
  while read -r schema key value; do
    gsettings set "$schema" "$key" "$value" && echo "  $schema $key = $value"
  done < "$STATE/gsettings.bak-$DATE.txt"
fi

echo "== Restoring terminal settings"
if [ -f "$STATE/gnome-terminal.bak-$DATE.dconf" ]; then
  dconf reset -f /org/gnome/terminal/
  dconf load /org/gnome/terminal/ < "$STATE/gnome-terminal.bak-$DATE.dconf"
  echo "  gnome-terminal restored (Ink profiles removed)"
fi
if [ -f "$STATE/ptyxis.bak-$DATE.dconf" ]; then
  dconf reset -f /org/gnome/Ptyxis/
  dconf load /org/gnome/Ptyxis/ < "$STATE/ptyxis.bak-$DATE.dconf"
  echo "  Ptyxis restored"
fi

echo "== Restoring changed files from their .bak-$DATE copies"
if [ -f "$STATE/files-backed-up" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] && [ -e "$f.bak-$DATE" ] && mv -f "$f.bak-$DATE" "$f" && echo "  restored $f"
  done < "$STATE/files-backed-up"
fi

echo "== Undoing app changes (VS Code extension, Neovim color cache)"
if [ -f "$STATE/revert-commands" ]; then
  while IFS= read -r cmd; do
    [ -n "$cmd" ] && echo "  $cmd" && bash -c "$cmd" >/dev/null 2>&1
  done < "$STATE/revert-commands"
fi

echo "== Removing files the theme created"
if [ -f "$STATE/files-created" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] && [ -e "$f" ] && rm -rf "$f" && echo "  removed $f"
  done < "$STATE/files-created"
fi
rmdir "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/themes" 2>/dev/null

rm -rf "$STATE"
echo
echo "Reverted. Log out and back in once to make sure every app is back to normal."
echo "The fonts and Papirus packages are still installed. To remove them too:"
echo "  sudo apt remove fonts-ibm-plex papirus-icon-theme"
