// src/components/headache/icons.js
import { COLORS } from "@/components/headache/data";

// Smiley in a coloured circle, like the app's intensity icons
export function FaceIcon({ face, size = 28 }) {
  const fill = COLORS[face] ?? COLORS.none;
  const eyes =
    face === "extreme" ? (
      <>
        <path d="M8.5 9.5l2.5 1.2M15.5 9.5L13 10.7" />
        <circle cx="9.8" cy="11.3" r="0.9" fill="#fff" stroke="none" />
        <circle cx="14.2" cy="11.3" r="0.9" fill="#fff" stroke="none" />
      </>
    ) : face === "strong" ? (
      <>
        <path d="M8.6 9.4l2.2 1M15.4 9.4l-2.2 1" />
        <circle cx="9.8" cy="11" r="0.9" fill="#fff" stroke="none" />
        <circle cx="14.2" cy="11" r="0.9" fill="#fff" stroke="none" />
      </>
    ) : face === "moderate" ? (
      <path d="M8.3 10.2q1.2 1 2.4 0M13.3 10.2q1.2 1 2.4 0" />
    ) : (
      <>
        <circle cx="9.5" cy="10" r="1" fill="#fff" stroke="none" />
        <circle cx="14.5" cy="10" r="1" fill="#fff" stroke="none" />
      </>
    );
  const mouth = {
    none: "M8.8 14.2q3.2 2.6 6.4 0",
    mild: "M9.2 15h5.6",
    moderate: "M9 15.8q3-2 6 0",
    strong: "M9 16.2q3-2.6 6 0",
    extreme: "M9 16.4q3-3 6 0",
  }[face] ?? "M9.2 15h5.6";

  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="12" r="11" fill={fill} />
      <g fill="none" stroke="#fff" strokeWidth="1.4" strokeLinecap="round">
        {eyes}
        <path d={mouth} />
      </g>
    </svg>
  );
}

// Red cross in a white ring – acute medication
export function AcuteIcon({ size = 20 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="12" r="11" fill="#fff" stroke={COLORS.acute} strokeWidth="1.6" />
      <path d="M10 6.5h4v3.5h3.5v4H14v3.5h-4V14H6.5v-4H10z" fill={COLORS.acute} />
    </svg>
  );
}

// Lightning in a yellow ring – aura
export function AuraIcon({ size = 20 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="12" r="11" fill="#fff8db" stroke={COLORS.aura} strokeWidth="1.6" />
      <path d="M13.4 4.5 7.5 13.2h4l-1.1 6.3 6.1-9h-4.1z" fill={COLORS.aura} stroke="#d9a400" strokeWidth="0.6" strokeLinejoin="round" />
    </svg>
  );
}

// Purple cluster of dots – cluster headache
export function ClusterIcon({ size = 20 }) {
  const dots = [
    [7, 8], [10.3, 8], [13.6, 8], [16.9, 8],
    [8.6, 11.2], [11.9, 11.2], [15.2, 11.2],
    [10.3, 14.4], [13.6, 14.4],
    [12, 17.4],
  ];
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="12" r="11" fill="#fff" stroke="#e6c8ef" strokeWidth="1.4" />
      {dots.map(([cx, cy], i) => (
        <circle key={i} cx={cx} cy={cy} r="1.45" fill={COLORS.cluster} />
      ))}
    </svg>
  );
}

// Syringe – injections
export function InjectionIcon({ size = 20 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="12" r="11" fill="#fff" stroke="#7ea6e6" strokeWidth="1.4" />
      <g transform="rotate(45 12 12)" fill="none" stroke="#3f64a3" strokeWidth="1.3" strokeLinecap="round">
        <rect x="10" y="7" width="4" height="8" rx="0.8" fill="#cfe0fb" />
        <path d="M12 15v3.5M10.6 7V5.6h2.8V7M9.3 5.6h5.4" />
      </g>
    </svg>
  );
}

// Red rounded square – migraine
export function MigraineIcon({ size = 20 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <rect x="1.5" y="1.5" width="21" height="21" rx="6" fill="#fff" stroke={COLORS.acute} strokeWidth="1.4" />
      <rect x="7" y="7" width="10" height="10" rx="3" fill={COLORS.strong} />
    </svg>
  );
}

// Pink square – menstruation (same pink as the tile behind a day)
export function PeriodIcon({ size = 20 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <rect x="2" y="2" width="20" height="20" rx="5" fill={COLORS.period} stroke="#f5b8cc" strokeWidth="1.2" />
    </svg>
  );
}

// Green hash – attacks
export function AttacksIcon({ size = 24 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <path d="M9 3 7 21M17 3l-2 18M4 8.5h17M3 15.5h17" stroke="#3aa356" strokeWidth="2.2" strokeLinecap="round" fill="none" />
    </svg>
  );
}

// Hourglass – hours with headache
export function HoursIcon({ size = 24 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="12" r="10.5" fill="none" stroke="#3aa356" strokeWidth="1.4" strokeDasharray="3 2" />
      <path d="M8 5.5h8M8 18.5h8M8.8 5.5c0 4 6.4 4.5 6.4 6.5S8.8 14 8.8 18.5M15.2 5.5c0 4-6.4 4.5-6.4 6.5s6.4 2 6.4 6.5" fill="none" stroke="#2d3b4f" strokeWidth="1.4" strokeLinecap="round" />
      <path d="M10 17.6h4l-2-2.4z" fill="#2d6b4a" />
    </svg>
  );
}

export function ChevronIcon({ dir = "left", size = 22 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d={dir === "left" ? "M15 5l-7 7 7 7" : "M9 5l7 7-7 7"} />
    </svg>
  );
}
