import type { Metadata } from "next";
import "./globals.css";
import { AppProvider } from "@/components/App";

export const metadata: Metadata = {
  title: "YFG ACC-WEB — ماژول حسابداری",
  description: "ماژول حسابداری YFG — بازنویسی وب مطابق فایل‌های اصلی (v2.0.0)",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fa" dir="rtl">
      <body>
        <AppProvider>{children}</AppProvider>
      </body>
    </html>
  );
}
