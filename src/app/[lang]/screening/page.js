// src/app/[lang]/screening/page.js
//
// Screening entry – the FULL dashboard from a link:
//   http://localhost:3000/no/screening?code=123456
//
// The URL stays as it is: the patient is put in sessionStorage the way the code card
// on the landing page does it, and the dashboard is rendered in place. A reload of the
// same link opens the same patient again without spending a new code.
//
// Trade-off: the code stays in the URL (history, server logs). Fine for a code that
// is single-use and dies within seconds.
"use client";

import DashboardPage from "@/app/dashboard/page";
import CodeLinkStatus from "@/components/headache/CodeLinkStatus";
import { useCodeLink } from "@/components/headache/useCodeLink";
import { useUrlLanguage } from "@/components/headache/useUrlLanguage";

const seedDashboard = (patient) => {
  try {
    sessionStorage.setItem("patient", JSON.stringify(patient));
  } catch {}
};

export default function ScreeningPage() {
  useUrlLanguage();
  const link = useCodeLink("screening", seedDashboard);

  if (link.status !== "ready") return <CodeLinkStatus errorKey={link.errorKey} />;
  return <DashboardPage />;
}
