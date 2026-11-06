#!/bin/bash
# Apply the "ink on paper" theme for GNOME. Run as yourself, not with sudo:
#   bash ~/Pictures/wallpapers/ink-paper/apply.sh [sketchbook|brush|vignette]
# Undo everything with revert.sh in the same folder.
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
WP="${1:-sketchbook}"
DATE=$(date +%F)
STATE="$DIR/backup"                     # what revert.sh needs
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"

[ "$(id -u)" -eq 0 ] && { echo "Run as your normal user, not with sudo." >&2; exit 1; }
[ -e "$STATE/applied" ] && { echo "Theme is already applied. Run revert.sh first to start over." >&2; exit 1; }
for m in light dark; do
  [ -f "$DIR/$WP-$m.png" ] || { echo "Missing $DIR/$WP-$m.png - run make_wallpapers.py first." >&2; exit 1; }
done
mkdir -p "$STATE"
# share one backup record with apps-apply.sh, so revert.sh undoes both
if [ -f "$STATE/date" ]; then DATE=$(cat "$STATE/date"); else echo "$DATE" > "$STATE/date"; fi
touch "$STATE/files-backed-up" "$STATE/files-created"

# ---------- palette ----------
L_BG="#F2EEE6"; L_SURF="#E7E2D8"; L_TEXT="#1A1A1A"; L_MUTED="#8A8580"; L_ACC="#B23A2E"
D_BG="#141414"; D_SURF="#1E1E1E"; D_TEXT="#E9E4DA"; D_MUTED="#5C5853"; D_ACC="#C8473A"
# terminal ANSI 0-15, muted toward warm grays; red is the only strong color
L_ANSI=("#1A1A1A" "#B23A2E" "#5F6152" "#7D6E52" "#565D68" "#6B5A60" "#56625F" "#6E6A64"
        "#8A8580" "#C8473A" "#717364" "#8F8064" "#69707B" "#7D6C72" "#687471" "#5C5853")
D_ANSI=("#1E1E1E" "#C8473A" "#8E907F" "#B3A283" "#858C96" "#9E8A92" "#869390" "#B8B2A8"
        "#5C5853" "#C8473A" "#A3A593" "#C7B697" "#9AA1AB" "#B39FA7" "#9BA8A5" "#E9E4DA")

# ---------- helpers ----------
backup_file() {   # copy an existing file to <file>.bak-<date>, or note that we create it
  if [ -e "$1" ]; then
    cp -a "$1" "$1.bak-$DATE" && echo "$1" >> "$STATE/files-backed-up"
    echo "  backed up $1 -> $1.bak-$DATE"
  else
    echo "$1" >> "$STATE/files-created"
  fi
}
save_gsetting() { echo "$1 $2 $(gsettings get "$1" "$2")" >> "$STATE/gsettings.bak-$DATE.txt"; }
gvariant_list() { local out="" c; for c in "$@"; do out+="'$c', "; done; echo "[${out%, }]"; }

echo "== Saving current settings"
touch "$STATE/gsettings.bak-$DATE.txt"
for k in color-scheme accent-color gtk-theme icon-theme font-name document-font-name monospace-font-name; do
  save_gsetting org.gnome.desktop.interface "$k"
done
save_gsetting org.gnome.desktop.wm.preferences titlebar-font
for k in picture-uri picture-uri-dark picture-options primary-color; do
  save_gsetting org.gnome.desktop.background "$k"
done
dconf dump /org/gnome/terminal/ > "$STATE/gnome-terminal.bak-$DATE.dconf"
dconf dump /org/gnome/Ptyxis/ > "$STATE/ptyxis.bak-$DATE.dconf"

# ---------- fonts ----------
echo "== Fonts: IBM Plex Sans (interface), IBM Plex Mono (terminal)"
if fc-list : family | grep -q 'IBM Plex Sans'; then
  gsettings set org.gnome.desktop.interface font-name 'IBM Plex Sans 11'
  gsettings set org.gnome.desktop.interface document-font-name 'IBM Plex Sans 11'
  gsettings set org.gnome.desktop.interface monospace-font-name 'IBM Plex Mono 11'
  gsettings set org.gnome.desktop.wm.preferences titlebar-font 'IBM Plex Sans Bold 11'
else
  echo "  IBM Plex not installed - skipped (sudo apt install fonts-ibm-plex)"
fi

# ---------- icons: Papirus with gray folders, as a small theme in your home ----------
echo "== Icons: Papirus with gray folders"
ICONS_OK=no
make_icon_theme() {   # $1 = new theme name, $2 = theme it builds on
  local dest="$DATA/icons/$1" src=/usr/share/icons/Papirus d sz f b
  mkdir -p "$dest"
  sed -e "s/^Name=.*/Name=$1/" -e "s/^Inherits=.*/Inherits=$2,hicolor/" "$src/index.theme" > "$dest/index.theme"
  for d in "$src"/*/places; do
    sz=$(basename "$(dirname "$d")")
    [ -L "$src/$sz" ] && continue
    mkdir -p "$dest/$sz/places"
    for f in "$d"/*-grey*.svg; do
      [ -e "$f" ] || continue
      b=$(basename "$f")
      ln -sf "$f" "$dest/$sz/places/${b/-grey/}"   # folder-grey-music.svg -> folder-music.svg
    done
  done
  for d in "$src"/*@2x; do [ -L "$d" ] && ln -sfn "$(readlink "$d")" "$dest/$(basename "$d")"; done
  gtk-update-icon-cache -q -f -t "$dest" 2>/dev/null
  echo "$dest" >> "$STATE/files-created"
}
if [ -d /usr/share/icons/Papirus ] && [ -d /usr/share/icons/Papirus-Dark ]; then
  make_icon_theme Papirus-Ink Papirus
  make_icon_theme Papirus-Ink-Dark Papirus-Dark
  ICONS_OK=yes
  echo "  created Papirus-Ink and Papirus-Ink-Dark in $DATA/icons"
else
  echo "  Papirus not installed - skipped (sudo apt install papirus-icon-theme)"
fi
echo "$ICONS_OK" > "$STATE/icons"

# ---------- app colors and corners (GTK 4 / libadwaita apps) ----------
echo "== App accent, colors and corners"
CSS="$CFG/gtk-4.0/gtk.css"
mkdir -p "$CFG/gtk-4.0"
backup_file "$CSS"
cat >> "$CSS" <<EOF
/* ink-paper theme (begin) */
:root {
  --accent-bg-color: $L_ACC;
  --accent-color: $L_ACC;
  --accent-fg-color: $L_BG;
  --window-bg-color: $L_SURF;
  --window-fg-color: $L_TEXT;
  --view-bg-color: $L_BG;
  --view-fg-color: $L_TEXT;
  --headerbar-bg-color: $L_SURF;
  --headerbar-fg-color: $L_TEXT;
  --sidebar-bg-color: $L_SURF;
  --sidebar-fg-color: $L_TEXT;
  --popover-bg-color: $L_BG;
  --popover-fg-color: $L_TEXT;
  --dialog-bg-color: $L_BG;
  --dialog-fg-color: $L_TEXT;
  --destructive-bg-color: $L_ACC;
  --error-color: $L_ACC;
  --window-radius: 6px;
}
@media (prefers-color-scheme: dark) {
  :root {
    --accent-bg-color: $D_ACC;
    --accent-color: $D_ACC;
    --accent-fg-color: $D_TEXT;
    --window-bg-color: $D_SURF;
    --window-fg-color: $D_TEXT;
    --view-bg-color: $D_BG;
    --view-fg-color: $D_TEXT;
    --headerbar-bg-color: $D_SURF;
    --headerbar-fg-color: $D_TEXT;
    --sidebar-bg-color: $D_SURF;
    --sidebar-fg-color: $D_TEXT;
    --popover-bg-color: $D_SURF;
    --popover-fg-color: $D_TEXT;
    --dialog-bg-color: $D_SURF;
    --dialog-fg-color: $D_TEXT;
    --destructive-bg-color: $D_ACC;
    --error-color: $D_ACC;
  }
}
/* square-ish corners */
button:not(.circular):not(.pill), entry, spinbutton, popover > contents, .card {
  border-radius: 4px;
}
/* ink-paper theme (end) */
EOF

# ---------- wallpaper (GNOME shows the -dark one in dark mode) ----------
echo "== Wallpaper: $WP"
gsettings set org.gnome.desktop.background picture-uri "file://$DIR/$WP-light.png"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$DIR/$WP-dark.png"
gsettings set org.gnome.desktop.background picture-options 'zoom'
gsettings set org.gnome.desktop.background primary-color "$L_BG"

# ---------- terminals ----------
echo "== Terminal: gnome-terminal (profiles 'Ink Paper' and 'Ink Dark')"
gt_profile() {   # $1 uuid, $2 name, $3 bg, $4 fg, $5 accent, $6 selection bg, rest: 16 colors
  local u=$1 name=$2 bg=$3 fg=$4 acc=$5 sel=$6; shift 6
  local P="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$u/"
  gsettings set "$P" visible-name "'$name'"
  gsettings set "$P" use-theme-colors false
  gsettings set "$P" background-color "$bg"
  gsettings set "$P" foreground-color "$fg"
  gsettings set "$P" palette "$(gvariant_list "$@")"
  gsettings set "$P" bold-color-same-as-fg true
  gsettings set "$P" bold-is-bright false
  gsettings set "$P" cursor-colors-set true
  gsettings set "$P" cursor-background-color "$acc"
  gsettings set "$P" cursor-foreground-color "$bg"
  gsettings set "$P" highlight-colors-set true
  gsettings set "$P" highlight-background-color "$sel"
  gsettings set "$P" highlight-foreground-color "$bg"
  gsettings set "$P" use-system-font true
}
if gsettings list-schemas | grep -qx org.gnome.Terminal.ProfilesList; then
  UL=$(cat /proc/sys/kernel/random/uuid); UD=$(cat /proc/sys/kernel/random/uuid)
  gt_profile "$UL" "Ink Paper" "$L_BG" "$L_TEXT" "$L_ACC" "$L_MUTED" "${L_ANSI[@]}"
  gt_profile "$UD" "Ink Dark" "$D_BG" "$D_TEXT" "$D_ACC" "$D_MUTED" "${D_ANSI[@]}"
  list=$(gsettings get org.gnome.Terminal.ProfilesList list)
  if [[ "$list" == *"'"* ]]; then
    gsettings set org.gnome.Terminal.ProfilesList list "${list%]}, '$UL', '$UD']"
  else   # empty list ("@as []")
    gsettings set org.gnome.Terminal.ProfilesList list "['$UL', '$UD']"
  fi
  printf '%s\n%s\n' "$UL" "$UD" > "$STATE/gnome-terminal-profiles"
else
  echo "  gnome-terminal settings not found - skipped"
fi

echo "== Terminal: Ptyxis (palette 'Ink Paper', follows light/dark automatically)"
PAL="$DATA/org.gnome.Ptyxis/palettes/ink-paper.palette"
mkdir -p "$(dirname "$PAL")"
backup_file "$PAL"
{
  echo "[Palette]"; echo "Name=Ink Paper"; echo
  echo "[Light]"; echo "Foreground=$L_TEXT"; echo "Background=$L_BG"; echo "Cursor=$L_ACC"
  for i in "${!L_ANSI[@]}"; do echo "Color$i=${L_ANSI[$i]}"; done; echo
  echo "[Dark]"; echo "Foreground=$D_TEXT"; echo "Background=$D_BG"; echo "Cursor=$D_ACC"
  for i in "${!D_ANSI[@]}"; do echo "Color$i=${D_ANSI[$i]}"; done
} > "$PAL"
PU=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'")
if [ -n "$PU" ]; then
  gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/$PU/" palette 'ink-paper'
else
  echo "  Ptyxis has no profile yet - open Ptyxis once, then pick 'Ink Paper' in its preferences"
fi

echo "== Terminal: Ghostty (follows light/dark automatically)"
GD="$CFG/ghostty"
mkdir -p "$GD/themes"
if [ -f "$GD/config.ghostty" ]; then GC="$GD/config.ghostty"; else GC="$GD/config"; fi
for m in paper dark; do
  backup_file "$GD/themes/ink-$m"
  if [ $m = paper ]; then bg=$L_BG fg=$L_TEXT acc=$L_ACC sel=$L_MUTED; ansi=("${L_ANSI[@]}")
  else bg=$D_BG fg=$D_TEXT acc=$D_ACC sel=$D_MUTED; ansi=("${D_ANSI[@]}"); fi
  {
    echo "background = $bg"; echo "foreground = $fg"; echo "cursor-color = $acc"
    echo "selection-background = $sel"; echo "selection-foreground = $bg"
    for i in "${!ansi[@]}"; do echo "palette = $i=${ansi[$i]}"; done
  } > "$GD/themes/ink-$m"
done
backup_file "$GC"
touch "$GC"
# turn off existing color/font lines so ours win, then add ours
sed -i -E 's/^(\s*(theme|font-family|background|foreground|palette|cursor-color|selection-background|selection-foreground)\s*=)/# ink-paper: \1/' "$GC"
cat >> "$GC" <<'EOF'
# ink-paper theme (begin)
theme = light:ink-paper,dark:ink-dark
font-family = IBM Plex Mono
background-opacity = 0.92
# ink-paper theme (end)
EOF

# ---------- light/dark switcher ----------
echo "== Installing the 'ink-mode' switcher"
mkdir -p "$HOME/.local/bin"
backup_file "$HOME/.local/bin/ink-mode"
cat > "$HOME/.local/bin/ink-mode" <<EOF
#!/bin/bash
# Switch the ink-paper theme: ink-mode light | dark | toggle
mode=\${1:-toggle}
if [ "\$mode" = toggle ]; then
  [ "\$(gsettings get org.gnome.desktop.interface color-scheme)" = "'prefer-dark'" ] && mode=light || mode=dark
fi
icons=\$(cat "$STATE/icons" 2>/dev/null)
profiles=("\$(sed -n 1p "$STATE/gnome-terminal-profiles" 2>/dev/null)" "\$(sed -n 2p "$STATE/gnome-terminal-profiles" 2>/dev/null)")
case "\$mode" in
  light)
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-red'
    [ "\$icons" = yes ] && gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Ink'
    [ -n "\${profiles[0]}" ] && gsettings set org.gnome.Terminal.ProfilesList default "\${profiles[0]}" ;;
  dark)
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-red-dark'
    [ "\$icons" = yes ] && gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Ink-Dark'
    [ -n "\${profiles[1]}" ] && gsettings set org.gnome.Terminal.ProfilesList default "\${profiles[1]}" ;;
  *) echo "usage: ink-mode light|dark|toggle" >&2; exit 1 ;;
esac
echo "ink-mode: \$mode"
EOF
chmod +x "$HOME/.local/bin/ink-mode"

# ---------- accent and mode ----------
echo "== Accent red, keeping your current light/dark mode"
gsettings set org.gnome.desktop.interface accent-color 'red'
if [ "$(gsettings get org.gnome.desktop.interface color-scheme)" = "'prefer-dark'" ]; then
  "$HOME/.local/bin/ink-mode" dark
else
  "$HOME/.local/bin/ink-mode" light
fi

touch "$STATE/applied"
echo
echo "Done. Switch with:  ink-mode light | ink-mode dark | ink-mode toggle"
echo "Undo everything:    bash $DIR/revert.sh"
echo "Log out and back in once so every app picks up the new fonts and colors."
