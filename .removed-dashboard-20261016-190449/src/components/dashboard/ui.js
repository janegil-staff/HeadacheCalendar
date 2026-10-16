// src/components/dashboard/ui.js
"use client";

import { useState } from "react";

export const CARD = "rounded-3xl border border-white/70 bg-white/90 shadow-[0_10px_30px_-18px_rgba(30,58,110,0.45)] backdrop-blur";

export function Card({ className = "", children }) {
  return <section className={`${CARD} ${className}`}>{children}</section>;
}

export function CountBadge({ value, tone = "blue" }) {
  const tones = {
    blue: "bg-blue-700 text-white",
    amber: "bg-amber-400 text-white",
  };
  return (
    <span className={`inline-flex h-6 min-w-6 items-center justify-center rounded-full px-1.5 text-xs font-bold ${tones[tone]}`}>
      {value}
    </span>
  );
}

function Chevron({ open }) {
  return (
    <svg
      className={`h-4 w-4 shrink-0 text-slate-600 transition-transform ${open ? "rotate-180" : ""}`}
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden="true"
    >
      <path d="M6 9h12l-6 7z" />
    </svg>
  );
}

// Card with an uppercase header that opens and closes
export function Collapsible({ title, count, defaultOpen = false, children }) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <Card>
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-expanded={open}
        className="flex w-full items-center justify-between gap-3 px-5 py-4 text-start"
      >
        <span className="text-sm font-bold uppercase tracking-[0.14em] text-blue-900">{title}</span>
        <span className="flex items-center gap-2">
          {count !== undefined && <CountBadge value={count} />}
          <Chevron open={open} />
        </span>
      </button>
      {open && <div className="border-t border-slate-100 px-5 pb-5 pt-3">{children}</div>}
    </Card>
  );
}

// Label / value row in the uppercase style of kolskalender
export function StatusRow({ label, value, tone = "default" }) {
  const tones = {
    default: "text-slate-700",
    good: "text-emerald-600",
    warn: "text-amber-600",
    bad: "text-red-600",
  };
  return (
    <div className="flex items-baseline justify-between gap-4 border-b border-slate-100 py-2.5 last:border-0">
      <span className="text-xs font-semibold uppercase tracking-[0.1em] text-slate-500">{label}</span>
      <span className={`text-end text-sm font-semibold ${tones[tone]}`}>{value}</span>
    </div>
  );
}
