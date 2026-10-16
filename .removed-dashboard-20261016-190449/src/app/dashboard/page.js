// src/app/dashboard/page.js
"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import Background from "@/components/landing/Background";
import LanguagePicker from "@/components/landing/LanguagePicker";
import DashboardHeader from "@/components/dashboard/DashboardHeader";
import HeadacheCalendar from "@/components/dashboard/HeadacheCalendar";
import CalendarLegend from "@/components/dashboard/CalendarLegend";
import DayDetails from "@/components/dashboard/DayDetails";
import MonthSummary from "@/components/dashboard/MonthSummary";
import { MedicationPanel, PreviousMedicationPanel } from "@/components/dashboard/MedicationPanels";
import AppDataPanel from "@/components/dashboard/AppDataPanel";
import StatusCard from "@/components/dashboard/StatusCard";
import AdviceCard from "@/components/dashboard/AdviceCard";
import { Card } from "@/components/dashboard/ui";
import {
  adviceTopics,
  firstRecordMonth,
  indexRecords,
  monthScore,
  monthStats,
  monthlyOverview,
  periodSummary,
  recordsInLastDays,
} from "@/lib/headache";

export default function DashboardPage() {
  const router = useRouter();
  const [patient, setPatient] = useState(null);

  const now = new Date();
  const [view, setView] = useState({ year: now.getFullYear(), month: now.getMonth() });
  const [selected, setSelected] = useState(null);

  useEffect(() => {
    let stored = null;
    try {
      stored = JSON.parse(sessionStorage.getItem("patient"));
    } catch {}
    if (!stored) {
      router.replace("/"); // no valid code used → back to landing
      return;
    }
    setPatient(stored);
  }, [router]);

  const byDate = useMemo(() => indexRecords(patient?.records), [patient]);
  const first = useMemo(() => firstRecordMonth(patient?.records), [patient]);
  const last30 = useMemo(() => periodSummary(recordsInLastDays(byDate, 30)), [byDate]);
  const topics = useMemo(() => (patient ? adviceTopics(patient, byDate) : []), [patient, byDate]);
  const months = useMemo(() => (patient ? monthlyOverview(patient, byDate, 12) : []), [patient, byDate]);
  const stats = useMemo(() => monthStats(byDate, view.year, view.month), [byDate, view]);

  const idx = (v) => v.year * 12 + v.month;
  const current = { year: now.getFullYear(), month: now.getMonth() };
  const canPrev = first ? idx(view) > idx(first) : false;
  const canNext = idx(view) < idx(current);
  const move = (delta) => {
    setView((v) => {
      const n = idx(v) + delta;
      return { year: Math.floor(n / 12), month: n % 12 };
    });
    setSelected(null);
  };

  const close = () => {
    try {
      sessionStorage.removeItem("patient");
    } catch {}
    router.replace("/"); // replace: Back shouldn't return to a closed patient
  };

  if (!patient) return null;

  return (
    <div className="relative isolate min-h-screen overflow-hidden pb-12">
      <Background />
      <DashboardHeader patient={patient} onClose={close} />

      <div className="mx-auto mt-4 flex max-w-6xl justify-end px-4 md:hidden">
        <LanguagePicker />
      </div>

      <main className="mx-auto mt-6 grid max-w-6xl grid-cols-[minmax(0,1fr)] items-start gap-6 px-4 sm:px-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
        {/* Left: calendar and the patient's registrations */}
        <div className="flex min-w-0 flex-col gap-5">
          <Card className="p-4 sm:p-6">
            <HeadacheCalendar
              byDate={byDate}
              year={view.year}
              month={view.month}
              canPrev={canPrev}
              canNext={canNext}
              onPrev={() => move(-1)}
              onNext={() => move(1)}
              selected={selected}
              onSelect={(key) => setSelected((cur) => (cur === key ? null : key))}
            />
            <DayDetails
              patient={patient}
              dateKey={selected}
              record={selected ? byDate.get(selected) : null}
              onClose={() => setSelected(null)}
            />
            <CalendarLegend />
          </Card>

          <MonthSummary stats={stats} score={monthScore(patient, view.year, view.month)} year={view.year} month={view.month} />
          <MedicationPanel patient={patient} />
          <PreviousMedicationPanel patient={patient} />
          <AppDataPanel months={months} />
        </div>

        {/* Right: sidebar */}
        <aside className="order-first flex min-w-0 flex-col gap-5 lg:order-none lg:sticky lg:top-24">
          <StatusCard patient={patient} last30={last30} />
          <AdviceCard topics={topics} />
        </aside>
      </main>
    </div>
  );
}
