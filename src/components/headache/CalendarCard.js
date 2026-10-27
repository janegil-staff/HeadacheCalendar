// src/components/headache/CalendarCard.js
"use client";

import { useMemo, useState } from "react";
import HeadacheCalendar from "@/components/headache/HeadacheCalendar";
import DayDetails from "@/components/headache/DayDetails";
import MonthlySummary from "@/components/headache/MonthlySummary";
import { MedicationDropdown, PreviousMedicationDropdown } from "@/components/headache/MedicationLists";
import { firstRecordMonth, indexRecords } from "@/components/headache/data";

// The calendar card: month navigation, day details, monthly summary and the medication dropdowns
export default function CalendarCard({ patient }) {
  const now = new Date();
  const [view, setView] = useState({ year: now.getFullYear(), month: now.getMonth() });
  const [selected, setSelected] = useState(null);

  const byDate = useMemo(() => indexRecords(patient?.records), [patient]);
  const first = useMemo(() => firstRecordMonth(patient?.records), [patient]);

  const idx = (v) => v.year * 12 + v.month;
  const current = { year: now.getFullYear(), month: now.getMonth() };
  const move = (delta) => {
    setView((v) => {
      const n = idx(v) + delta;
      return { year: Math.floor(n / 12), month: n % 12 };
    });
    setSelected(null);
  };

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
        selected={selected}
        onSelect={(key) => setSelected((cur) => (cur === key ? null : key))}
        showNotes={!!patient?.shareNotes}
      />
      <DayDetails
        patient={patient}
        dateKey={selected}
        record={selected ? byDate.get(selected) : null}
        onClose={() => setSelected(null)}
      />

      {/* Monthly summary as a card inside the calendar card, following the month shown */}
      <MonthlySummary patient={patient} byDate={byDate} year={view.year} month={view.month} />

      {/* Medication and previously used medication, as dropdowns */}
      <MedicationDropdown patient={patient} />
      <PreviousMedicationDropdown patient={patient} />
    </section>
  );
}
