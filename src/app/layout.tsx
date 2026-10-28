import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "YFG ACC-WEB — ماژول حسابداری",
  description: "نمونهٔ وب ماژول حسابداری بازسازی‌شده مطابق فایل‌های اصلی",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fa" dir="rtl">
      <body>{children}</body>
    </html>
  );
}
