#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <file>"
  exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
  echo "File not found: $FILE"
  exit 1
fi

EXT=$(echo "${FILE##*.}" | tr '[:upper:]' '[:lower:]')

if [[ "$EXT" == "png" || "$EXT" == "jpg" || "$EXT" == "jpeg" || "$EXT" == "gif" ]]; then
  if [[ "$EXT" == "png" ]]; then
    MIME="image/png"
  elif [[ "$EXT" == "gif" ]]; then
    MIME="image/gif"
  else
    MIME="image/jpeg"
  fi

  DATA_URI="data:$MIME;base64,$(base64 -w 0 "$FILE")"

  RESPONSE=$(printf '%s' "$DATA_URI" | curl -s -D - --data-binary @- https://paste.rs)
else
  RESPONSE=$(curl -s -D - --data-binary "@$FILE" https://paste.rs)
fi

PASTE_URL=$(echo "$RESPONSE" | tail -n 1)
DELETE_URL=$(echo "$RESPONSE" | grep -i '^X-Delete-Url:' | awk '{print $2}' | tr -d '\r')

echo "Uploaded URL: $PASTE_URL"
echo "Delete command:"
echo "curl -X DELETE $DELETE_URL"

CLEAN_TEXT=$(curl -s "$PASTE_URL")

if command -v xclip >/dev/null 2>&1; then
  printf '%s' "$CLEAN_TEXT" | xclip -selection clipboard
  echo "Copied Base64 text to clipboard (xclip)"
elif command -v wl-copy >/dev/null 2>&1; then
  printf '%s' "$CLEAN_TEXT" | wl-copy
  echo "Copied Base64 text to clipboard (wl-copy)"
else
  echo "Clipboard tool not found (install xclip or wl-clipboard)"
fi
echo "Now paste it directly into Browser URL bar"
