// src/components/dashboard/HeadacheCalendar.js
"use client";

import { useMemo } from "react";
import { useLocale } from "@/components/LocaleProvider";
import {
  COLORS,
  INTENSITY,
  hasAcute,
  intensityOf,
  intlLocale,
  monthGrid,
  toDateKey,
  todayKey,
} from "@/lib/headache";
import { AcuteIcon, AuraIcon, ChevronIcon, ClusterIcon } from "@/components/dashboard/icons";

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
}) {
  const { t, locale } = useLocale();
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
      <div className="mb-4 flex items-center justify-between px-2">
        <button
          type="button"
          onClick={onPrev}
          disabled={!canPrev}
          aria-label={t.CAL_PREV_MONTH}
          className="rounded-full p-2 text-blue-600 transition hover:bg-blue-50 disabled:opacity-30 rtl:rotate-180"
        >
          <ChevronIcon dir="left" />
        </button>
        <h2 className="font-serif text-xl font-bold capitalize text-blue-900 sm:text-2xl" aria-live="polite">
          {title}
        </h2>
        <button
          type="button"
          onClick={onNext}
          disabled={!canNext}
          aria-label={t.CAL_NEXT_MONTH}
          className="rounded-full p-2 text-blue-600 transition hover:bg-blue-50 disabled:opacity-30 rtl:rotate-180"
        >
          <ChevronIcon dir="right" />
        </button>
      </div>

      <div>
        <div className="grid grid-cols-7 gap-1 pb-2 text-center text-sm font-medium uppercase text-slate-500 sm:gap-2 sm:text-base">
          {weekdays.map((d, i) => (
            <div key={i}>{d}</div>
          ))}
        </div>

        <div className="grid grid-cols-7 gap-1 sm:gap-2" role="grid">
          {cells.map((day, i) => {
            if (!day) return <div key={i} />;
            const key = toDateKey(year, month, day);
            const r = byDate.get(key);
            const level = r ? intensityOf(r) : null;
            const isToday = key === today;
            const isFuture = key > today;
            const isSelected = key === selected;

            let box = "border-2 border-dashed border-slate-200 text-slate-400"; // past, nothing registered
            let style;
            if (r && level > 0) {
              box = "text-white";
              style = { backgroundColor: FILL[level] };
            } else if (r) {
              box = "border-2 border-slate-300 bg-white text-slate-700";
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
            ]
              .filter(Boolean)
              .join(", ");

            return (
              <div
                key={i}
                className="relative aspect-square rounded-xl p-[9%]"
                style={r?.hasPeriod ? { backgroundColor: COLORS.period } : undefined}
              >
                <button
                  type="button"
                  disabled={isFuture}
                  onClick={() => onSelect(key)}
                  aria-label={label}
                  aria-pressed={isSelected}
                  className={`relative flex h-full w-full items-center justify-center rounded-[30%] text-base font-medium transition sm:text-xl ${box} ${
                    isSelected ? "ring-[3px] ring-blue-600 ring-offset-2" : isToday && r ? "ring-[3px] ring-[#3f64a3] ring-offset-2" : ""
                  } ${isFuture ? "cursor-default" : "hover:brightness-95"}`}
                  style={style}
                >
                  {day}
                </button>

                {/* Acute medication – top right */}
                {r && hasAcute(r) && (
                  <span className="pointer-events-none absolute -end-[4%] -top-[4%] w-[40%]">
                    <AcuteIcon size="100%" />
                  </span>
                )}

                {/* Aura and cluster headache – bottom left */}
                {(r?.hasAura || r?.hasClusterHeadache) && (
                  <span className="pointer-events-none absolute -bottom-[4%] -start-[4%] flex w-[78%] gap-[2%]">
                    {r.hasAura && (
                      <span className="w-[50%]">
                        <AuraIcon size="100%" />
                      </span>
                    )}
                    {r.hasClusterHeadache && (
                      <span className="w-[50%]">
                        <ClusterIcon size="100%" />
                      </span>
                    )}
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
