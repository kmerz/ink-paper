#!/bin/bash
# Extend the ink-paper theme to apps: VS Code, Neovim (NvChad), Vim, tmux, bash prompt,
# Firefox, Thunderbird, Joplin, lock screen and Qt apps.
# Close VS Code, Firefox, Thunderbird and Joplin first. Run as yourself, not with sudo:
#   bash ~/Pictures/wallpapers/ink-paper/apps-apply.sh
# revert.sh undoes this together with apply.sh.
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
A="$DIR/apps"
STATE="$DIR/backup"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"

[ "$(id -u)" -eq 0 ] && { echo "Run as your normal user, not with sudo." >&2; exit 1; }
[ -e "$STATE/apps-applied" ] && { echo "App themes are already applied. Run revert.sh first to start over." >&2; exit 1; }

running=$(pgrep -l -f 'firefox|thunderbird|joplin|/code' 2>/dev/null | grep -vE 'pgrep|apps-apply' | awk '{print $2}' | sort -u | tr '\n' ' ')
if [ -n "$running" ]; then
  echo "Please close these apps first (they overwrite their settings on exit): $running"
  read -r -p "Continue anyway? [y/N] " ok
  [ "$ok" = y ] || [ "$ok" = Y ] || exit 1
fi

mkdir -p "$STATE"
if [ -f "$STATE/date" ]; then DATE=$(cat "$STATE/date"); else DATE=$(date +%F); echo "$DATE" > "$STATE/date"; fi
touch "$STATE/files-backed-up" "$STATE/files-created" "$STATE/gsettings.bak-$DATE.txt" "$STATE/revert-commands"

backup_file() {
  if [ -e "$1" ]; then
    grep -qxF "$1" "$STATE/files-backed-up" || { cp -a "$1" "$1.bak-$DATE" && echo "$1" >> "$STATE/files-backed-up"; }
    echo "  backed up $1"
  else
    echo "$1" >> "$STATE/files-created"
  fi
}
put() { backup_file "$2"; mkdir -p "$(dirname "$2")"; cp "$1" "$2"; }           # copy a whole file
append() { backup_file "$2"; mkdir -p "$(dirname "$2")"; cat "$1" >> "$2"; }    # add a block to a file
undo() { echo "$1" >> "$STATE/revert-commands"; }

# ---------- VS Code ----------
echo "== VS Code: Ink Paper / Ink Dark, follows system light/dark"
if command -v code >/dev/null; then
  VSIX="$A/ink-paper.vsix"
  python3 -I - "$A/vscode" "$VSIX" <<'PY'
import sys, zipfile, pathlib
src, out = pathlib.Path(sys.argv[1]), sys.argv[2]
manifest = """<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="ink-paper" Version="1.0.0" Publisher="local" />
    <DisplayName>Ink Paper</DisplayName>
    <Description xml:space="preserve">Ink on paper color theme</Description>
    <Categories>Themes</Categories>
    <Properties><Property Id="Microsoft.VisualStudio.Code.Engine" Value="^1.70.0" /></Properties>
  </Metadata>
  <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code" /></Installation>
  <Dependencies />
  <Assets><Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true" /></Assets>
</PackageManifest>"""
types = """<?xml version="1.0" encoding="utf-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension=".json" ContentType="application/json" /><Default Extension=".vsixmanifest" ContentType="text/xml" /></Types>"""
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("extension.vsixmanifest", manifest)
    z.writestr("[Content_Types].xml", types)
    z.write(src / "package.json", "extension/package.json")
    for f in (src / "themes").glob("*.json"):
        z.write(f, f"extension/themes/{f.name}")
PY
  code --install-extension "$VSIX" --force >/dev/null 2>&1 && echo "  extension installed" \
    && undo "code --uninstall-extension local.ink-paper"
  VS="$CFG/Code/User/settings.json"
  backup_file "$VS"
  mkdir -p "$(dirname "$VS")"; [ -s "$VS" ] || echo '{}' > "$VS"
  python3 -I - "$VS" <<'PY' || echo "  settings.json has comments or errors - set the theme by hand: Ctrl+K Ctrl+T"
import json, sys
p = sys.argv[1]
s = json.load(open(p))
s.update({
    "window.autoDetectColorScheme": True,
    "workbench.preferredLightColorTheme": "Ink Paper",
    "workbench.preferredDarkColorTheme": "Ink Dark",
    "workbench.colorTheme": "Ink Dark",
    "editor.fontFamily": "'IBM Plex Mono', monospace",
    "terminal.integrated.fontFamily": "'IBM Plex Mono'",
})
json.dump(s, open(p, "w"), indent=4)
print("  settings.json updated")
PY
else
  echo "  VS Code not found - skipped"
fi

# ---------- Neovim (NvChad) ----------
echo "== Neovim: ink_paper / ink_dark themes, follows GNOME at startup"
NV="$CFG/nvim"
if [ -f "$NV/lua/chadrc.lua" ]; then
  [ -d "$NV/lua/themes" ] || { mkdir -p "$NV/lua/themes"; echo "$NV/lua/themes" >> "$STATE/files-created"; }
  put "$A/nvim/ink_paper.lua" "$NV/lua/themes/ink_paper.lua"
  put "$A/nvim/ink_dark.lua" "$NV/lua/themes/ink_dark.lua"
  backup_file "$NV/lua/chadrc.lua"
  sed -i -E '0,/theme\s*=\s*"[^"]*"/s//theme = "ink_dark"/' "$NV/lua/chadrc.lua"
  append "$A/nvim/follow-gnome.lua" "$NV/lua/autocmds.lua"
  backup_file "$DATA/nvim/ink-paper-theme"
  undo "nvim --headless '+lua require(\"base46\").load_all_highlights()' +qa"
else
  echo "  NvChad config not found - skipped"
fi

# ---------- Vim ----------
echo "== Vim: inkpaper colorscheme"
put "$A/vim/inkpaper.vim" "$HOME/.vim/colors/inkpaper.vim"
cat > "$STATE/vimrc-block" <<'EOF'
" ink-paper theme (begin)
if has('termguicolors') | set termguicolors | endif
let &background = system('gsettings get org.gnome.desktop.interface color-scheme') =~# 'dark' ? 'dark' : 'light'
syntax on
colorscheme inkpaper
" ink-paper theme (end)
EOF
append "$STATE/vimrc-block" "$HOME/.vimrc"

# ---------- tmux ----------
echo "== tmux: quiet status bar, red only for the session mark and active pane"
if [ -f "$CFG/tmux/tmux.conf" ]; then append "$A/tmux.conf" "$CFG/tmux/tmux.conf"
else append "$A/tmux.conf" "$HOME/.tmux.conf"; fi
tmux source-file "$HOME/.tmux.conf" 2>/dev/null

# ---------- bash prompt ----------
echo "== bash prompt: muted gray, red host name"
cat > "$STATE/bashrc-block" <<'EOF'
# ink-paper prompt (begin)
PS1='\[\e[90m\]\u@\[\e[31m\]\h\[\e[90m\]:\[\e[39m\]\w \[\e[90m\]•\[\e[0m\]\n'
# ink-paper prompt (end)
EOF
append "$STATE/bashrc-block" "$HOME/.bashrc"

# ---------- Firefox and Thunderbird ----------
mozilla() {   # $1 app name, $2 profiles folder
  local base=$2 rel prof
  [ -f "$base/profiles.ini" ] || { echo "  $1: no profiles - skipped"; return; }
  rel=$(awk -F= '/^\[/{p=""} /^Path=/{p=$2} /^Default=1/{if(p!=""){print p; exit}}' "$base/profiles.ini")
  [ -n "$rel" ] || rel=$(awk -F= '/^Path=/{print $2; exit}' "$base/profiles.ini")
  prof="$base/$rel"
  [ -d "$prof" ] || { echo "  $1: profile $prof not found - skipped"; return; }
  echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' > "$STATE/userjs-line"
  append "$STATE/userjs-line" "$prof/user.js"
  append "$A/mozilla-userChrome.css" "$prof/chrome/userChrome.css"
  echo "  $1: profile $(basename "$prof")"
}
echo "== Firefox and Thunderbird: userChrome.css"
mozilla Firefox "$HOME/snap/firefox/common/.mozilla/firefox"
mozilla Thunderbird "$HOME/snap/thunderbird/common/.thunderbird"

# ---------- Joplin ----------
echo "== Joplin: note viewer colors and fonts, follow system light/dark"
JD="$CFG/joplin-desktop"
if [ -d "$JD" ]; then
  append "$A/joplin-userstyle.css" "$JD/userstyle.css"
  if [ -f "$JD/settings.json" ]; then
    backup_file "$JD/settings.json"
    python3 -I - "$JD/settings.json" <<'PY' || echo "  could not edit settings.json - turn on 'Automatically switch theme' in Joplin"
import json, sys
p = sys.argv[1]
s = json.load(open(p))
s["themeAutoDetect"] = True
json.dump(s, open(p, "w"), indent=2)
print("  automatic light/dark switching turned on")
PY
  fi
else
  echo "  Joplin config not found - skipped"
fi

# ---------- lock screen ----------
echo "== Lock screen: ink wallpaper"
echo "org.gnome.desktop.screensaver picture-uri $(gsettings get org.gnome.desktop.screensaver picture-uri)" >> "$STATE/gsettings.bak-$DATE.txt"
dark=$(gsettings get org.gnome.desktop.background picture-uri-dark | tr -d "'")
[[ "$dark" == *ink-paper* ]] || dark="file://$DIR/sketchbook-dark.png"
gsettings set org.gnome.desktop.screensaver picture-uri "$dark"

# ---------- Qt apps ----------
echo "== Qt apps: follow the GNOME/GTK look (after next login)"
QT="$CFG/environment.d/90-ink-paper-qt.conf"
backup_file "$QT"; mkdir -p "$(dirname "$QT")"
echo "QT_QPA_PLATFORMTHEME=gtk3" > "$QT"

touch "$STATE/apps-applied"
echo
echo "Done. Restart VS Code, Firefox, Thunderbird, Joplin, Neovim/Vim and open a new terminal."
echo "Log out and back in once for the Qt setting. Undo everything: bash $DIR/revert.sh"
