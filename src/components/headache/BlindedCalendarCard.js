// src/components/headache/BlindedCalendarCard.js
"use client";

import { useMemo, useState } from "react";
import HeadacheCalendar from "@/components/headache/HeadacheCalendar";
import { firstRecordMonth, indexRecords } from "@/components/headache/data";

// Calendar only, read-only: month navigation and the blinded grid.
// No day details, monthly summary or medication lists – they would show what the
// blinded grid hides.
export default function BlindedCalendarCard({ patient }) {
  const now = new Date();
  const [view, setView] = useState({ year: now.getFullYear(), month: now.getMonth() });

  const byDate = useMemo(() => indexRecords(patient?.records), [patient]);
  const first = useMemo(() => firstRecordMonth(patient?.records), [patient]);

  const idx = (v) => v.year * 12 + v.month;
  const current = { year: now.getFullYear(), month: now.getMonth() };
  const move = (delta) =>
    setView((v) => {
      const n = idx(v) + delta;
      return { year: Math.floor(n / 12), month: n % 12 };
    });

  return (
    <section className="rounded-3xl border border-white/70 bg-white/65 p-4 shadow-[0_10px_30px_-18px_rgba(60,100,160,0.35)] backdrop-blur sm:px-5 sm:py-5">
      <HeadacheCalendar
        byDate={byDate}
        year={view.year}
        month={view.month}
        canPrev={first ? idx(view) > idx(first) : false}
        canNext={idx(view) < idx(current)}
        onPrev={() => move(-1)}
        onNext={() => move(1)}
        blinded
      />
    </section>
  );
}
