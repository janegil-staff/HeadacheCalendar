#!/usr/bin/env bash
# lift-landing.sh
# Landing page: lifts everything a little. The content stays vertically centred, but with
# less space above it than below, so it sits about 40 px higher on desktop (a bit higher on
# phones too, where the language picker keeps its space in the top corner).
# Only the <main> line in src/app/page.js changes. (front-image.sh now includes this too.)
# Run from the project root:  bash lift-landing.sh
set -euo pipefail

FILE=src/app/page.js
OLD='<main className="relative isolate flex min-h-screen items-center justify-center overflow-hidden px-4 py-20">'
NEW='<main className="relative isolate flex min-h-screen items-center justify-center overflow-hidden px-4 pb-28 pt-20 lg:pb-28 lg:pt-8">'

if [ ! -f "$FILE" ]; then
  echo "✗ $FILE not found – run this from the project root." >&2
  exit 1
fi

if grep -qF "$NEW" "$FILE"; then
  echo "✓ $FILE is already lifted"
elif grep -qF "$OLD" "$FILE"; then
  node -e 'const fs=require("fs");const [f,o,n]=process.argv.slice(1);fs.writeFileSync(f,fs.readFileSync(f,"utf8").replace(o,n))' "$FILE" "$OLD" "$NEW"
  echo "✓ $FILE (content lifted)"
else
  echo "✗ $FILE: the <main> line differs from what this script expects – run front-image.sh first." >&2
  exit 1
fi
