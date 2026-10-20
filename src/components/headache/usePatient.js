// src/components/headache/usePatient.js
"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";

// The patient opened with the one-time code (kept in sessionStorage), shared by the dashboard pages
export function usePatient() {
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

  const close = useCallback(() => {
    try {
      sessionStorage.removeItem("patient");
    } catch {}
    router.replace("/"); // replace: Back shouldn't return to a closed patient
  }, [router]);

  return { patient, close };
}
