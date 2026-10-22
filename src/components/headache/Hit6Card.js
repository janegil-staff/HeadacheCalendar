// src/components/headache/Hit6Card.js
"use client";

import { useMemo, useState } from "react";
import { useLocale } from "@/components/LocaleProvider";

// HIT-6 answers are stored 1–5 (Never … Always); the standard points per answer
const POINTS = [6, 8, 10, 11, 13];

// Standard HIT-6 impact bands (score 36–78)
const BANDS = [
  { max: 49, key: "HIT6_IMPACT_LITTLE", color: "#22a565", bg: "#e8f7ef" },
  { max: 55, key: "HIT6_IMPACT_SOME", color: "#b58900", bg: "#fdf6dc" },
  { max: 59, key: "HIT6_IMPACT_SUBSTANTIAL", color: "#e07b16", bg: "#fdeedd" },
  { max: Infinity, key: "HIT6_IMPACT_SEVERE", color: "#d93d3d", bg: "#fde8e8" },
];
const bandOf = (score) => BANDS.find((b) => score <= b.max);

// Newest first; empty tests (no score, score 0, no answers) are left out.
// The score is calculated from the answers if it's missing
function hit6Tests(patient) {
  const list = Array.isArray(patient?.hitSix) ? patient.hitSix : [];
  return list
    .map((e) => {
      const answers = Array.isArray(e?.answers) ? e.answers.map(Number) : [];
      const fromAnswers =
        answers.length === 6 && answers.every((a) => a >= 1 && a <= 5)
          ? answers.reduce((sum, a) => sum + POINTS[a - 1], 0)
          : null;
      // 0, null or a missing score counts as empty – use the answers if they are filled in
      const score = typeof e?.score === "number" && e.score > 0 ? e.score : fromAnswers;
      return { date: e?.date ?? null, score, answers };
    })
    .filter((e) => typeof e.score === "number" && e.score > 0)
    .sort((a, b) => String(b.date ?? "").localeCompare(String(a.date ?? "")));
}

function formatDate(locale, key) {
  if (!key) return "";
  const [y, m, d] = String(key).slice(0, 10).split("-").map(Number);
  if (!y || !m || !d) return String(key);
  try {
    return new Intl.DateTimeFormat(locale, { day: "numeric", month: "short", year: "numeric" }).format(new Date(y, m - 1, d));
  } catch {
    return String(key).slice(0, 10);
  }
}

function ScoreBadge({ score, large = false }) {
  const band = bandOf(score);
  return (
    <span
      className={`inline-flex items-center justify-center rounded-full font-bold tabular-nums text-white ${
        large ? "h-12 min-w-12 px-2 text-xl" : "h-6 min-w-8 px-2 text-xs"
      }`}
      style={{ backgroundColor: band.color }}
    >
      {score}
    </span>
  );
}

// "HIT-6" panel at the bottom of the summary card, under "Show log" (same look as that button): latest score with impact level, the six answers,
// the app's note when the score is 50 or higher, and earlier tests.
// Not shown at all when the patient has no HIT-6 (or only empty ones with score 0).
export default function Hit6Card({ patient }) {
  const { t, locale } = useLocale();
  const [open, setOpen] = useState(false);
  const tests = useMemo(() => hit6Tests(patient), [patient]);
  const latest = tests[0];
  const earlier = tests.slice(1);
  const band = latest ? bandOf(latest.score) : null;

  // No HIT-6, or only empty ones: don't show the panel at all
  if (!latest) return null;

  return (
    <section className="mt-3 overflow-hidden rounded-2xl border border-slate-200/80 bg-white shadow-[0_6px_18px_-8px_rgba(60,100,160,0.45)]">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-expanded={open}
        className="flex w-full items-center gap-3 px-4 py-3 text-start transition hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-[#6a9be0]/40"
      >
        <span className="flex-1 text-xs font-bold uppercase tracking-[0.14em] text-[#4f7cc0]">{t.HIT_6 ?? "HIT-6"}</span>
        <ScoreBadge score={latest.score} />
        <svg
          className={`h-3.5 w-3.5 text-[#6a9be0] transition-transform ${open ? "rotate-180" : ""}`}
          viewBox="0 0 24 24"
          fill="currentColor"
          aria-hidden="true"
        >
          <path d="M5 8h14l-7 9z" />
        </svg>
      </button>

      {open && (
        <div className="border-t border-slate-100 p-4">
          {(
            <div className="space-y-4">
              {/* Latest score */}
              <div className="flex items-center gap-4 rounded-xl p-3" style={{ backgroundColor: band.bg }}>
                <ScoreBadge score={latest.score} large />
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-bold" style={{ color: band.color }}>
                    {t[band.key]}
                  </p>
                  <p className="text-xs text-slate-500">
                    {[formatDate(locale, latest.date), `${t.HIT_6_TOTAL_SCORE ?? "Total"} ${latest.score} / 78`]
                      .filter(Boolean)
                      .join(" · ")}
                  </p>
                </div>
              </div>

              {/* The six answers */}
              {latest.answers.length === 6 && (
                <ul className="divide-y divide-slate-100 overflow-hidden rounded-xl border border-slate-200/80">
                  {latest.answers.map((a, i) => (
                    <li key={i} className="flex items-center gap-3 px-4 py-2.5 text-sm" title={t[`HIT_6_QUESTION_${i + 1}`]}>
                      <span className="min-w-0 flex-1 text-slate-700">{t[`HIT_6_QUESTION_${i + 1}_SHORT`]}</span>
                      <span className="shrink-0 font-semibold text-slate-800">{t[`HIT_6_ANSWER_${a}`] ?? a}</span>
                      <span className="w-6 shrink-0 text-end text-xs tabular-nums text-slate-400">{POINTS[a - 1] ?? ""}</span>
                    </li>
                  ))}
                </ul>
              )}

              {/* The app's own note for 50 or higher */}
              {latest.score >= 50 && t.HIT_6_HIGH_SCORE && (
                <p
                  className="rounded-xl px-4 py-3 text-sm leading-relaxed"
                  style={{ backgroundColor: band.bg, color: "#4b3a14" }}
                >
                  {t.HIT_6_HIGH_SCORE}
                </p>
              )}

              {/* Earlier tests */}
              {earlier.length > 0 && (
                <div>
                  <p className="mb-2 px-1 text-[11px] font-semibold uppercase tracking-[0.1em] text-slate-500">{t.HIT6_EARLIER}</p>
                  <ul className="divide-y divide-slate-100 overflow-hidden rounded-xl border border-slate-200/80">
                    {earlier.map((e, i) => (
                      <li key={`${e.date}-${i}`} className="flex items-center gap-3 px-4 py-2 text-sm">
                        <span className="flex-1 text-slate-700">{formatDate(locale, e.date)}</span>
                        <span className="text-xs" style={{ color: bandOf(e.score).color }}>
                          {t[bandOf(e.score).key]}
                        </span>
                        <ScoreBadge score={e.score} />
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </section>
  );
}
