#!/bin/bash
# Put the ink-paper CSS into WriteFreely's "Custom CSS" for every blog on motoko.one.
# Same as pasting it under Customize -> Custom CSS; survives WriteFreely updates.
# Run from your computer; needs ssh access to the server as the user who owns the database:
#   WF_HOST=myserver WF_DIR=/path/to/writefreely bash apps/writefreely-ink-apply.sh
# Undo:   bash apps/writefreely-ink-apply.sh --revert
set -eu
HOST=${WF_HOST:-hulud}
W=${WF_DIR:-/mnt/HC_Volume_23537516/konrad/motoko.one/writefreely}
CSS="$(dirname "$0")/writefreely-ink.css"
MODE=${1:-apply}

if [ "$MODE" = apply ]; then
  scp -q "$CSS" "$HOST:/tmp/writefreely-ink.css"
fi

ssh "$HOST" bash -s -- "$MODE" "$W" <<'REMOTE'
set -eu
MODE=$1; W=$2
command -v sqlite3 >/dev/null || { echo "sqlite3 is not installed on the server" >&2; exit 1; }
DBF=$(awk -F' *= *' '/^\[/{s=$0} s=="[database]" && $1=="filename"{print $2}' "$W/config.ini")
DBF=${DBF:-writefreely.db}; [[ "$DBF" = /* ]] || DBF="$W/$DBF"
[ -f "$DBF" ] || { echo "database not found: $DBF" >&2; exit 1; }
SAVE="$W/custom-css-before-ink.txt"

echo "Blogs:"
sqlite3 -separator '  ' "$DBF" "SELECT '  ' || alias, title, CASE WHEN ifnull(style_sheet,'')='' THEN '(no custom CSS)' ELSE length(style_sheet) || ' chars custom CSS' END FROM collections;"

if [ "$MODE" = --revert ]; then
  [ -f "$SAVE" ] || { echo "nothing to revert ($SAVE missing)" >&2; exit 1; }
  # restore each blog's previous CSS from the saved JSON ({"alias": "css", ...})
  sqlite3 "$DBF" "UPDATE collections SET style_sheet = json_extract(CAST(readfile('$SAVE') AS TEXT), '$.\"' || alias || '\"');"
  echo "Previous custom CSS restored."
  exit 0
fi

# keep the old CSS once, so --revert can bring it back
if [ ! -f "$SAVE" ]; then
  sqlite3 "$DBF" "SELECT json_group_object(alias, ifnull(style_sheet,'')) FROM collections;" > "$SAVE"
  chmod 600 "$SAVE"
  echo "Old custom CSS saved in $SAVE"
fi
cp -a "$DBF" "$DBF.bak-$(date +%F-%H%M)"
sqlite3 "$DBF" "UPDATE collections SET style_sheet = CAST(readfile('/tmp/writefreely-ink.css') AS TEXT);"
rm -f /tmp/writefreely-ink.css
echo "Ink theme applied to $(sqlite3 "$DBF" 'SELECT count(*) FROM collections;') blog(s). Database backup: $DBF.bak-*"
echo "https://motoko.one -> HTTP $(curl -s -o /dev/null -w '%{http_code}' -m 10 https://motoko.one/)"
REMOTE
