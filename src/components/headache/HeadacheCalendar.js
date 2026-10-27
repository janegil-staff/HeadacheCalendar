// src/components/headache/HeadacheCalendar.js
"use client";

import { useMemo } from "react";
import { useHeadacheText } from "@/components/headache/useHeadacheText";
import {
  COLORS,
  INTENSITY,
  hasAcute,
  hasNote,
  intensityOf,
  intlLocale,
  monthGrid,
  toDateKey,
  todayKey,
} from "@/components/headache/data";
import { AcuteIcon, AuraIcon, ChevronIcon, ClusterIcon, NoteIcon } from "@/components/headache/icons";

const FILL = { 1: COLORS.mild, 2: COLORS.moderate, 3: COLORS.strong, 4: COLORS.extreme };

export default function HeadacheCalendar({
  byDate,
  year,
  month,
  canPrev,
  canNext,
  onPrev,
  onNext,
  selected,
  onSelect,
  showNotes = false,
}) {
  const { t, locale } = useHeadacheText();
  const loc = intlLocale(locale);
  const today = todayKey();
  const cells = monthGrid(year, month);

  const title = useMemo(
    () => new Intl.DateTimeFormat(loc, { month: "long", year: "numeric" }).format(new Date(year, month, 1)),
    [loc, year, month]
  );

  // Monday-first weekday initials in the selected language (2024-01-01 was a Monday)
  const weekdays = useMemo(() => {
    const fmt = new Intl.DateTimeFormat(loc, { weekday: "narrow" });
    return Array.from({ length: 7 }, (_, i) => fmt.format(new Date(2024, 0, 1 + i)));
  }, [loc]);

  const longDate = useMemo(
    () => new Intl.DateTimeFormat(loc, { weekday: "long", day: "numeric", month: "long", year: "numeric" }),
    [loc]
  );

  return (
    <div>
      {/* Month navigation */}
      <div className="mx-auto mb-3 flex max-w-sm items-center justify-between">
        <button
          type="button"
          onClick={onPrev}
          disabled={!canPrev}
          aria-label={t.CAL_PREV_MONTH}
          className="rounded-full p-1.5 text-[#7aa3e2] transition hover:bg-blue-50 disabled:opacity-30 rtl:rotate-180"
        >
          <ChevronIcon dir="left" size={16} />
        </button>
        <h2 className="font-serif text-lg font-bold capitalize text-[#4f7cc0]" aria-live="polite">
          {title}
        </h2>
        <button
          type="button"
          onClick={onNext}
          disabled={!canNext}
          aria-label={t.CAL_NEXT_MONTH}
          className="rounded-full p-1.5 text-[#7aa3e2] transition hover:bg-blue-50 disabled:opacity-30 rtl:rotate-180"
        >
          <ChevronIcon dir="right" size={16} />
        </button>
      </div>

      <div className="mx-auto max-w-sm">
        <div className="grid grid-cols-7 gap-1 pb-1 text-center text-[11px] font-semibold uppercase text-slate-400">
          {weekdays.map((d, i) => (
            <div key={i}>{d}</div>
          ))}
        </div>

        <div className="grid grid-cols-7 gap-1" role="grid">
          {cells.map((day, i) => {
            if (!day) return <div key={i} />;
            const key = toDateKey(year, month, day);
            const r = byDate.get(key);
            const level = r ? intensityOf(r) : null;
            const isToday = key === today;
            const isFuture = key > today;
            const isSelected = key === selected;
            const note = showNotes && hasNote(r);

            let box = "border border-dashed border-slate-200 text-slate-400"; // past, nothing registered
            let style;
            if (r && level > 0) {
              box = "text-white";
              style = { backgroundColor: FILL[level] };
            } else if (r) {
              box = "border border-slate-300 bg-white text-slate-700";
            } else if (isToday) {
              box = "text-white";
              style = { backgroundColor: COLORS.today };
            } else if (isFuture) {
              box = "text-slate-300";
            }

            const label = [
              longDate.format(new Date(year, month, day)),
              r ? t[INTENSITY[level].key] : t.CAL_NO_REGISTRATION,
              r?.hasPeriod && t.CAL_PERIOD,
              r && hasAcute(r) && t.CAL_ACUTE_MEDICATION,
              r?.hasAura && t.CAL_AURA,
              r?.hasClusterHeadache && t.CAL_CLUSTER,
              r?.isMigraine && t.CAL_MIGRAINE,
              note && t.CAL_NOTE,
            ]
              .filter(Boolean)
              .join(", ");

            return (
              <div
                key={i}
                className="relative h-8 rounded-md p-[3px]"
                style={r?.hasPeriod ? { backgroundColor: COLORS.period } : undefined}
              >
                <button
                  type="button"
                  disabled={isFuture}
                  onClick={() => onSelect(key)}
                  aria-label={label}
                  aria-pressed={isSelected}
                  className={`relative flex h-full w-full items-center justify-center rounded-md text-xs font-semibold tabular-nums transition ${box} ${
                    isSelected ? "ring-2 ring-[#9dbdee] ring-offset-1" : isToday && r ? "ring-2 ring-[#6b93d1] ring-offset-1" : ""
                  } ${isFuture ? "cursor-default" : "hover:brightness-95"}`}
                  style={style}
                >
                  {day}
                </button>

                {/* Acute medication – top right */}
                {r && hasAcute(r) && (
                  <span className="pointer-events-none absolute -end-1 -top-1">
                    <AcuteIcon size={12} />
                  </span>
                )}

                {/* Aura and cluster headache – bottom left */}
                {(r?.hasAura || r?.hasClusterHeadache) && (
                  <span className="pointer-events-none absolute -bottom-1 -start-1 flex">
                    {r.hasAura && (
                      <span>
                        <AuraIcon size={12} />
                      </span>
                    )}
                    {r.hasClusterHeadache && (
                      <span>
                        <ClusterIcon size={12} />
                      </span>
                    )}
                  </span>
                )}

                {/* Written note – bottom right */}
                {note && (
                  <span className="pointer-events-none absolute -bottom-1 -end-1">
                    <NoteIcon size={12} />
                  </span>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
