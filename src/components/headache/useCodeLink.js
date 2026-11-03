// src/components/headache/useCodeLink.js
"use client";

import { useEffect, useState } from "react";

// One request per code for the lifetime of the page. The code is single-use and dies
// after a few seconds, so React's dev double-mount must not fire a second request.
const requests = new Map();

function fetchPatient(code) {
  if (!requests.has(code)) {
    requests.set(
      code,
      fetch("/api/patient-access", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code }),
      })
        .then(async (res) => {
          const data = await res.json().catch(() => ({}));
          if (res.ok && data.patient) return { patient: data.patient };
          return { errorKey: res.status === 410 ? "PATIENT_CODE_EXPIRED" : "PATIENT_CODE_INVALID" };
        })
        .catch(() => ({ errorKey: "ERROR_NETWORK" }))
    );
  }
  return requests.get(code);
}

// Opens a patient from a link like /no/screening?code=123456.
// The result is kept in sessionStorage under `storageKey` together with the code,
// so a reload of the same link shows the same patient without spending a new code.
// `onLoaded(patient)` runs before the page renders the patient.
export function useCodeLink(storageKey, onLoaded) {
  const [state, setState] = useState({ status: "loading" });

  useEffect(() => {
    const code = (new URLSearchParams(window.location.search).get("code") || "").trim();
    if (!/^\d{6}$/.test(code)) {
      setState({ status: "error", errorKey: "PATIENT_CODE_INVALID" });
      return;
    }

    const ready = (patient) => {
      onLoaded?.(patient);
      setState({ status: "ready", patient });
    };

    try {
      const saved = JSON.parse(sessionStorage.getItem(storageKey));
      if (saved?.code === code && saved.patient) {
        ready(saved.patient);
        return;
      }
    } catch {}

    let active = true;
    fetchPatient(code).then((result) => {
      if (!active) return;
      if (!result.patient) {
        setState({ status: "error", errorKey: result.errorKey });
        return;
      }
      try {
        sessionStorage.setItem(storageKey, JSON.stringify({ code, patient: result.patient }));
      } catch {}
      ready(result.patient);
    });
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [storageKey]);

  return state;
}
