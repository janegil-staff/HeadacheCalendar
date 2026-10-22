#!/usr/bin/env bash
# text-over-image.sh
# Landing page (desktop): the headline "Hodepinedagboken" and the intro text sit only over the
# image with the three phones – same width as the image and lined up with it, right next to
# the code card. "Read more" lines up under the image the same way.
#  - image: 75 % of the left column, at the card side (mirrored for Arabic/Hebrew); its height
#    now follows its width, so the text is exactly as wide as the phones
#  - headline one step smaller on very wide screens so it fits over the image
#  - includes the "smaller image, next to the card" change (smaller-image.sh)
#  - phones/tablets look as before
# Works on page.js from front-image.sh with or without smaller-image.sh; safe to run again.
# (front-image.sh includes this too, so running it again won't undo it.)
# Run from the project root:  bash text-over-image.sh
set -euo pipefail

FILE=src/app/page.js
if [ ! -f "$FILE" ]; then
  echo "✗ $FILE not found – run this from the project root." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/changes.json" <<'FILE_END'
[
  {"what": "the header line",
   "from": ["<header className=\"max-w-2xl text-center lg:col-start-1 lg:row-start-1 lg:text-start\">"],
   "to": "<header className=\"max-w-2xl text-center lg:col-start-1 lg:row-start-1 lg:w-[75%] lg:max-w-none lg:justify-self-end lg:text-start\">"},
  {"what": "the headline size",
   "from": ["<h1 className=\"font-serif text-4xl font-bold text-blue-800 sm:text-5xl xl:text-6xl\">"],
   "to": "<h1 className=\"font-serif text-4xl font-bold text-blue-800 sm:text-5xl\">"},
  {"what": "the intro text size",
   "from": ["<p className=\"mt-4 text-base leading-relaxed text-slate-700 sm:text-lg xl:text-xl\">"],
   "to": "<p className=\"mt-4 text-base leading-relaxed text-slate-700 sm:text-lg\">"},
  {"what": "the language picker line",
   "from": ["lg:mt-11 lg:self-start lg:justify-self-end xl:mt-14\">"],
   "to": "lg:mt-11 lg:self-start lg:justify-self-end\">"},
  {"what": "the FrontImage line",
   "from": ["<FrontImage className=\"hidden h-auto max-h-[72vh] w-full object-contain drop-shadow-2xl ltr:object-left rtl:object-right lg:col-start-1 lg:row-start-2 lg:block\" />",
            "<FrontImage className=\"hidden h-auto max-h-[62vh] w-[85%] object-contain drop-shadow-2xl ltr:object-left rtl:object-right lg:col-start-1 lg:row-start-2 lg:block lg:justify-self-start\" />",
            "<FrontImage className=\"hidden h-auto max-h-[62vh] w-[75%] object-contain drop-shadow-2xl ltr:object-right rtl:object-left lg:col-start-1 lg:row-start-2 lg:block lg:justify-self-end\" />"],
   "to": "<FrontImage className=\"hidden h-auto w-[75%] drop-shadow-2xl lg:col-start-1 lg:row-start-2 lg:block lg:justify-self-end\" />"},
  {"what": "the grid line",
   "from": ["lg:grid-cols-[minmax(0,1fr)_minmax(0,28rem)] lg:gap-x-10 xl:gap-x-14\">"],
   "to": "lg:grid-cols-[minmax(0,1fr)_minmax(0,28rem)] lg:gap-x-6 xl:gap-x-8\">"},
  {"what": "the read-more line",
   "from": ["<div className=\"flex justify-center lg:col-start-1 lg:row-start-3 lg:justify-start\">"],
   "to": "<div className=\"flex justify-center lg:col-start-1 lg:row-start-3 lg:w-[75%] lg:justify-self-end lg:justify-start\">"}
]
FILE_END

node - "$FILE" "$TMP/changes.json" <<'NODE_END'
const fs = require("fs");
const [file, changesFile] = process.argv.slice(2);
let src = fs.readFileSync(file, "utf8");
for (const c of JSON.parse(fs.readFileSync(changesFile, "utf8"))) {
  if (src.includes(c.to)) continue;
  const hit = c.from.find((f) => src.includes(f));
  if (!hit) {
    console.error(`✗ ${file}: ${c.what} differs from what this script expects – run front-image.sh first.`);
    process.exit(1);
  }
  src = src.replace(hit, c.to);
}
fs.writeFileSync(file, src);
console.log(`✓ ${file} (headline and text over the phone image only)`);
NODE_END
