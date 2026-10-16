// src/components/dashboard/StatusCard.js
"use client";

import { useLocale } from "@/components/LocaleProvider";
import { fill, formatUnit, intlLocale, lastRegistration, latestHit6 } from "@/lib/headache";
import { Card, StatusRow } from "@/components/dashboard/ui";

const PERIOD = 30;

export default function StatusCard({ patient, last30 }) {
  const { t, locale } = useLocale();
  const days = (n) => formatUnit(locale, n, "day");
  const dateFmt = new Intl.DateTimeFormat(intlLocale(locale), { day: "numeric", month: "short", year: "numeric" });
  const fmtDate = (key) => {
    if (!key) return "–";
    const [y, m, d] = String(key).slice(0, 10).split("-").map(Number);
    return dateFmt.format(new Date(y, m - 1, d));
  };

  // ≥15 headache days/month = chronic range, ≥4 = frequent
  const headacheTone = last30.headacheDays >= 15 ? "bad" : last30.headacheDays >= 4 ? "warn" : "good";
  // ≥10 days with acute medication/month = risk of medication-overuse headache
  const acuteTone = last30.acuteDays >= 10 ? "bad" : last30.acuteDays >= 6 ? "warn" : "good";

  const preventive = (patient.preventiveMedicines ?? []).map((m) => m?.name ?? String(m)).filter(Boolean);
  const hit6 = latestHit6(patient);
  // HIT-6: 36–78, ≥60 = severe impact, 56–59 = substantial
  const hitTone = !hit6 ? "default" : hit6.score >= 60 ? "bad" : hit6.score >= 56 ? "warn" : "good";

  const pct = Math.round((last30.registered / PERIOD) * 100);
  const pctTone = pct >= 80 ? "good" : pct >= 50 ? "warn" : "bad";

  return (
    <Card className="p-6">
      <h2 className="text-center font-serif text-2xl font-bold text-blue-900">{t.DASH_STATUS_TITLE}</h2>
      <p className="mb-3 text-center text-xs text-slate-500">{t.DASH_LAST_30}</p>

      <StatusRow label={t.DASH_HEADACHE_DAYS} value={days(last30.headacheDays)} tone={headacheTone} />
      <StatusRow label={t.DASH_MIGRAINE_DAYS} value={days(last30.migraineDays)} tone={last30.migraineDays ? "warn" : "good"} />
      <StatusRow label={t.DASH_ACUTE_DAYS} value={days(last30.acuteDays)} tone={acuteTone} />
      <StatusRow
        label={t.CAL_PREVENTIVE}
        value={preventive.length ? preventive.join(", ") : t.DASH_NONE}
        tone={preventive.length ? "default" : "warn"}
      />
      <StatusRow
        label="HIT-6"
        value={hit6 ? `${hit6.score}${hit6.date ? ` · ${fmtDate(hit6.date)}` : ""}` : t.DASH_NOT_COMPLETED}
        tone={hitTone}
      />
      <StatusRow label={t.DASH_LAST_REGISTRATION} value={fmtDate(lastRegistration(patient.records))} />

      <div className="pt-3">
        <div className="flex items-baseline justify-between gap-4">
          <span className="text-xs font-semibold uppercase tracking-[0.1em] text-slate-500">{t.DASH_COMPLETED_IN_APP}</span>
          <span
            className={`text-sm font-semibold ${
              { good: "text-emerald-600", warn: "text-amber-600", bad: "text-red-600" }[pctTone]
            }`}
          >
            {pct}%
          </span>
        </div>
        <div className="mt-2 h-2 overflow-hidden rounded-full bg-slate-100" role="progressbar" aria-valuenow={pct} aria-valuemin={0} aria-valuemax={100}>
          <div
            className={`h-full rounded-full ${{ good: "bg-emerald-500", warn: "bg-amber-400", bad: "bg-red-500" }[pctTone]}`}
            style={{ width: `${Math.min(pct, 100)}%` }}
          />
        </div>
        <p className="mt-1.5 text-xs text-slate-500">{fill(t.DASH_DAYS_OF, { n: last30.registered, total: PERIOD })}</p>
      </div>
    </Card>
  );
}
