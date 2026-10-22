#!/usr/bin/env bash
# smaller-image.sh
# Landing page: the image with the three phones is narrower and sits right next to the code card:
#  - 75 % of the left column's width (at most 62 % of the screen height)
#  - placed at the card side of its column (mirrored for Arabic/Hebrew), not at the far left
#  - less space between the image column and the card column
# Only two lines in src/app/page.js change (the grid and the FrontImage line).
# Works whether page.js has the original or the earlier "smaller" image; safe to run again.
# (front-image.sh includes this too, so running it again won't undo it.)
# Run from the project root:  bash smaller-image.sh
set -euo pipefail

FILE=src/app/page.js
if [ ! -f "$FILE" ]; then
  echo "✗ $FILE not found – run this from the project root." >&2
  exit 1
fi

node - "$FILE" <<'NODE_END'
const fs = require("fs");
const file = process.argv[2];
let src = fs.readFileSync(file, "utf8");

const changes = [
  {
    what: "the FrontImage line",
    from: [
      '<FrontImage className="hidden h-auto max-h-[72vh] w-full object-contain drop-shadow-2xl ltr:object-left rtl:object-right lg:col-start-1 lg:row-start-2 lg:block" />',
      '<FrontImage className="hidden h-auto max-h-[62vh] w-[85%] object-contain drop-shadow-2xl ltr:object-left rtl:object-right lg:col-start-1 lg:row-start-2 lg:block lg:justify-self-start" />',
    ],
    to: '<FrontImage className="hidden h-auto max-h-[62vh] w-[75%] object-contain drop-shadow-2xl ltr:object-right rtl:object-left lg:col-start-1 lg:row-start-2 lg:block lg:justify-self-end" />',
  },
  {
    what: "the grid line",
    from: ['lg:grid-cols-[minmax(0,1fr)_minmax(0,28rem)] lg:gap-x-10 xl:gap-x-14">'],
    to: 'lg:grid-cols-[minmax(0,1fr)_minmax(0,28rem)] lg:gap-x-6 xl:gap-x-8">',
  },
];

for (const c of changes) {
  if (src.includes(c.to)) continue;
  const hit = c.from.find((f) => src.includes(f));
  if (!hit) {
    console.error(`✗ ${file}: ${c.what} differs from what this script expects – run front-image.sh first.`);
    process.exit(1);
  }
  src = src.replace(hit, c.to);
}
fs.writeFileSync(file, src);
console.log(`✓ ${file} (image narrower and next to the code card)`);
NODE_END
