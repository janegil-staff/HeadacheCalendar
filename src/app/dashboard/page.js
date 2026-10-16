// src/app/dashboard/page.js
"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

export default function DashboardPage() {
  const router = useRouter();
  const [patient, setPatient] = useState(null);

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

  const close = () => {
    try {
      sessionStorage.removeItem("patient");
    } catch {}
    router.replace("/"); // replace: Back shouldn't return to a closed patient
  };

  if (!patient) return null;

  return (
    <main className="min-h-screen bg-gray-50 px-4 py-8">
      <div className="mx-auto max-w-5xl">
        <div className="mb-6 flex items-center justify-between">
          <h1 className="font-serif text-3xl font-bold text-blue-800">Dashboard</h1>
          <button
            type="button"
            onClick={close}
            className="rounded-lg border border-blue-700 px-4 py-2 text-sm font-semibold text-blue-700 hover:bg-blue-50"
          >
            Lukk pasient
          </button>
        </div>

        {/* Temporary raw view until the response shape is known */}
        <pre className="overflow-x-auto rounded-2xl bg-white p-6 text-sm text-gray-800 shadow-sm">
          {JSON.stringify(patient, null, 2)}
        </pre>
      </div>
    </main>
  );
}
