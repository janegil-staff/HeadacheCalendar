// src/components/landing/FrontImage.js
"use client";

import { useState } from "react";
import { useLocale } from "@/components/LocaleProvider";
import { DEFAULT_LOCALE, getImageFolder } from "@/lib/i18n";

const frontSrc = (locale) => `/images/about-app/${getImageFolder(locale)}/front.webp`;

function Picture({ locale, alt, className }) {
  const fallback = frontSrc(DEFAULT_LOCALE);
  const [src, setSrc] = useState(frontSrc(locale));
  const [hidden, setHidden] = useState(false);

  if (hidden) return null;

  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={src}
      alt={alt}
      className={className}
      draggable={false}
      onError={() => (src !== fallback ? setSrc(fallback) : setHidden(true))}
    />
  );
}

// key={locale} → a fresh image (and fallback state) every time the language changes
export default function FrontImage({ className = "" }) {
  const { locale, t } = useLocale();
  return <Picture key={locale} locale={locale} alt={t.HEADACHE_DIARY ?? ""} className={className} />;
}
