#!/usr/bin/env bash
# front-image.sh
# Landing page: shows the selected language's front.png to the left of the code card.
#  - image: public/images/about-app/<folder>/front.png (same folders as the "About the app"
#    screenshots, picked with getImageFolder(locale), e.g. nb-NO → no, sv-SE → se, pt-BR → br)
#  - switches instantly when another language is picked in the language picker
#  - if a language has no front.png, the Norwegian one is used; if that is missing too, the
#    image is hidden and the card stays centred as before
#  - shown from the lg breakpoint (≥1024 px); on phones/tablets the page looks as it does now
#  - Arabic and Hebrew (right-to-left) get the image on the right, mirroring the layout
#  - also lists any language folder that is missing front.png
# Run from the project root:  bash front-image.sh
set -euo pipefail

if [ ! -f src/app/page.js ] || [ ! -f src/lib/i18n.js ]; then
  echo "✗ src/app/page.js or src/lib/i18n.js not found – run this from the project root." >&2
  exit 1
fi

mkdir -p src/components/landing

cat > src/components/landing/FrontImage.js <<'FILE_END'
// src/components/landing/FrontImage.js
"use client";

import { useState } from "react";
import { useLocale } from "@/components/LocaleProvider";
import { DEFAULT_LOCALE, getImageFolder } from "@/lib/i18n";

const frontSrc = (locale) => `/images/about-app/${getImageFolder(locale)}/front.png`;

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
FILE_END

cat > src/app/page.js <<'FILE_END'
// src/app/page.js
"use client";

import Background from "@/components/landing/Background";
import CodeCard from "@/components/landing/CodeCard";
import FrontImage from "@/components/landing/FrontImage";
import LanguagePicker from "@/components/landing/LanguagePicker";
import ReadMoreButton from "@/components/landing/ReadMoreButton";
import { useLocale } from "@/components/LocaleProvider";

export default function LandingPage() {
  const { t } = useLocale();

  return (
    <main className="relative isolate flex min-h-screen items-center justify-center overflow-hidden px-4 py-20">
      <Background />

      <div className="absolute end-4 top-4 sm:end-6 sm:top-6">
        <LanguagePicker />
      </div>

      <div className="flex w-full max-w-5xl items-center justify-center gap-12 xl:gap-16">
        <FrontImage className="hidden h-auto max-h-[75vh] w-full max-w-sm shrink object-contain drop-shadow-2xl lg:block xl:max-w-md" />

        <div className="w-full max-w-md shrink-0">
          <h1 className="mb-8 text-center font-serif text-4xl font-bold text-blue-800 sm:text-5xl">
            {t.HEADACHE_DIARY}
          </h1>

          <CodeCard />

          <div className="mt-6 flex justify-center">
            <ReadMoreButton />
          </div>
        </div>
      </div>
    </main>
  );
}
FILE_END

echo "✓ src/components/landing/FrontImage.js"
echo "✓ src/app/page.js"

# Report language folders without front.png
if [ -d public/images/about-app ]; then
  missing=""
  for dir in public/images/about-app/*/; do
    [ -f "${dir}front.png" ] || missing="$missing $(basename "$dir")"
  done
  if [ -n "$missing" ]; then
    echo "! front.png missing in:$missing (those languages show the Norwegian image)"
  else
    echo "✓ front.png found in every language folder"
  fi
fi
