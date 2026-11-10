// src/app/admin/page.js
// Hidden admin page – not linked from anywhere and kept out of search engines.
import AdminDashboard from "@/components/admin/AdminDashboard";
import AdminLogin from "@/components/admin/AdminLogin";
import { isAdmin, missingSettings } from "@/lib/adminAuth";

export const metadata = {
  title: "Admin",
  robots: { index: false, follow: false, nocache: true },
};

export default async function AdminPage() {
  // Reads the login cookie, so this renders per request (the layout wraps pages in Suspense)
  if (await isAdmin()) return <AdminDashboard />;
  const missing = missingSettings();
  // Only while developing: name the missing settings on the login page
  const devMissing = process.env.NODE_ENV === "production" ? [] : missing;
  return <AdminLogin configured={missing.length === 0} missing={devMissing} cwd={devMissing.length ? process.cwd() : null} />;
}
