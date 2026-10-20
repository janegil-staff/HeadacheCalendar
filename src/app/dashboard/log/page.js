// src/app/dashboard/log/page.js
"use client";

import DashboardHeader from "@/components/headache/DashboardHeader";
import HeadacheLog from "@/components/headache/HeadacheLog";
import { usePatient } from "@/components/headache/usePatient";
import { useHeadacheText } from "@/components/headache/useHeadacheText";

export default function LogPage() {
  const { patient, close } = usePatient();
  const { locale, dir } = useHeadacheText();

  if (!patient) return null;

  return (
    <div dir={dir} lang={locale} className="min-h-screen pb-12">
      <DashboardHeader patient={patient} onClose={close} />
      <main className="mx-auto mt-6 max-w-4xl px-4">
        <HeadacheLog patient={patient} />
      </main>
    </div>
  );
}
