#!/usr/bin/env bash
# apply-note-marker.sh
# Shows a note symbol (bottom right) on calendar days that have a written note,
# only when the patient shares notes (patient.shareNotes), same rule as the day details.
# Run from the repo root:  bash apply-note-marker.sh
set -euo pipefail
[ -f src/components/headache/HeadacheCalendar.js ] || { echo "Run this from the HeadacheCalendar repo root"; exit 1; }

node - <<'__PATCH__'
const fs = require("fs");
function patch(p, pairs, marker) {
  let s = fs.readFileSync(p, "utf8");
  if (s.includes(marker)) return console.log(`= ${p} (already done)`);
  for (const [a, b] of pairs) {
    if (!s.includes(a)) throw new Error(`${p}: could not find\n${a}`);
    s = s.replace(a, b);
  }
  fs.writeFileSync(p, s);
  console.log(`→ ${p}`);
}

patch("src/components/headache/data.js", [
  ['  cluster: "#6b2fb3",\n};', '  cluster: "#6b2fb3",\n  note: "#4f7cc0",\n};'],
  ["export const hasAcute = (r) =>",
   '// A written note on the day (only shown when the patient shares notes)\nexport const hasNote = (r) => typeof r?.note === "string" && r.note.trim() !== "";\n\nexport const hasAcute = (r) =>'],
], "export const hasNote");

patch("src/components/headache/icons.js", [
  ["// Lightning in a yellow ring – aura", `// Note sheet with lines in a blue ring – the day has a written note
export function NoteIcon({ size = 20 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="12" r="11" fill="#fff" stroke={COLORS.note} strokeWidth="1.6" />
      <path d="M8 5.8h5.6l2.6 2.6v9.8H8z" fill={COLORS.note} />
      <path d="M13.6 5.8v2.6h2.6" fill="#cfe0f7" />
      <path d="M9.8 11.3h4.6M9.8 13.6h4.6M9.8 15.9h3" stroke="#fff" strokeWidth="1.2" strokeLinecap="round" />
    </svg>
  );
}

// Lightning in a yellow ring – aura`],
], "export function NoteIcon");

patch("src/components/headache/HeadacheCalendar.js", [
  ["  hasAcute,\n", "  hasAcute,\n  hasNote,\n"],
  ["import { AcuteIcon, AuraIcon, ChevronIcon, ClusterIcon } from", "import { AcuteIcon, AuraIcon, ChevronIcon, ClusterIcon, NoteIcon } from"],
  ["  selected,\n  onSelect,\n}) {", "  selected,\n  onSelect,\n  showNotes = false,\n}) {"],
  ["            const isSelected = key === selected;\n", "            const isSelected = key === selected;\n            const note = showNotes && hasNote(r);\n"],
  ["              r?.isMigraine && t.CAL_MIGRAINE,\n", "              r?.isMigraine && t.CAL_MIGRAINE,\n              note && t.CAL_NOTE,\n"],
  [`                    )}
                  </span>
                )}
              </div>`, `                    )}
                  </span>
                )}

                {/* Written note – bottom right */}
                {note && (
                  <span className="pointer-events-none absolute -bottom-1 -end-1">
                    <NoteIcon size={12} />
                  </span>
                )}
              </div>`],
], "NoteIcon size={12}");

patch("src/components/headache/CalendarCard.js", [
  ["        onSelect={(key) => setSelected((cur) => (cur === key ? null : key))}\n      />",
   "        onSelect={(key) => setSelected((cur) => (cur === key ? null : key))}\n        showNotes={!!patient?.shareNotes}\n      />"],
], "showNotes=");
__PATCH__

echo "✓ Done. Start with: npm run dev"
