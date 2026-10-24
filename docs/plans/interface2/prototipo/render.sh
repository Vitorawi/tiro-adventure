#!/bin/sh
# Renderiza um HTML do protótipo em PNG (360x780 a 2x). Uso: sh render.sh tiro  |  sh render.sh missoes premio
CHROME="/c/Program Files/Google/Chrome/Application/chrome.exe"
DIR="$(cd "$(dirname "$0")" && pwd -W)"
OUT="$1"; URL="file:///$DIR/$1.html"
if [ -n "$2" ]; then OUT="$1_$2"; URL="$URL#$2"; fi
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files --force-device-scale-factor=2 \
  --virtual-time-budget=4000 --window-size=${W:-360},${H:-780} --screenshot="$DIR/$OUT.png" "$URL" 2>/dev/null
