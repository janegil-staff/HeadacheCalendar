#!/usr/bin/env bash
# footer.sh
# Landing page: copyright and contact at the very bottom, centred, like on kolskalender:
#   Copyright 2026 - KBB Medic AS (org: 912 372 022)
#   ✉ post@kbbmedic.com   (opens the mail program)
#  - the year follows the current year automatically
#  - same in every language (company name and address)
#  - safe to run again
# Run from the project root:  bash footer.sh   (after store-links.sh)
set -euo pipefail

PAGE=src/app/page.js
if [ ! -f "$PAGE" ]; then
  echo "✗ $PAGE not found – run this from the project root." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/change.json" <<'FILE_END'
{
  "anchor": "          <StoreLinks />\n        </div>\n",
  "add": "\n        {/* Copyright and contact, centred at the very bottom */}\n        <footer className=\"mt-2 text-center text-sm leading-relaxed text-slate-600 lg:col-span-2 lg:row-start-5\">\n          <p>Copyright {new Date().getFullYear()} - KBB Medic AS (org: 912 372 022)</p>\n          <p>\n            <a href=\"mailto:post@kbbmedic.com\" className=\"hover:text-blue-800 hover:underline\">\n              <span aria-hidden=\"true\">✉</span> post@kbbmedic.com\n            </a>\n          </p>\n        </footer>\n"
}
FILE_END

node - "$PAGE" "$TMP/change.json" <<'NODE_END'
const fs = require("fs");
const [file, changeFile] = process.argv.slice(2);
const { anchor, add } = JSON.parse(fs.readFileSync(changeFile, "utf8"));
let src = fs.readFileSync(file, "utf8");
if (src.includes("post@kbbmedic.com")) {
  console.log(`✓ ${file} already has the footer`);
} else if (src.includes(anchor)) {
  fs.writeFileSync(file, src.replace(anchor, anchor + add));
  console.log(`✓ ${file} (copyright and e-mail at the bottom)`);
} else {
  console.error(`✗ ${file}: the store links weren't found – run store-links.sh first.`);
  process.exit(1);
}
NODE_END
