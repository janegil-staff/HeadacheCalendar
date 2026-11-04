#!/usr/bin/env bash
# move-compare-button.sh
# Moves "Compare before and after a reference date" from a link under the summary table
# to a full-width button under "Show cluster headache", above Show log (same style as Show log / HIT-6).
# It opens the same ReferenceModal as before.
# Run from the project root:  bash move-compare-button.sh
set -euo pipefail
F=src/components/headache/SummaryCard.js
[ -f "$F" ] || { echo "✗ $F not found – run this from the project root." >&2; exit 1; }
if grep -q "Before / after a reference date – opens ReferenceModal" "$F"; then
  echo "✓ Already applied."; exit 0
fi
git apply --whitespace=nowarn <<'PATCH_END'
diff --git a/src/components/headache/SummaryCard.js b/src/components/headache/SummaryCard.js
index b8edaa1..74559f7 100644
--- a/src/components/headache/SummaryCard.js
+++ b/src/components/headache/SummaryCard.js
@@ -406,19 +406,7 @@ export default function SummaryCard({ patient }) {
         )}
       </div>
 
-      {/* Link-style button: before / after a reference date, in a modal */}
-      <div className="mt-2 text-center">
-        <button
-          type="button"
-          onClick={() => setRefOpen(true)}
-          aria-haspopup="dialog"
-          className="rounded text-sm font-semibold text-[#4f7cc0] underline decoration-[#6a9be0]/40 underline-offset-4 transition hover:text-[#3d68a8] hover:decoration-[#4f7cc0] focus:outline-none focus:ring-2 focus:ring-[#6a9be0]/40"
-        >
-          {t.REF_OPEN}
-        </button>
-      </div>
-
-      <div className="mt-3 border-t border-slate-200/80 pt-3">
+      <div className="mt-4 border-t border-slate-200/80 pt-3">
         <PeriodSwitch value={period} onChange={(v) => setOption("period", v)} t={t} />
         <Checkbox checked={options.textView} onChange={(v) => setOption("textView", v)}>
           {t.SUM_TEXT_VIEW}
@@ -433,6 +421,19 @@ export default function SummaryCard({ patient }) {
           {t.SUM_SHOW_CLUSTER}
         </Checkbox>
       </div>
+      {/* Before / after a reference date – opens ReferenceModal, same look as Show log / HIT-6 */}
+      <button
+        type="button"
+        onClick={() => setRefOpen(true)}
+        aria-haspopup="dialog"
+        className="mt-4 flex w-full items-center gap-3 rounded-2xl border border-slate-200/80 bg-white px-4 py-3 text-start shadow-[0_6px_18px_-8px_rgba(60,100,160,0.45)] transition hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-[#6a9be0]/40"
+      >
+        <span className="flex-1 text-xs font-bold uppercase tracking-[0.14em] text-[#4f7cc0]">{t.REF_OPEN}</span>
+        <svg className="h-3.5 w-3.5 text-[#6a9be0] rtl:-scale-x-100" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
+          <path d="M8 5v14l9-7z" />
+        </svg>
+      </button>
+
       {/* Opens the log in a modal – same look as the Medication / Previously used medication panels */}
       <button
         type="button"
PATCH_END
echo "✓ Compare button moved under 'Show cluster headache' in $F"
