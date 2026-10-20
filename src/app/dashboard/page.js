// src/app/dashboard/page.js
"use client";

import CalendarCard from "@/components/headache/CalendarCard";
import SummaryCard from "@/components/headache/SummaryCard";
import DashboardHeader from "@/components/headache/DashboardHeader";
import { usePatient } from "@/components/headache/usePatient";
import { useHeadacheText } from "@/components/headache/useHeadacheText";

export default function DashboardPage() {
  const { patient, close } = usePatient();
  const { locale, dir } = useHeadacheText();

  if (!patient) return null;

  return (
    <div dir={dir} lang={locale} className="min-h-screen pb-12">
      <DashboardHeader patient={patient} onClose={close} />

      {/* Calendar on the left, sidebar on the right (stacked on small screens) */}
      <main className="mx-auto mt-6 grid max-w-md gap-6 px-4 lg:max-w-[62rem] lg:grid-cols-2 lg:items-start">
        <CalendarCard patient={patient} />
        <aside className="space-y-6">
          <SummaryCard patient={patient} />
        </aside>
      </main>
    </div>
  );
}
