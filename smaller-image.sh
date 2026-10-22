#!/usr/bin/env bash
# smaller-image.sh
# Landing page: the image with the three phones is about 15 % smaller (85 % of the left
# column's width, at most 62 % of the screen height instead of 72 %), still lined up with
# the text on the left. Only the FrontImage line in src/app/page.js changes.
# (front-image.sh now includes this too, so running it again won't undo it.)
# Run from the project root:  bash smaller-image.sh
set -euo pipefail

FILE=src/app/page.js
OLD='<FrontImage className="hidden h-auto max-h-[72vh] w-full object-contain drop-shadow-2xl ltr:object-left rtl:object-right lg:col-start-1 lg:row-start-2 lg:block" />'
NEW='<FrontImage className="hidden h-auto max-h-[62vh] w-[85%] object-contain drop-shadow-2xl ltr:object-left rtl:object-right lg:col-start-1 lg:row-start-2 lg:block lg:justify-self-start" />'

if [ ! -f "$FILE" ]; then
  echo "✗ $FILE not found – run this from the project root." >&2
  exit 1
fi

if grep -qF "$NEW" "$FILE"; then
  echo "✓ $FILE: the image is already smaller"
elif grep -qF "$OLD" "$FILE"; then
  node -e 'const fs=require("fs");const [f,o,n]=process.argv.slice(1);fs.writeFileSync(f,fs.readFileSync(f,"utf8").replace(o,n))' "$FILE" "$OLD" "$NEW"
  echo "✓ $FILE (image made smaller)"
else
  echo "✗ $FILE: the FrontImage line differs from what this script expects – run front-image.sh first." >&2
  exit 1
fi
