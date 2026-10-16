// src/components/headache/DayDetails.js
"use client";

import { useHeadacheText } from "@/components/headache/useHeadacheText";
import { EFFECT_KEYS, INTENSITY, formatUnit, intensityOf, intlLocale, medicineName } from "@/components/headache/data";
import { AcuteIcon, AuraIcon, ClusterIcon, FaceIcon, MigraineIcon, PeriodIcon } from "@/components/headache/icons";

const card = "relative mx-auto mt-3 max-w-sm rounded-xl border border-slate-100 bg-slate-50/80 px-3 py-2.5";

function Line({ label, children }) {
  return (
    <div className="flex items-baseline justify-between gap-4 border-b border-slate-100 py-1.5 last:border-0">
      <dt className="text-xs text-slate-500">{label}</dt>
      <dd className="text-end text-xs font-medium text-slate-800">{children}</dd>
    </div>
  );
}

function Chip({ icon, children }) {
  return (
    <span className="inline-flex items-center gap-1 rounded-full bg-white py-0.5 pe-2 ps-0.5 text-xs text-slate-700">
      {icon}
      {children}
    </span>
  );
}

// Preventive medicines may come as ids (into patient.medicines) or as names
const preventiveName = (patient, m) => (typeof m === "number" ? medicineName(patient, m) : String(m));

export default function DayDetails({ patient, dateKey, record, onClose }) {
  const { t, locale } = useHeadacheText();

  if (!dateKey) {
    return <p className="mt-3 text-center text-sm text-slate-500">{t.CAL_SELECT_DAY}</p>;
  }

  const closeButton = onClose && (
    <button
      type="button"
      onClick={onClose}
      aria-label={t.ABOUT_CLOSE}
      className="absolute end-2 top-2 rounded-lg p-1.5 text-slate-500 hover:bg-slate-200"
    >
      <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.2}>
        <path d="M6 6l12 12M18 6 6 18" />
      </svg>
    </button>
  );

  const [y, m, d] = dateKey.split("-").map(Number);
  const heading = new Intl.DateTimeFormat(intlLocale(locale), {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(new Date(y, m - 1, d));

  if (!record) {
    return (
      <div className={card}>
        {closeButton}
        <h3 className="pe-8 text-sm font-semibold capitalize text-slate-800">{heading}</h3>
        <p className="mt-2 text-sm text-slate-500">{t.CAL_NO_REGISTRATION}</p>
      </div>
    );
  }

  const level = intensityOf(record);
  const acute = record.acuteMedicines ?? [];
  const times = record.acuteMedicinesUsedTimes ?? [];
  const preventive = record.preventiveMedicines ?? [];
  const effectKey = EFFECT_KEYS[record.effect];

  return (
    <div className={card}>
      {closeButton}
      <h3 className="pe-8 text-sm font-semibold capitalize text-slate-800">{heading}</h3>

      <div className="mt-1.5 flex items-center gap-2">
        <FaceIcon face={INTENSITY[level].face} size={20} />
        <span className="text-sm font-semibold text-slate-800">{t[INTENSITY[level].key]}</span>
      </div>

      {(record.isMigraine || record.hasAura || record.hasClusterHeadache || record.hasPeriod) && (
        <div className="mt-2 flex flex-wrap gap-1.5">
          {record.isMigraine && <Chip icon={<MigraineIcon size={16} />}>{t.CAL_MIGRAINE}</Chip>}
          {record.hasAura && <Chip icon={<AuraIcon size={16} />}>{t.CAL_AURA}</Chip>}
          {record.hasClusterHeadache && <Chip icon={<ClusterIcon size={16} />}>{t.CAL_CLUSTER}</Chip>}
          {record.hasPeriod && <Chip icon={<PeriodIcon size={16} />}>{t.CAL_PERIOD}</Chip>}
        </div>
      )}

      <dl className="mt-1.5">
        {level > 0 && (
          <>
            <Line label={t.CAL_ATTACKS}>{record.attacks ?? 0}</Line>
            {Number(record.durationMinutes) > 0 && (
              <Line label={t.CAL_DURATION}>{formatUnit(locale, record.durationMinutes, "minute")}</Line>
            )}
          </>
        )}

        {acute.length > 0 && (
          <Line label={t.CAL_ACUTE_MEDICATION}>
            <span className="inline-flex flex-col items-end gap-1">
              {acute.map((id, i) => (
                <span key={i} className="inline-flex items-center gap-1.5">
                  <AcuteIcon size={16} />
                  {medicineName(patient, id)}
                  {times[i] > 1 ? ` × ${times[i]}` : ""}
                </span>
              ))}
            </span>
          </Line>
        )}

        {acute.length > 0 && effectKey && <Line label={t.CAL_EFFECT}>{t[effectKey]}</Line>}

        {preventive.length > 0 && (
          <Line label={t.CAL_PREVENTIVE}>{preventive.map((p) => preventiveName(patient, p)).join(", ")}</Line>
        )}

        {patient?.shareNotes && record.note?.trim() && (
          <Line label={t.CAL_NOTE}>
            <span className="whitespace-pre-wrap font-normal">{record.note}</span>
          </Line>
        )}
      </dl>

      {record.wasAddedLater && <p className="mt-3 text-xs text-slate-400">{t.CAL_REGISTERED_LATER}</p>}
    </div>
  );
}
