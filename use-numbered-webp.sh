#!/usr/bin/env bash
# use-numbered-webp.sh
# The About modal loads 01.webp … 09.webp
# Run from the project root:  bash use-numbered-webp.sh
set -euo pipefail

F=src/components/landing/AboutAppModal.js
[ -f "$F" ] || { echo "✗ $F not found – run add-about-modal.sh first." >&2; exit 1; }

# Works whether the file currently uses ${page}.png or ${page}.webp
perl -pi -e 's/\$\{page\}\.(png|webp)/\$\{String(page).padStart(2, "0")\}.webp/g' "$F"

if grep -q 'padStart(2, "0")}.webp' "$F"; then
  echo "✓ $F now loads 01.webp – 09.webp"
else
  echo "✗ Could not find the image path in $F" >&2; exit 1
fi

# Check the screenshots
IMG=public/images/about-app
if [ -d "$IMG" ]; then
  [ -f "$IMG/no/01.webp" ] || echo "⚠ $IMG/no/01.webp missing – Norwegian is the fallback for all languages"
  missing=""
  for code in ar bg bs ca cs da de el en es et fi fr he hr hu is it ja lt lv mk nl no pl pt pt-BR ro ru sk sl sr sv tr uk; do
    for n in 1 2 3 4 5 6 7 8 9; do
      if [ ! -f "$IMG/$code/0$n.webp" ]; then missing="$missing $code"; break; fi
    done
  done
  if [ -n "$missing" ]; then
    echo "ℹ Incomplete or missing image folders (Norwegian images are used instead):$missing"
  else
    echo "✓ All 35 image folders have 01.webp – 09.webp"
  fi
else
  echo "⚠ $IMG not found"
fi
