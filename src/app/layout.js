// src/app/layout.js
import { Suspense } from "react";
import LocaleGate from "@/components/LocaleGate";
import "./globals.css";

export const metadata = {
  title: "Hodepinedagboken",
};

export default function RootLayout({ children }) {
  return (
    <html lang="nb-NO" suppressHydrationWarning>
      <body>
        {/* Locale is read from the request (cookie / browser), so it lives inside Suspense */}
        <Suspense fallback={null}>
          <LocaleGate>{children}</LocaleGate>
        </Suspense>
      </body>
    </html>
  );
}
