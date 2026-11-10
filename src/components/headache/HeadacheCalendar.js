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

// Day icons: size in px, centred on the corner of the date box (the cell has 3 px padding)
const DAY_ICON_SIZE = 17;
// How far the icons are moved from the corner towards the centre of the date (px)
const ICON_INSET = 3;
const ICON_OFFSET = 3 - DAY_ICON_SIZE / 2 + ICON_INSET;

const FILL = { 1: COLORS.mild, 2: COLORS.moderate, 3: COLORS.strong, 4: COLORS.extreme };

// Blinded: every registered day in one flat light blue, so only *whether* a day was
// registered shows – not intensity, medication, aura, cluster, period or notes
const BLIND_BG = "#DCEBF7";
const BLIND_TEXT = "#14324a";

// Same look as the calendar in the app: rounded tiles with a grey outline, filled with the intensity colour
const TILE = "flex h-full w-full items-center justify-center rounded-[9px] text-[15px] tabular-nums";
const EMPTY = "border-[1.5px] border-[#c9d1dc] bg-white font-medium text-[#3b4757]";
const FUTURE = "border-[1.5px] border-[#e3e8ef] bg-white/70 font-medium text-[#b7c0cc]";
// Migraine: a red frame around the day, like in the app
const MIGRAINE_FRAME = "#e8696b";

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
  blinded = false,
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
      <div className="mx-auto mb-4 flex max-w-sm items-center justify-between">
        <button
          type="button"
          onClick={onPrev}
          disabled={!canPrev}
          aria-label={t.CAL_PREV_MONTH}
          className="rounded-full p-1.5 text-[#4f7cc0] transition hover:bg-blue-50 disabled:opacity-25 rtl:rotate-180"
        >
          <ChevronIcon dir="left" size={20} />
        </button>
        <h2 className="text-lg font-bold uppercase tracking-wide text-[#2c4a6e]" aria-live="polite">
          {title}
        </h2>
        <button
          type="button"
          onClick={onNext}
          disabled={!canNext}
          aria-label={t.CAL_NEXT_MONTH}
          className="rounded-full p-1.5 text-[#4f7cc0] transition hover:bg-blue-50 disabled:opacity-25 rtl:rotate-180"
        >
          <ChevronIcon dir="right" size={20} />
        </button>
      </div>

      <div className="mx-auto max-w-sm">
        <div className="grid grid-cols-7 gap-2 pb-2 text-center text-xs font-medium uppercase text-[#7d8899]">
          {weekdays.map((d, i) => (
            <div key={i}>{d}</div>
          ))}
        </div>

        <div className="grid grid-cols-7 gap-x-2 gap-y-2.5" role="grid">
          {cells.map((day, i) => {
            if (!day) return <div key={i} />;
            const key = toDateKey(year, month, day);
            const r = byDate.get(key);
            const level = r ? intensityOf(r) : null;
            const isToday = key === today;
            const isFuture = key > today;
            const isSelected = key === selected;
            const note = showNotes && hasNote(r);

            if (blinded) {
              // Read-only and nothing but registered / not registered – also in the screen-reader label
              return (
                <div
                  key={i}
                  role="gridcell"
                  aria-label={`${longDate.format(new Date(year, month, day))}, ${r ? t.CAL_REGISTERED : t.CAL_NO_REGISTRATION}`}
                  className="h-11 rounded-xl p-[3px]"
                >
                  <span
                    className={`${TILE} ${
                      r
                        ? "font-semibold"
                        : isFuture
                          ? FUTURE
                          : EMPTY
                    } ${isToday ? "ring-2 ring-[#6b93d1] ring-offset-1" : ""}`}
                    style={r ? { backgroundColor: BLIND_BG, color: BLIND_TEXT } : undefined}
                  >
                    {day}
                  </span>
                </div>
              );
            }

            let box = EMPTY; // past, nothing registered – outlined like in the app
            let style;
            if (r && level > 0) {
              box = "font-semibold text-white";
              style = { backgroundColor: FILL[level] };
            } else if (r) {
              box = "border-[1.5px] border-[#7ea6e6] bg-[#eef4fd] font-semibold text-[#3b5f94]"; // registered, no headache
            } else if (isToday) {
              box = "font-semibold text-white";
              style = { backgroundColor: COLORS.today };
            } else if (isFuture) {
              box = FUTURE;
            }

            // Frame around the day: menstruation fills the 3 px padding with strong pink,
            // migraine adds a red line outside it (both can show at once)
            const migraine = !!r?.isMigraine;
            const frameStyle =
              r?.hasPeriod || migraine
                ? {
                    backgroundColor: r?.hasPeriod ? COLORS.periodStrong : "#fff",
                    boxShadow: migraine
                      ? `0 0 0 1.5px ${MIGRAINE_FRAME}`
                      : `0 0 0 1px ${COLORS.periodStrong}`,
                  }
                : undefined;

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
                className="relative h-11 rounded-xl p-[3px]"
                // The frame is padding plus a box-shadow ring, so the day keeps its size
                style={frameStyle}
              >
                <button
                  type="button"
                  disabled={isFuture}
                  onClick={() => onSelect(key)}
                  aria-label={label}
                  aria-pressed={isSelected}
                  className={`relative ${TILE} transition ${box} ${
                    isSelected ? "ring-2 ring-[#9dbdee] ring-offset-1" : isToday && r ? "ring-2 ring-[#6b93d1] ring-offset-1" : ""
                  } ${isFuture ? "cursor-default" : "hover:brightness-95"}`}
                  style={style}
                >
                  {day}
                </button>

                {/* Acute medication – top right */}
                {r && hasAcute(r) && (
                  <span className="pointer-events-none absolute z-10 flex" style={{ top: ICON_OFFSET, insetInlineEnd: ICON_OFFSET }}>
                    <AcuteIcon size={DAY_ICON_SIZE} />
                  </span>
                )}

                {/* Aura and cluster headache – bottom left */}
                {(r?.hasAura || r?.hasClusterHeadache) && (
                  <span className="pointer-events-none absolute z-10 flex" style={{ bottom: ICON_OFFSET, insetInlineStart: ICON_OFFSET }}>
                    {r.hasAura && <AuraIcon size={DAY_ICON_SIZE} />}
                    {r.hasClusterHeadache && <ClusterIcon size={DAY_ICON_SIZE} />}
                  </span>
                )}

                {/* Written note – bottom right */}
                {note && (
                  <span className="pointer-events-none absolute z-10 flex" style={{ bottom: ICON_OFFSET, insetInlineEnd: ICON_OFFSET }}>
                    <NoteIcon size={DAY_ICON_SIZE} />
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
