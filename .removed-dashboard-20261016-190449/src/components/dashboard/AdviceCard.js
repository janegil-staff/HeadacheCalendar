// src/components/dashboard/AdviceCard.js
"use client";

import { useState } from "react";
import { useLocale } from "@/components/LocaleProvider";
import { fill } from "@/lib/headache";
import { Card, CountBadge } from "@/components/dashboard/ui";

export default function AdviceCard({ topics }) {
  const { t } = useLocale();
  const [open, setOpen] = useState(false);

  return (
    <Card className="px-6 py-5">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-expanded={open}
        className="relative w-full text-center"
      >
        <span className="font-serif text-2xl font-bold text-blue-900">{t.DASH_ADVICE_TITLE}</span>
        <span className="absolute end-0 top-1 flex items-center gap-2">
          {topics.length > 0 && <CountBadge value={topics.length} tone="amber" />}
          <svg className={`h-4 w-4 text-slate-600 transition-transform ${open ? "rotate-180" : ""}`} viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M6 9h12l-6 7z" />
          </svg>
        </span>
        <span className="mt-1 block text-sm text-slate-500">{t.DASH_ADVICE_SUBTITLE}</span>
      </button>

      {open && (
        <div className="mt-4 border-t border-slate-100 pt-3">
          {topics.length === 0 ? (
            <p className="text-sm text-slate-500">{t.DASH_ADVICE_NONE}</p>
          ) : (
            <ul className="space-y-3">
              {topics.map((topic) => (
                <li key={topic.id} className="rounded-xl border-s-4 border-amber-400 bg-amber-50/70 px-4 py-3">
                  <p className="font-semibold text-slate-800">{t[topic.titleKey]}</p>
                  <p className="mt-0.5 text-sm leading-relaxed text-slate-600">
                    {fill(t[topic.textKey], topic.values)}
                    {topic.extraKey ? ` ${t[topic.extraKey]}` : ""}
                  </p>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </Card>
  );
}
