#!/usr/bin/env bash
# lighter-period-frame.sh – much lighter, thinner pink frame around menstruation days
# Run from the root of the HeadacheCalendar repo:  bash lighter-period-frame.sh
set -euo pipefail
[ -f src/components/headache/data.js ] || { echo "Run this from the HeadacheCalendar repo root"; exit 1; }
node - <<'JS'
const fs = require("fs");
const edit = (p, from, to) => {
  const s = fs.readFileSync(p, "utf8");
  if (s.includes(to)) return console.log(`  already done: ${p}`);
  if (!s.includes(from)) throw new Error(`Could not find the text to change in ${p}`);
  fs.writeFileSync(p, s.replace(from, to));
  console.log(`  updated ${p}`);
};

// Light pink instead of the strong #d63384 (also used by the menstruation icon in the summary)
edit(
  "src/components/headache/data.js",
  'periodStrong: "#d63384", // thick frame around menstruation days in the calendar',
  'periodStrong: "#f6b8d1", // light pink frame around menstruation days in the calendar'
);

// Thinner: 2 px of pink inside the cell, and no extra ring outside it
edit(
  "src/components/headache/HeadacheCalendar.js",
  `                    backgroundColor: r?.hasPeriod ? COLORS.periodStrong : "#fff",
                    boxShadow: migraine
                      ? \`0 0 0 1.5px \${MIGRAINE_FRAME}\`
                      : \`0 0 0 1px \${COLORS.periodStrong}\`,
                  }`,
  `                    backgroundColor: r?.hasPeriod ? COLORS.periodStrong : "#fff",
                    padding: r?.hasPeriod ? 2 : undefined, // a thinner pink band than the 3 px default
                    boxShadow: migraine ? \`0 0 0 1.5px \${MIGRAINE_FRAME}\` : undefined,
                  }`
);
JS
echo "Done."
